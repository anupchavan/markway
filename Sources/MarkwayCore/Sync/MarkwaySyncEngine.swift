import Foundation

public enum MarkwayMetadataKey {
    public static let title = "title"
    public static let appleJournalID = "markway.appleJournalID"
    public static let lastSyncedAt = "markway.lastSyncedAt"
}

public enum MarkwaySyncAction: Equatable, Sendable {
    case createJournalEntry(path: String)
    case updateJournalEntry(path: String, id: String)
}

public struct VaultScanSummary: Equatable, Sendable {
    public var markdownFiles: Int
    public var linkedJournalEntries: Int
    public var unlinkedMarkdownFiles: Int
    public var actions: [MarkwaySyncAction]

    public init(markdownFiles: Int, linkedJournalEntries: Int, unlinkedMarkdownFiles: Int, actions: [MarkwaySyncAction]) {
        self.markdownFiles = markdownFiles
        self.linkedJournalEntries = linkedJournalEntries
        self.unlinkedMarkdownFiles = unlinkedMarkdownFiles
        self.actions = actions
    }
}

public struct MarkwaySyncEngine<Backend: JournalBackend>: Sendable {
    public let journal: Backend
    public let clock: @Sendable () -> Date

    public init(journal: Backend, clock: @escaping @Sendable () -> Date = Date.init) {
        self.journal = journal
        self.clock = clock
    }

    public func pushMarkdownFile(_ fileURL: URL, title explicitTitle: String? = nil, writeMetadata: Bool = true) throws -> String {
        var document = try MarkdownDocument.read(from: fileURL)
        let title = explicitTitle
            ?? document[MarkwayMetadataKey.title]
            ?? fileURL.deletingPathExtension().lastPathComponent

        let bodyURL = try writeTemporaryBody(document.body)
        defer { try? FileManager.default.removeItem(at: bodyURL) }

        let id: String
        if let existingID = document[MarkwayMetadataKey.appleJournalID], !existingID.isEmpty {
            try journal.update(id: existingID, title: title, bodyFile: bodyURL)
            id = existingID
        } else {
            id = try journal.add(title: title, bodyFile: bodyURL)
            document[MarkwayMetadataKey.appleJournalID] = id
        }

        document[MarkwayMetadataKey.title] = title
        document[MarkwayMetadataKey.lastSyncedAt] = ISO8601DateFormatter().string(from: clock())
        if writeMetadata {
            try document.write(to: fileURL)
        }
        return id
    }

    public func pullJournalEntry(id: String, to fileURL: URL) throws {
        let entry = try journal.get(id: id)
        let document = MarkdownDocument(
            frontmatter: [
                MarkwayMetadataKey.appleJournalID: entry.id,
                MarkwayMetadataKey.title: entry.title,
                MarkwayMetadataKey.lastSyncedAt: ISO8601DateFormatter().string(from: clock())
            ],
            body: entry.body
        )
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try document.write(to: fileURL)
    }

    public func scanVault(at vaultURL: URL) throws -> VaultScanSummary {
        var markdownFiles = 0
        var linkedJournalEntries = 0
        var actions: [MarkwaySyncAction] = []

        guard let enumerator = FileManager.default.enumerator(
            at: vaultURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return VaultScanSummary(markdownFiles: 0, linkedJournalEntries: 0, unlinkedMarkdownFiles: 0, actions: [])
        }

        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            if excludedDirectoryNames.contains(name) {
                enumerator.skipDescendants()
                continue
            }

            guard url.pathExtension.lowercased() == "md" else {
                continue
            }

            markdownFiles += 1
            let document = try MarkdownDocument.read(from: url)
            if let id = document[MarkwayMetadataKey.appleJournalID], !id.isEmpty {
                linkedJournalEntries += 1
                actions.append(.updateJournalEntry(path: url.path, id: id))
            } else {
                actions.append(.createJournalEntry(path: url.path))
            }
        }

        return VaultScanSummary(
            markdownFiles: markdownFiles,
            linkedJournalEntries: linkedJournalEntries,
            unlinkedMarkdownFiles: markdownFiles - linkedJournalEntries,
            actions: actions
        )
    }

    private func writeTemporaryBody(_ body: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("markway-\(UUID().uuidString)")
            .appendingPathExtension("md")
        try body.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private var excludedDirectoryNames: Set<String> {
        [".git", ".markway", ".obsidian", "node_modules"]
    }
}
