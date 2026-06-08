import CryptoKit
import Foundation

public enum MarkwayBridgeKind: String, Codable, Sendable {
    case doctor
    case journalList
    case journalGet
    case journalPush
    case journalPull
    case journalDelete
    case journalDeleteAttachment
}

public struct MarkwayBridgeRequest: Codable, Equatable, Sendable {
    public var id: String
    public var kind: MarkwayBridgeKind
    public var filePath: String?
    public var relativePath: String?
    public var journalID: String?
    public var assetID: String?
    public var title: String?
    public var includeMusicAttachments: Bool?
    public var stripTitleHeading: Bool?
    public var requestedAt: String

    public init(
        id: String,
        kind: MarkwayBridgeKind,
        filePath: String? = nil,
        relativePath: String? = nil,
        journalID: String? = nil,
        assetID: String? = nil,
        title: String? = nil,
        includeMusicAttachments: Bool? = nil,
        stripTitleHeading: Bool? = nil,
        requestedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.kind = kind
        self.filePath = filePath
        self.relativePath = relativePath
        self.journalID = journalID
        self.assetID = assetID
        self.title = title
        self.includeMusicAttachments = includeMusicAttachments
        self.stripTitleHeading = stripTitleHeading
        self.requestedAt = requestedAt
    }
}

public enum MarkwayBridgeError: Error, CustomStringConvertible, Sendable {
    case missingPath(String)
    case absolutePathRejected
    case pathOutsideVault(String)

    public var description: String {
        switch self {
        case .missingPath(let kind):
            return "\(kind) requires relativePath"
        case .absolutePathRejected:
            return "bridge requests must use vault-relative paths"
        case .pathOutsideVault(let path):
            return "bridge request path escapes the vault: \(path)"
        }
    }
}

public struct MarkwayBridgeResponse: Codable, Equatable, Sendable {
    public var id: String
    public var ok: Bool
    public var message: String
    public var journalID: String?
    public var entry: JournalEntryText?
    public var entries: [JournalEntrySummary]?
    public var completedAt: String

    public init(
        id: String,
        ok: Bool,
        message: String,
        journalID: String? = nil,
        entry: JournalEntryText? = nil,
        entries: [JournalEntrySummary]? = nil,
        completedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.ok = ok
        self.message = message
        self.journalID = journalID
        self.entry = entry
        self.entries = entries
        self.completedAt = completedAt
    }
}

public enum MarkwayBridgeEventKind: String, Codable, Sendable {
    case journalChanged
}

public struct MarkwayBridgeEvent: Codable, Equatable, Sendable {
    public var id: String
    public var kind: MarkwayBridgeEventKind
    public var createdAt: String

    public init(
        id: String = UUID().uuidString.uppercased(),
        kind: MarkwayBridgeEventKind,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
    }
}

public struct MarkwayFileBridge<Backend: JournalBackend>: Sendable {
    public let vaultURL: URL
    public let journal: Backend
    public let bridgeBaseURL: URL
    private let usesVaultLocalBridge: Bool

    public init(vaultURL: URL, journal: Backend, bridgeBaseURL: URL? = nil) {
        self.vaultURL = vaultURL.resolvingSymlinksInPath().standardizedFileURL
        self.journal = journal
        self.bridgeBaseURL = bridgeBaseURL ?? Self.defaultBridgeBaseURL(vaultURL: self.vaultURL)
        self.usesVaultLocalBridge = bridgeBaseURL == nil
    }

    public var bridgeURL: URL {
        if usesVaultLocalBridge {
            return bridgeBaseURL
        }

        return bridgeBaseURL.appendingPathComponent(Self.bridgeID(for: vaultURL.path), isDirectory: true)
    }

    public var requestsURL: URL {
        bridgeURL.appendingPathComponent("requests")
    }

    public var responsesURL: URL {
        bridgeURL.appendingPathComponent("responses")
    }

    public var eventsURL: URL {
        bridgeURL.appendingPathComponent("events")
    }

    @discardableResult
    public func prepare() throws -> URL {
        try createPrivateDirectory(bridgeBaseURL)
        try createPrivateDirectory(bridgeURL)
        try createPrivateDirectory(requestsURL)
        try createPrivateDirectory(responsesURL)
        try createPrivateDirectory(eventsURL)
        return bridgeURL
    }

