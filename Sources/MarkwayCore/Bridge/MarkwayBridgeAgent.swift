import CoreServices
import Darwin
import Foundation

public enum MarkwayBridgeAgentEvent: Sendable, Equatable {
    case started(String)
    case stopped
    case processed(requests: Int, successes: Int)
    case journalChangedQueued
    case error(String)
}

public final class MarkwayBridgeAgent<Backend: JournalBackend> {
    private let vaultURL: URL
    private let journal: Backend
    private let bridgeBaseURL: URL?
    private let journalContainerURL: URL
    private let eventHandler: @Sendable (MarkwayBridgeAgentEvent) -> Void

    private var bridgeWatcher: BridgeDirectoryWatcher?
    private var journalWatcher: RecursiveDirectoryWatcher?
    private var pendingBridgeProcess: DispatchWorkItem?
    private var pendingJournalEvent: DispatchWorkItem?
    private var isProcessingBridge = false
    private var needsBridgeProcessAfterCurrentRun = false
    private var ignoreJournalEventsUntil: Date?

    public init(
        vaultURL: URL,
        journal: Backend,
        bridgeBaseURL: URL? = nil,
        journalContainerURL: URL = MarkwayBridgeAgent.defaultJournalContainerURL(),
        eventHandler: @escaping @Sendable (MarkwayBridgeAgentEvent) -> Void = { _ in }
    ) {
        self.vaultURL = vaultURL.resolvingSymlinksInPath().standardizedFileURL
        self.journal = journal
        self.bridgeBaseURL = bridgeBaseURL
        self.journalContainerURL = journalContainerURL
        self.eventHandler = eventHandler
    }

    deinit {
        stop()
    }

    public func start() throws {
        stop()

        let bridge = makeBridge()
        try bridge.prepare()

        processBridge()
        bridgeWatcher = try BridgeDirectoryWatcher(directoryURL: bridge.requestsURL) { [weak self] in
            self?.queueBridgeProcess()
        }
        journalWatcher = try RecursiveDirectoryWatcher(directoryURL: journalContainerURL) { [weak self] in
            self?.queueJournalChangedEvent()
        }

        eventHandler(.started(bridge.bridgeURL.path))
    }

    public func stop() {
        pendingBridgeProcess?.cancel()
        pendingBridgeProcess = nil
        pendingJournalEvent?.cancel()
        pendingJournalEvent = nil
        journalWatcher?.cancel()
        journalWatcher = nil
        bridgeWatcher?.cancel()
        bridgeWatcher = nil
        eventHandler(.stopped)
    }

    private func queueBridgeProcess() {
        pendingBridgeProcess?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.pendingBridgeProcess = nil
            self?.processBridge()
        }
        pendingBridgeProcess = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func queueJournalChangedEvent() {
        if let ignoreUntil = ignoreJournalEventsUntil, Date() < ignoreUntil {
            return
        }

        pendingJournalEvent?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.emitJournalChangedEvent()
        }
        pendingJournalEvent = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }

    private func emitJournalChangedEvent() {
        guard pendingJournalEvent?.isCancelled == false else {
            return
        }
        pendingJournalEvent = nil
        if let ignoreUntil = ignoreJournalEventsUntil, Date() < ignoreUntil {
            return
        }

        do {
            let bridge = makeBridge()
            try bridge.emitEvent(kind: .journalChanged)
            eventHandler(.journalChangedQueued)
        } catch {
            eventHandler(.error("Failed to queue Journal change: \(error)"))
        }
    }

    private func processBridge() {
        guard !isProcessingBridge else {
            needsBridgeProcessAfterCurrentRun = true
            return
        }

        isProcessingBridge = true
        defer {
            isProcessingBridge = false
            if needsBridgeProcessAfterCurrentRun || hasPendingBridgeRequests() {
                needsBridgeProcessAfterCurrentRun = false
                queueBridgeProcess()
            }
        }

        do {
            let bridge = makeBridge()
            let responses = try bridge.processPendingRequests()
            guard !responses.isEmpty else {
                return
            }

            ignoreJournalEventsUntil = Date().addingTimeInterval(3)
            eventHandler(.processed(requests: responses.count, successes: responses.filter(\.ok).count))
        } catch {
            eventHandler(.error(String(describing: error)))
        }
    }

    private func hasPendingBridgeRequests() -> Bool {
        let bridge = makeBridge()
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: bridge.requestsURL,
            includingPropertiesForKeys: nil
        ) else {
            return false
        }
        return files.contains { $0.pathExtension == "json" }
    }

    private func makeBridge() -> MarkwayFileBridge<Backend> {
        MarkwayFileBridge(vaultURL: vaultURL, journal: journal, bridgeBaseURL: bridgeBaseURL)
    }

    public static func defaultJournalContainerURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Group Containers", isDirectory: true)
            .appendingPathComponent("group.com.apple.moments", isDirectory: true)
    }
}

private final class BridgeDirectoryWatcher {
    private let source: DispatchSourceFileSystemObject
    private var isCancelled = false

    init(directoryURL: URL, handler: @escaping () -> Void) throws {
        let descriptor = open(directoryURL.path, O_EVTONLY)
        guard descriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )
        source.setEventHandler {
            handler()
        }
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()

        self.source = source
    }

    func cancel() {
        guard !isCancelled else {
            return
        }
        isCancelled = true
        source.cancel()
    }

    deinit {
        cancel()
    }
}

private final class RecursiveDirectoryWatcher {
    private var stream: FSEventStreamRef?
    private let handler: () -> Void

    init(directoryURL: URL, handler: @escaping () -> Void) throws {
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw CocoaError(.fileNoSuchFile)
        }

        self.handler = handler

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, info, _, _, _, _ in
                guard let info else {
                    return
                }
                let watcher = Unmanaged<RecursiveDirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
                watcher.handler()
            },
            &context,
            [directoryURL.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            flags
        ) else {
            throw CocoaError(.fileReadUnknown)
        }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        guard FSEventStreamStart(stream) else {
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
            throw CocoaError(.fileReadUnknown)
        }
    }

    func cancel() {
        guard let stream else {
            return
        }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit {
        cancel()
    }
}
