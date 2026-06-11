import Foundation

public struct JournalEntryText: Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var body: String
    public var created: String
    public var updated: String
    public var musicAttachments: [JournalMusicAttachment]
    public var photoAttachments: [JournalPhotoAttachment]
    public var attachments: [JournalGenericAttachment]

    public init(
        id: String,
        title: String,
        body: String,
        created: String = "",
        updated: String = "",
        musicAttachments: [JournalMusicAttachment] = [],
        photoAttachments: [JournalPhotoAttachment] = [],
        attachments: [JournalGenericAttachment] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.created = created
        self.updated = updated
        self.musicAttachments = musicAttachments
        self.photoAttachments = photoAttachments
        self.attachments = attachments
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        created = try container.decodeIfPresent(String.self, forKey: .created) ?? ""
        updated = try container.decodeIfPresent(String.self, forKey: .updated) ?? ""
        musicAttachments = try container.decodeIfPresent([JournalMusicAttachment].self, forKey: .musicAttachments) ?? []
        photoAttachments = try container.decodeIfPresent([JournalPhotoAttachment].self, forKey: .photoAttachments) ?? []
        attachments = try container.decodeIfPresent([JournalGenericAttachment].self, forKey: .attachments) ?? []
    }
}

/// One Journal attachment of any asset type, in the entry's display order.
/// `metadata` carries the helper's decoded metadata JSON with binary blobs
/// already turned into friendly values (reflection prompt text, hex colors)
/// or dropped (map item archives).
public struct JournalGenericAttachment: Codable, Equatable, Sendable {
    public var id: String
    public var assetType: String
    public var source: String
    public var isHidden: Bool
    public var isSlim: Bool
    public var createdDate: String
    public var suggestionDate: String
    public var files: [JournalAttachmentFile]
    public var metadata: JournalJSONValue

    public init(
        id: String,
        assetType: String,
        source: String = "",
        isHidden: Bool = false,
        isSlim: Bool = false,
        createdDate: String = "",
        suggestionDate: String = "",
        files: [JournalAttachmentFile] = [],
        metadata: JournalJSONValue = .object([:])
    ) {
        self.id = id
        self.assetType = assetType
        self.source = source
        self.isHidden = isHidden
        self.isSlim = isSlim
        self.createdDate = createdDate
        self.suggestionDate = suggestionDate
        self.files = files
        self.metadata = metadata
    }
}

public enum JournalJSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JournalJSONValue])
    case object([String: JournalJSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JournalJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JournalJSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    public init?(jsonObject: Any) {
        switch jsonObject {
        case is NSNull:
            self = .null
        case let number as NSNumber:
            self = CFGetTypeID(number) == CFBooleanGetTypeID() ? .bool(number.boolValue) : .number(number.doubleValue)
        case let string as String:
            self = .string(string)
        case let array as [Any]:
            self = .array(array.compactMap { JournalJSONValue(jsonObject: $0) })
        case let object as [String: Any]:
            self = .object(object.compactMapValues { JournalJSONValue(jsonObject: $0) })
        default:
            return nil
        }
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
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

public struct JournalPhotoAttachment: Codable, Equatable, Sendable {
    public var id: String
    public var source: String
    public var isHidden: Bool
    public var isSlim: Bool
    public var assetIdentifier: String
    public var assetDate: Double?
    public var createdDate: String
    public var suggestionDate: String
    public var files: [JournalAttachmentFile]

    public init(
        id: String,
        source: String = "",
        isHidden: Bool = false,
        isSlim: Bool = false,
        assetIdentifier: String = "",
        assetDate: Double? = nil,
        createdDate: String = "",
        suggestionDate: String = "",
        files: [JournalAttachmentFile] = []
    ) {
        self.id = id
        self.source = source
        self.isHidden = isHidden
        self.isSlim = isSlim
        self.assetIdentifier = assetIdentifier
        self.assetDate = assetDate
        self.createdDate = createdDate
        self.suggestionDate = suggestionDate
        self.files = files
    }
}

public struct JournalAttachmentFile: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var relativePath: String
    public var absolutePath: String
    public var exists: Bool
    public var byteLength: Int?

    public init(
        id: String,
        name: String = "",
        relativePath: String = "",
        absolutePath: String = "",
        exists: Bool = false,
        byteLength: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.exists = exists
        self.byteLength = byteLength
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
    func deleteAttachment(entryID: String, assetID: String) throws
    func get(id: String) throws -> JournalEntryText
    func musicAttachments(id: String) throws -> [JournalMusicAttachment]
    func photoAttachments(id: String) throws -> [JournalPhotoAttachment]
    func attachments(id: String) throws -> [JournalGenericAttachment]
    func runRaw(_ arguments: [String]) throws -> String
}
