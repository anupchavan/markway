import MarkwayCore
import AppKit
import CoreServices
import Darwin
import SwiftUI

struct ContentView: View {
    @State private var vaultPath = UserDefaults.standard.string(forKey: "vaultPath") ?? ""
    @State private var bridgeStatus = "Bridge stopped."
    @State private var message = "Idle"
    @State private var bridgeWatcher: BridgeDirectoryWatcher?
    @State private var journalWatcher: RecursiveDirectoryWatcher?
    @State private var pendingBridgeProcess: DispatchWorkItem?
    @State private var pendingJournalEvent: DispatchWorkItem?
    @State private var isProcessingBridge = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Markway")
                .font(.largeTitle.bold())

            HStack {
                TextField("Markdown vault", text: $vaultPath)
                    .textFieldStyle(.roundedBorder)
                Button("Scan") {
                    scan()
                }
                .keyboardShortcut(.defaultAction)
                Button(bridgeWatcher == nil ? "Start bridge" : "Stop bridge") {
                    toggleBridge()
                }
            }

            HStack {
                Button("Check Journal Access") {
                    checkJournalAccess()
                }

                Button("Open Full Disk Access") {
                    openFullDiskAccessSettings()
                }

                Button("Reveal Markway.app") {
                    revealMarkwayApp()
                }

                Button("Reveal Journal helper") {
                    revealJournalHelper()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(bridgeStatus)
                Text(message)
            }
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 260)
    }

    private func scan() {
        guard let vaultURL else {
            message = "Choose a vault path."
            return
        }
        UserDefaults.standard.set(vaultURL.path, forKey: "vaultPath")

        do {
            let engine = MarkwaySyncEngine(journal: NoopJournalBackend())
            let summary = try engine.scanVault(at: vaultURL)
            message = """
            markdown files: \(summary.markdownFiles)
            linked journal entries: \(summary.linkedJournalEntries)
            unlinked markdown files: \(summary.unlinkedMarkdownFiles)
            """
        } catch {
            message = String(describing: error)
        }
    }

    private func toggleBridge() {
        if bridgeWatcher != nil {
            stopBridge()
            return
        }

        guard let vaultURL else {
            message = "Choose a vault path."
            return
        }

        UserDefaults.standard.set(vaultURL.path, forKey: "vaultPath")
        do {
            let bridge = MarkwayFileBridge(vaultURL: vaultURL, journal: NoopJournalBackend())
            try bridge.prepare()
            processBridge(vaultURL: vaultURL)
            bridgeWatcher = try BridgeDirectoryWatcher(directoryURL: bridge.requestsURL) {
                queueBridgeProcess(vaultURL: vaultURL)
            }
            startJournalWatcher(vaultURL: vaultURL)
            bridgeStatus = "Bridge started: \(bridge.bridgeURL.path)"
        } catch {
            message = String(describing: error)
        }
    }

    private func stopBridge() {
        pendingBridgeProcess?.cancel()
        pendingBridgeProcess = nil
        pendingJournalEvent?.cancel()
        pendingJournalEvent = nil
        journalWatcher?.cancel()
        journalWatcher = nil
        bridgeWatcher?.cancel()
        bridgeWatcher = nil
        bridgeStatus = "Bridge stopped."
    }

    private func startJournalWatcher(vaultURL: URL) {
        do {
            let containerURL = Self.defaultJournalContainerURL()
            journalWatcher = try RecursiveDirectoryWatcher(directoryURL: containerURL) {
                queueJournalChangedEvent(vaultURL: vaultURL)
            }
        } catch {
            message = "Bridge started, but Journal watcher could not start: \(error)"
        }
    }

    private func queueBridgeProcess(vaultURL: URL) {
        pendingBridgeProcess?.cancel()
        let workItem = DispatchWorkItem {
            pendingBridgeProcess = nil
            processBridge(vaultURL: vaultURL)
        }
        pendingBridgeProcess = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func queueJournalChangedEvent(vaultURL: URL) {
        pendingJournalEvent?.cancel()
        let workItem = DispatchWorkItem {
            emitJournalChangedEvent(vaultURL: vaultURL)
        }
        pendingJournalEvent = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }

    private func emitJournalChangedEvent(vaultURL: URL) {
        guard pendingJournalEvent?.isCancelled == false else {
            return
        }
        pendingJournalEvent = nil

        do {
            let bridge = MarkwayFileBridge(vaultURL: vaultURL, journal: NoopJournalBackend())
            try bridge.emitEvent(kind: .journalChanged)
            bridgeStatus = "Journal change queued for Obsidian."
        } catch {
            message = "Failed to queue Journal change: \(error)"
        }
    }

    private func processBridge(vaultURL: URL) {
        guard !isProcessingBridge else {
            return
        }

        isProcessingBridge = true
        defer { isProcessingBridge = false }

        do {
            guard let journal = journalTool() else {
                message = "Bundled Journal helper not found. Rebuild Markway.app."
                return
            }

            let bridge = MarkwayFileBridge(vaultURL: vaultURL, journal: journal)
            let responses = try bridge.processPendingRequests()
            if responses.isEmpty {
                bridgeStatus = "Bridge running: \(bridge.bridgeURL.path)"
            } else {
                let successes = responses.filter(\.ok).count
                message = "Processed \(responses.count) request(s), \(successes) ok."
            }
        } catch {
            message = String(describing: error)
        }
    }

    private func checkJournalAccess() {
        do {
            guard let journal = journalTool() else {
                message = "Bundled Journal helper not found. Rebuild Markway.app."
                return
            }

            _ = try journal.runRaw(["sync-status"])
            message = "Journal access OK."
        } catch {
            message = String(describing: error)
        }
    }

    private func openFullDiskAccessSettings() {
        let settingsURLs = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
        ]

        for urlString in settingsURLs {
            guard let url = URL(string: urlString) else {
                continue
            }

            if NSWorkspace.shared.open(url) {
                message = "Opened Full Disk Access. Enable Markway.app, then fully quit and reopen Markway.app."
                return
            }
        }

        message = "Could not open Full Disk Access. Open System Settings > Privacy & Security > Full Disk Access."
    }

    private func revealMarkwayApp() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
        message = "Revealed Markway.app. In Full Disk Access, use + and select this app if it is not listed."
    }

    private func revealJournalHelper() {
        let helperURL = journalHelperURL
        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            message = "Bundled Journal helper not found. Rebuild Markway.app."
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([helperURL])
        message = "Revealed journal_text. If Journal access still fails after enabling Markway.app, add this helper to Full Disk Access too."
    }

    private var vaultURL: URL? {
        let path = vaultPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    private func journalTool() -> JournalTextTool? {
        let bundledHelper = journalHelperURL

        if FileManager.default.isExecutableFile(atPath: bundledHelper.path) {
            return JournalTextTool(executableURL: bundledHelper)
        }

        return nil
    }

    private var journalHelperURL: URL {
        Bundle.main.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Helpers")
            .appendingPathComponent("journal_text")
    }

    private static func defaultJournalContainerURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Group Containers", isDirectory: true)
            .appendingPathComponent("group.com.apple.moments", isDirectory: true)
    }
}

private struct NoopJournalBackend: JournalBackend {
    func list() throws -> [JournalEntrySummary] { [] }
    func add(title: String, bodyFile: URL) throws -> String { "" }
    func update(id: String, title: String, bodyFile: URL) throws {}
    func delete(id: String) throws {}
    func get(id: String) throws -> JournalEntryText { JournalEntryText(id: id, title: "", body: "") }
    func musicAttachments(id: String) throws -> [JournalMusicAttachment] { [] }
    func runRaw(_ arguments: [String]) throws -> String { "" }
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
