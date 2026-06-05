import Foundation

public struct MarkwayConfig: Codable, Equatable, Sendable {
    public var vaultPath: String
    public var journalToolPath: String?

    public init(vaultPath: String, journalToolPath: String? = nil) {
        self.vaultPath = vaultPath
        self.journalToolPath = journalToolPath
    }

    public static func configURL(forVault vaultURL: URL) -> URL {
        vaultURL.appendingPathComponent(".markway/config.json")
    }

    public func write(to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder.markway.encode(self)
        try data.write(to: url, options: .atomic)
    }

    public static func read(from url: URL) throws -> MarkwayConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder.markway.decode(MarkwayConfig.self, from: data)
    }
}

extension JSONEncoder {
    static var markway: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var markway: JSONDecoder {
        JSONDecoder()
    }
}
