import Foundation

public enum MarkwayBridgeKind: String, Codable, Sendable {
    case doctor
    case journalPush
}

public struct MarkwayBridgeRequest: Codable, Equatable, Sendable {
    public var id: String
    public var kind: MarkwayBridgeKind
    public var filePath: String?
    public var title: String?
    public var requestedAt: String

    public init(
        id: String,
        kind: MarkwayBridgeKind,
        filePath: String? = nil,
        title: String? = nil,
        requestedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.kind = kind
        self.filePath = filePath
        self.title = title
        self.requestedAt = requestedAt
    }
}

public struct MarkwayBridgeResponse: Codable, Equatable, Sendable {
    public var id: String
    public var ok: Bool
    public var message: String
    public var journalID: String?
    public var completedAt: String

    public init(
        id: String,
        ok: Bool,
        message: String,
        journalID: String? = nil,
        completedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.ok = ok
        self.message = message
        self.journalID = journalID
        self.completedAt = completedAt
    }
}

public struct MarkwayFileBridge<Backend: JournalBackend>: Sendable {
    public let vaultURL: URL
    public let journal: Backend

    public init(vaultURL: URL, journal: Backend) {
        self.vaultURL = vaultURL
        self.journal = journal
    }

    public var bridgeURL: URL {
        vaultURL.appendingPathComponent(".markway")
    }

    public var requestsURL: URL {
        bridgeURL.appendingPathComponent("requests")
    }

    public var responsesURL: URL {
        bridgeURL.appendingPathComponent("responses")
    }

    @discardableResult
    public func prepare() throws -> URL {
        try FileManager.default.createDirectory(at: requestsURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: responsesURL, withIntermediateDirectories: true)
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

        case .journalPush:
            guard let filePath = request.filePath, !filePath.isEmpty else {
                return MarkwayBridgeResponse(id: request.id, ok: false, message: "journalPush requires filePath")
            }

            let engine = MarkwaySyncEngine(journal: journal)
            let journalID = try engine.pushMarkdownFile(
                URL(fileURLWithPath: filePath),
                title: request.title,
                writeMetadata: false
            )
            return MarkwayBridgeResponse(
                id: request.id,
                ok: true,
                message: "Pushed to Journal",
                journalID: journalID
            )
        }
    }

    private func writeResponse(_ response: MarkwayBridgeResponse) throws {
        try prepare()
        let responseURL = responsesURL.appendingPathComponent(response.id).appendingPathExtension("json")
        let data = try JSONEncoder.markway.encode(response)
        try data.write(to: responseURL, options: .atomic)
    }
}
