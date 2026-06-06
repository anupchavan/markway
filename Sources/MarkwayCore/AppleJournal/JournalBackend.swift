import Foundation

public struct JournalEntryText: Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var body: String
    public var created: String
    public var updated: String
    public var musicAttachments: [JournalMusicAttachment]

    public init(
        id: String,
        title: String,
        body: String,
        created: String = "",
        updated: String = "",
        musicAttachments: [JournalMusicAttachment] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.created = created
        self.updated = updated
        self.musicAttachments = musicAttachments
    }
}

public struct JournalMusicAttachment: Codable, Equatable, Sendable {
    public var id: String
    public var song: String
    public var artistName: String
    public var mediaId: String
    public var source: String
    public var isHidden: Bool
    public var isSlim: Bool
    public var mediaType: String
    public var startTime: Double?
    public var createdDate: String
    public var suggestionDate: String

    public init(
        id: String,
        song: String,
        artistName: String = "",
        mediaId: String = "",
        source: String = "",
        isHidden: Bool = false,
        isSlim: Bool = false,
        mediaType: String = "",
        startTime: Double? = nil,
        createdDate: String = "",
        suggestionDate: String = ""
    ) {
        self.id = id
        self.song = song
        self.artistName = artistName
        self.mediaId = mediaId
        self.source = source
        self.isHidden = isHidden
        self.isSlim = isSlim
        self.mediaType = mediaType
        self.startTime = startTime
        self.createdDate = createdDate
        self.suggestionDate = suggestionDate
    }
}

public struct JournalEntrySummary: Codable, Equatable, Sendable {
    public var id: String
    public var status: String
    public var created: String
    public var updated: String
    public var title: String

    public init(id: String, status: String, created: String, updated: String = "", title: String) {
        self.id = id
        self.status = status
        self.created = created
        self.updated = updated
        self.title = title
    }
}

public protocol JournalBackend: Sendable {
    func list() throws -> [JournalEntrySummary]
    func add(title: String, bodyFile: URL) throws -> String
    func update(id: String, title: String, bodyFile: URL) throws
    func delete(id: String) throws
    func get(id: String) throws -> JournalEntryText
    func musicAttachments(id: String) throws -> [JournalMusicAttachment]
    func runRaw(_ arguments: [String]) throws -> String
}