    @discardableResult
    public func processPendingRequests() throws -> [MarkwayBridgeResponse] {
        try prepare()

        let files = try FileManager.default.contentsOfDirectory(
            at: requestsURL,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var responses: [MarkwayBridgeResponse] = []
        for requestURL in files {
            let response = processRequestFile(requestURL)
            try writeResponse(response)
            try? FileManager.default.removeItem(at: requestURL)
            responses.append(response)
        }

        return responses
    }

    private func processRequestFile(_ requestURL: URL) -> MarkwayBridgeResponse {
        do {
            let data = try Data(contentsOf: requestURL)
            let request = try JSONDecoder.markway.decode(MarkwayBridgeRequest.self, from: data)
            return try process(request)
        } catch {
            let fallbackID = requestURL.deletingPathExtension().lastPathComponent
            return MarkwayBridgeResponse(
                id: fallbackID,
                ok: false,
                message: String(describing: error)
            )
        }
    }

    private func process(_ request: MarkwayBridgeRequest) throws -> MarkwayBridgeResponse {
        switch request.kind {
        case .doctor:
            _ = try journal.runRaw(["sync-status"])
            return MarkwayBridgeResponse(id: request.id, ok: true, message: "Journal access ok")

        case .journalList:
            let entries = try journal.list()
            return MarkwayBridgeResponse(
                id: request.id,
                ok: true,
                message: "Listed Journal entries",
                entries: entries
            )

        case .journalGet:
            guard let journalID = request.journalID, !journalID.isEmpty else {
                return MarkwayBridgeResponse(id: request.id, ok: false, message: "journalGet requires journalID")
            }
            var entry = try journal.get(id: journalID)
            if request.includeMusicAttachments == true {
                entry.musicAttachments = try journal.musicAttachments(id: journalID)
            }
            return MarkwayBridgeResponse(
                id: request.id,
                ok: true,
                message: "Read Journal entry",
                journalID: entry.id,
                entry: entry
            )

        case .journalPush:
            let fileURL = try fileURL(for: request, kind: "journalPush")

            let engine = MarkwaySyncEngine(journal: journal)
            let journalID = try engine.pushMarkdownFile(
                fileURL,
                title: request.title,
                existingID: request.journalID,
                writeMetadata: false,
                stripTitleHeading: request.stripTitleHeading == true
            )
            return MarkwayBridgeResponse(
                id: request.id,
                ok: true,
                message: "Pushed to Journal",
                journalID: journalID
            )

        case .journalPull:
            let fileURL = try fileURL(for: request, kind: "journalPull")
            guard let journalID = request.journalID, !journalID.isEmpty else {
                return MarkwayBridgeResponse(id: request.id, ok: false, message: "journalPull requires journalID")
            }

            let engine = MarkwaySyncEngine(journal: journal)
            try engine.pullJournalEntry(id: journalID, to: fileURL)
            return MarkwayBridgeResponse(
                id: request.id,
                ok: true,
                message: "Pulled from Journal",
                journalID: journalID
            )

        case .journalDelete:
            guard let journalID = request.journalID, !journalID.isEmpty else {
                return MarkwayBridgeResponse(id: request.id, ok: false, message: "journalDelete requires journalID")
            }

            try journal.delete(id: journalID)
            return MarkwayBridgeResponse(
                id: request.id,
                ok: true,
                message: "Deleted Journal entry",
                journalID: journalID
            )

        case .journalDeleteAttachment:
            guard let journalID = request.journalID, !journalID.isEmpty else {
                return MarkwayBridgeResponse(id: request.id, ok: false, message: "journalDeleteAttachment requires journalID")
            }
            guard let assetID = request.assetID, !assetID.isEmpty else {
                return MarkwayBridgeResponse(id: request.id, ok: false, message: "journalDeleteAttachment requires assetID")
            }

            try journal.deleteAttachment(entryID: journalID, assetID: assetID)
            return MarkwayBridgeResponse(
                id: request.id,
                ok: true,
                message: "Deleted Journal attachment",
                journalID: journalID
            )
        }
    }

    private func writeResponse(_ response: MarkwayBridgeResponse) throws {
        try prepare()
        let responseURL = responsesURL.appendingPathComponent(response.id).appendingPathExtension("json")
        let data = try JSONEncoder.markway.encode(response)
        try data.write(to: responseURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: responseURL.path)
    }

    public func emitEvent(kind: MarkwayBridgeEventKind) throws {
        try prepare()
        let event = MarkwayBridgeEvent(kind: kind)
        let eventURL = eventsURL.appendingPathComponent(event.id).appendingPathExtension("json")
        let data = try JSONEncoder.markway.encode(event)
        try data.write(to: eventURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: eventURL.path)
    }

    private func createPrivateDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }

    private static func defaultBridgeBaseURL(vaultURL: URL) -> URL {
        vaultURL
            .appendingPathComponent(".obsidian", isDirectory: true)
            .appendingPathComponent("plugins", isDirectory: true)
            .appendingPathComponent("markway", isDirectory: true)
            .appendingPathComponent("bridge", isDirectory: true)
    }

    private static func bridgeID(for vaultPath: String) -> String {
        SHA256.hash(data: Data(vaultPath.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func fileURL(for request: MarkwayBridgeRequest, kind: String) throws -> URL {
        let rawPath = request.relativePath ?? request.filePath
        guard let rawPath, !rawPath.isEmpty else {
            throw MarkwayBridgeError.missingPath(kind)
        }
        guard !rawPath.hasPrefix("/") else {
            throw MarkwayBridgeError.absolutePathRejected
        }

        let candidate = vaultURL
            .appendingPathComponent(rawPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let vaultPath = vaultURL.path
        guard candidate.path == vaultPath || candidate.path.hasPrefix(vaultPath + "/") else {
            throw MarkwayBridgeError.pathOutsideVault(rawPath)
        }
        return candidate
    }
}
