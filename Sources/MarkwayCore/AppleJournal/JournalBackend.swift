import Foundation

public struct JournalEntryText: Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var body: String

    public init(id: String, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public struct JournalEntrySummary: Codable, Equatable, Sendable {
    public var id: String
    public var status: String
    public var created: String
    public var title: String

    public init(id: String, status: String, created: String, title: String) {
        self.id = id
        self.status = status
        self.created = created
        self.title = title
    }
}

public protocol JournalBackend: Sendable {
    func list() throws -> [JournalEntrySummary]
    func add(title: String, bodyFile: URL) throws -> String
    func update(id: String, title: String, bodyFile: URL) throws
    func get(id: String) throws -> JournalEntryText
    func runRaw(_ arguments: [String]) throws -> String
}
