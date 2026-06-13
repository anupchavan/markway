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

    public func pushMarkdownFile(
        _ fileURL: URL,
        title explicitTitle: String? = nil,
        existingID explicitExistingID: String? = nil,
        writeMetadata: Bool = true,
        stripTitleHeading: Bool = false,
        bodyOverride: String? = nil,
        createdDate: String? = nil
    ) throws -> String {
        var document = try MarkdownDocument.read(from: fileURL)
        let title = explicitTitle
            ?? document[MarkwayMetadataKey.title]
            ?? fileURL.deletingPathExtension().lastPathComponent

        // The Obsidian plugin separates the journal text from generated
        // template sections and sends only the journal text; pushing the raw
        // file would copy template output into the Journal entry.
        let rawBody = bodyOverride ?? document.body
        let body = stripTitleHeading ? Self.stripGeneratedTitleHeading(from: rawBody, title: title) : rawBody
        let bodyURL = try writeTemporaryBody(body)
        defer { try? FileManager.default.removeItem(at: bodyURL) }

        let id: String
        let existingID = Self.normalizedJournalID(explicitExistingID)
            ?? Self.normalizedJournalID(document[MarkwayMetadataKey.appleJournalID])
        if let existingID {
            do {
                try journal.update(id: existingID, title: title, bodyFile: bodyURL)
                id = existingID
            } catch {
                guard Self.shouldCreateEntryAfterUpdateFailure(error) else {
                    throw error
                }
                id = try journal.add(title: title, bodyFile: bodyURL)
                document[MarkwayMetadataKey.appleJournalID] = id
            }
        } else {
            id = try journal.add(title: title, bodyFile: bodyURL)
            document[MarkwayMetadataKey.appleJournalID] = id
        }

        if let createdDate, !createdDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try journal.updateCreatedDate(id: id, created: createdDate)
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
        let existingDocument = FileManager.default.fileExists(atPath: fileURL.path)
            ? try MarkdownDocument.read(from: fileURL)
            : nil
        var frontmatter = existingDocument?.frontmatter ?? [:]
        frontmatter[MarkwayMetadataKey.appleJournalID] = entry.id
        frontmatter[MarkwayMetadataKey.title] = entry.title
        frontmatter[MarkwayMetadataKey.lastSyncedAt] = ISO8601DateFormatter().string(from: clock())
        let body = existingDocument.map {
            MarkdownStructurePreserver.preserve(existingBody: $0.body, journalBody: entry.body)
        } ?? entry.body
        let document = MarkdownDocument(
            frontmatter: frontmatter,
            body: body
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

    private static func normalizedJournalID(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func shouldCreateEntryAfterUpdateFailure(_ error: Error) -> Bool {
        let message = String(describing: error).lowercased()
        return message.contains("update requires uuid")
            || message.contains("invalid uuid")
            || message.contains("entry not found")
    }

    static func stripGeneratedTitleHeading(from body: String, title: String) -> String {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            return body
        }

        let normalizedBody = body.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let heading = "# \(normalizedTitle)"
        guard normalizedBody == heading || normalizedBody.hasPrefix("\(heading)\n") else {
            return body
        }

        var remainder = String(normalizedBody.dropFirst(heading.count))
        if remainder.hasPrefix("\n\n") {
            remainder.removeFirst(2)
        } else if remainder.hasPrefix("\n") {
            remainder.removeFirst()
        }
        return remainder
    }
}

enum MarkdownStructurePreserver {
    static func preserve(existingBody: String, journalBody: String) -> String {
        guard existingBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return journalBody
        }

        let existing = normalizedLines(existingBody)
        let journal = normalizedLines(journalBody)
        var output: [String] = []
        var existingIndex = 0
        var journalIndex = 0

        while existingIndex < existing.count {
            let existingLine = existing[existingIndex]

            if isBlank(existingLine) {
                if journal.indices.contains(journalIndex), isBlank(journal[journalIndex]) {
                    output.append(journal[journalIndex])
                    journalIndex += 1
                } else {
                    output.append(existingLine)
                }
                existingIndex += 1
                continue
            }

            if isFenceStart(existingLine) {
                let block = collectFencedBlock(lines: existing, start: existingIndex)
                let journalCode = takeJournalCodeBlock(lines: journal, start: journalIndex, fallbackLength: block.content.count)
                output.append(block.opening)
                output.append(contentsOf: journalCode.lines)
                output.append(block.closing)
                journalIndex = journalCode.nextIndex
                existingIndex = block.nextIndex
                continue
            }

            let journalLine = takeJournalContentLine(lines: journal, start: journalIndex)
            let current = journalLine.line ?? existingLine
            journalIndex = journalLine.nextIndex

            if let heading = firstMatch(#"^(\s{0,3})(#{1,6})\s+(.*)$"#, in: existingLine) {
                output.append("\(heading[1])\(heading[2]) \(markdownLineText(current))")
                existingIndex += 1
                continue
            }

            if let quote = firstMatch(#"^(\s{0,3}>\s?)(.*)$"#, in: existingLine) {
                output.append("\(quote[1])\(markdownLineText(current))")
                existingIndex += 1
                continue
            }

            if isThematicBreak(existingLine) {
                if isThematicBreak(current) {
                    journalIndex = journalLine.nextIndex
                } else {
                    journalIndex = journalLine.startIndex
                }
                output.append(existingLine)
                existingIndex += 1
                continue
            }

            let list = firstMatch(#"^(\s*)((?:[-*+])|(?:\d+[.)]))\s+(.*)$"#, in: existingLine)
            let currentIsList = firstMatch(#"^(\s*)((?:[-*+])|(?:\d+[.)]))\s+"#, in: current) != nil
            if let list, !currentIsList {
                output.append("\(list[1])\(list[2]) \(markdownLineText(current))")
                existingIndex += 1
                continue
            }

            output.append(current)
            existingIndex += 1
        }

        if journalIndex < journal.count {
            output.append(contentsOf: journal[journalIndex...])
        }

        return alignTrailingBlankLines(output: output, journal: journal).joined(separator: "\n")
    }

    private struct FencedBlock {
        var opening: String
        var closing: String
        var content: [String]
        var nextIndex: Int
    }

    private struct LineTake {
        var line: String?
        var startIndex: Int
        var nextIndex: Int
    }

    private static func normalizedLines(_ value: String) -> [String] {
        value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    private static func isBlank(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func isFenceStart(_ line: String) -> Bool {
        firstMatch(#"^ {0,3}(`{3,}|~{3,})"#, in: line) != nil
    }

    private static func isFenceClose(_ line: String, opener: String) -> Bool {
        let trimmed = opener.trimmingCharacters(in: .whitespaces)
        let marker = trimmed.hasPrefix("~") ? "~" : "`"
        let count = max(3, trimmed.prefix { String($0) == marker }.count)
        return firstMatch("^ {0,3}\(NSRegularExpression.escapedPattern(for: String(repeating: marker, count: count)))\\s*$", in: line) != nil
    }

    private static func collectFencedBlock(lines: [String], start: Int) -> FencedBlock {
        let opening = lines.indices.contains(start) ? lines[start] : "```"
        var content: [String] = []
        var index = start + 1
        while index < lines.count {
            let line = lines[index]
            if isFenceClose(line, opener: opening) {
                return FencedBlock(opening: opening, closing: line, content: content, nextIndex: index + 1)
            }
            content.append(line)
            index += 1
        }
        return FencedBlock(opening: opening, closing: opening.trimmingCharacters(in: .whitespaces).hasPrefix("~") ? "~~~" : "```", content: content, nextIndex: index)
    }

    private static func takeJournalCodeBlock(lines: [String], start: Int, fallbackLength: Int) -> (lines: [String], nextIndex: Int) {
        var index = skipBlankLines(lines: lines, start: start)
        if lines.indices.contains(index), isFenceStart(lines[index]) {
            let block = collectFencedBlock(lines: lines, start: index)
            return (block.content, block.nextIndex)
        }

        var content: [String] = []
        let length = max(1, fallbackLength)
        while index < lines.count, content.count < length {
            let line = lines[index]
            if isBlank(line), !content.isEmpty {
                break
            }
            content.append(line)
            index += 1
        }
        return (content, index)
    }

    private static func takeJournalContentLine(lines: [String], start: Int) -> LineTake {
        let contentIndex = skipBlankLines(lines: lines, start: start)
        guard lines.indices.contains(contentIndex) else {
            return LineTake(line: nil, startIndex: start, nextIndex: contentIndex)
        }
        return LineTake(line: lines[contentIndex], startIndex: contentIndex, nextIndex: contentIndex + 1)
    }

    private static func skipBlankLines(lines: [String], start: Int) -> Int {
        var index = start
        while lines.indices.contains(index), isBlank(lines[index]) {
            index += 1
        }
        return index
    }

    private static func alignTrailingBlankLines(output: [String], journal: [String]) -> [String] {
        let desiredTrailingBlanks = trailingBlankLineCount(journal)
        let currentTrailingBlanks = trailingBlankLineCount(output)
        guard currentTrailingBlanks != desiredTrailingBlanks else {
            return output
        }

        return Array(output.dropLast(currentTrailingBlanks))
            + Array(repeating: "", count: desiredTrailingBlanks)
    }

    private static func trailingBlankLineCount(_ lines: [String]) -> Int {
        var count = 0
        for line in lines.reversed() {
            guard isBlank(line) else {
                break
            }
            count += 1
        }
        return count
    }

    private static func markdownLineText(_ line: String) -> String {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if let heading = firstMatch(#"^#{1,6}\s+(.*)$"#, in: text) {
            text = heading[1]
        }
        if let quote = firstMatch(#"^>\s?(.*)$"#, in: text) {
            text = quote[1]
        }
        if let list = firstMatch(#"^((?:[-*+])|(?:\d+[.)]))\s+(.*)$"#, in: text) {
            text = list[2]
        }

        let wrappers = [
            #"^\*\*\*(.*)\*\*\*$"#,
            #"^___(.*)___$"#,
            #"^\*\*(.*)\*\*$"#,
            #"^__(.*)__$"#,
            #"^\*(.*)\*$"#,
            #"^_(.*)_$"#,
            #"^`(.*)`$"#,
        ]
        var changed = true
        while changed {
            changed = false
            for wrapper in wrappers {
                if let match = firstMatch(wrapper, in: text) {
                    text = match[1]
                    changed = true
                }
            }
        }
        return text
    }

    private static func isThematicBreak(_ line: String) -> Bool {
        firstMatch(#"^ {0,3}((?:-\s*){3,}|(?:_\s*){3,}|(?:\*\s*){3,})$"#, in: line) != nil
    }

    private static func firstMatch(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange) else {
            return nil
        }
        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound, let stringRange = Range(range, in: text) else {
                return ""
            }
            return String(text[stringRange])
        }
    }
}
