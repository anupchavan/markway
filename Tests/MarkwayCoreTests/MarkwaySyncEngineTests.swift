import Foundation
import XCTest
@testable import MarkwayCore

final class MarkwaySyncEngineTests: XCTestCase {
    func testPushCreatesJournalEntryAndWritesFrontmatter() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try "Hello **world**".write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "ENTRY-ID")
        let engine = MarkwaySyncEngine(journal: backend, clock: { Date(timeIntervalSince1970: 0) })
        let id = try engine.pushMarkdownFile(file, title: "Hello")

        XCTAssertEqual(id, "ENTRY-ID")
        XCTAssertEqual(backend.addCalls.count, 1)
        XCTAssertEqual(backend.addCalls.first?.title, "Hello")
        XCTAssertEqual(try String(contentsOf: backend.addCalls.first!.bodyFile), "Hello **world**")

        let updated = try MarkdownDocument.read(from: file)
        XCTAssertEqual(updated[MarkwayMetadataKey.appleJournalID], "ENTRY-ID")
        XCTAssertEqual(updated[MarkwayMetadataKey.title], "Hello")
        XCTAssertEqual(updated[MarkwayMetadataKey.lastSyncedAt], "1970-01-01T00:00:00Z")
    }

    func testPushUpdatesExistingJournalEntryWithoutSendingFrontmatter() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try """
        ---
        markway.appleJournalID: "EXISTING"
        title: "Old"
        ---
        Updated body
        """.write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let engine = MarkwaySyncEngine(journal: backend, clock: { Date(timeIntervalSince1970: 0) })
        let id = try engine.pushMarkdownFile(file, title: "New")

        XCTAssertEqual(id, "EXISTING")
        XCTAssertEqual(backend.updateCalls.count, 1)
        XCTAssertEqual(backend.updateCalls.first?.id, "EXISTING")
        XCTAssertEqual(backend.updateCalls.first?.title, "New")
        XCTAssertEqual(try String(contentsOf: backend.updateCalls.first!.bodyFile), "Updated body")
    }

    func testPushCanUseExistingIDOutsideFrontmatter() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try "Updated body".write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let engine = MarkwaySyncEngine(journal: backend, clock: { Date(timeIntervalSince1970: 0) })
        let id = try engine.pushMarkdownFile(file, title: "New", existingID: "EXISTING")

        XCTAssertEqual(id, "EXISTING")
        XCTAssertEqual(backend.addCalls.count, 0)
        XCTAssertEqual(backend.updateCalls.count, 1)
        XCTAssertEqual(try String(contentsOf: backend.updateCalls.first!.bodyFile), "Updated body")
    }

    func testPushCanLeaveFrontmatterForCallerToWrite() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try "Hello".write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "ENTRY-ID")
        let engine = MarkwaySyncEngine(journal: backend, clock: { Date(timeIntervalSince1970: 0) })
        let id = try engine.pushMarkdownFile(file, title: "Hello", writeMetadata: false)

        XCTAssertEqual(id, "ENTRY-ID")
        XCTAssertEqual(try String(contentsOf: file), "Hello")
    }

    func testPushCanStripGeneratedTitleHeading() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try """
        # Entry

        Body
        """.write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "ENTRY-ID")
        let engine = MarkwaySyncEngine(journal: backend)

        _ = try engine.pushMarkdownFile(file, title: "Entry", writeMetadata: false, stripTitleHeading: true)

        XCTAssertEqual(try String(contentsOf: backend.addCalls.first!.bodyFile), "Body")
    }

    func testPushDoesNotStripUnrelatedHeading() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try """
        # Different

        Body
        """.write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "ENTRY-ID")
        let engine = MarkwaySyncEngine(journal: backend)

        _ = try engine.pushMarkdownFile(file, title: "Entry", writeMetadata: false, stripTitleHeading: true)

        XCTAssertEqual(try String(contentsOf: backend.addCalls.first!.bodyFile), "# Different\n\nBody")
    }

    func testPullPreservesMarkdownStructureWhenJournalNormalizesTextAttributes() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try """
        ---
        custom: "keep"
        ---
        ui maa **bold** *italic*

        ## ok

        - item 1

        1. two
        1. three
        1. four

        ```
        const ok = "strong"
        ```

        > Take me back to the night we met

        --------
        """.write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.getResults["ENTRY-ID"] = JournalEntryText(
            id: "ENTRY-ID",
            title: "Entry",
            body: """
            ui maa **bold** *italic*

            **okidoki**

            - item 1

            1. two
            1. three
            1. four

            const ok = "strong"

            Take me back to the night we met
            """
        )
        let engine = MarkwaySyncEngine(journal: backend, clock: { Date(timeIntervalSince1970: 0) })

        try engine.pullJournalEntry(id: "ENTRY-ID", to: file)

        let document = try MarkdownDocument.read(from: file)
        XCTAssertEqual(document["custom"], "keep")
        XCTAssertEqual(document[MarkwayMetadataKey.appleJournalID], "ENTRY-ID")
        XCTAssertEqual(document.body, """
        ui maa **bold** *italic*

        ## okidoki

        - item 1

        1. two
        1. three
        1. four

        ```
        const ok = "strong"
        ```

        > Take me back to the night we met

        --------
        """)
    }

    func testPullPreservesExistingFenceLanguage() throws {
        let temp = try temporaryDirectory()
        let file = temp.appendingPathComponent("Entry.md")
        try """
        ```js
        const ok = 1
        ```
        """.write(to: file, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.getResults["ENTRY-ID"] = JournalEntryText(id: "ENTRY-ID", title: "Entry", body: "const ok = 2")
        let engine = MarkwaySyncEngine(journal: backend)

        try engine.pullJournalEntry(id: "ENTRY-ID", to: file)

        let document = try MarkdownDocument.read(from: file)
        XCTAssertEqual(document.body, """
        ```js
        const ok = 2
        ```
        """)
    }

    func testPreserverDoesNotKeepStaleExtraTrailingBlankLines() {
        XCTAssertEqual(
            MarkdownStructurePreserver.preserve(existingBody: "Body\n\n\n\n\n", journalBody: "Body\n"),
            "Body\n"
        )
    }

    func testPreserverKeepsTrailingBlankLinesPresentInJournalBody() {
        XCTAssertEqual(
            MarkdownStructurePreserver.preserve(existingBody: "Body\n", journalBody: "Body\n\n\n"),
            "Body\n\n\n"
        )
    }

    func testScanVaultPlansCreatesAndUpdates() throws {
        let temp = try temporaryDirectory()
        try FileManager.default.createDirectory(at: temp.appendingPathComponent(".obsidian"), withIntermediateDirectories: true)
        try "# Scratch".write(to: temp.appendingPathComponent(".obsidian/ignored.md"), atomically: true, encoding: .utf8)
        try "New".write(to: temp.appendingPathComponent("New.md"), atomically: true, encoding: .utf8)
        try """
        ---
        markway.appleJournalID: "ABC"
        ---
        Existing
        """.write(to: temp.appendingPathComponent("Existing.md"), atomically: true, encoding: .utf8)

        let engine = MarkwaySyncEngine(journal: RecordingJournalBackend(nextID: "UNUSED"))
        let summary = try engine.scanVault(at: temp)

        XCTAssertEqual(summary.markdownFiles, 2)
        XCTAssertEqual(summary.linkedJournalEntries, 1)
        XCTAssertEqual(summary.unlinkedMarkdownFiles, 1)
        XCTAssertEqual(summary.actions.count, 2)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

final class RecordingJournalBackend: JournalBackend, @unchecked Sendable {
    struct AddCall {
        var title: String
        var bodyFile: URL
    }

    struct UpdateCall {
        var id: String
        var title: String
        var bodyFile: URL
    }

    var addCalls: [AddCall] = []
    var updateCalls: [UpdateCall] = []
    var deleteCalls: [String] = []
    var attachmentDeleteCalls: [[String]] = []
    var rawCalls: [[String]] = []
    var listResults: [JournalEntrySummary] = []
    var musicResults: [JournalMusicAttachment] = []
    var musicCalls: [String] = []
    var getResults: [String: JournalEntryText] = [:]
    let nextID: String

    init(nextID: String) {
        self.nextID = nextID
    }

    func add(title: String, bodyFile: URL) throws -> String {
        let copied = try copyBodyFile(bodyFile)
        addCalls.append(AddCall(title: title, bodyFile: copied))
        return nextID
    }

    func update(id: String, title: String, bodyFile: URL) throws {
        let copied = try copyBodyFile(bodyFile)
        updateCalls.append(UpdateCall(id: id, title: title, bodyFile: copied))
    }

    func delete(id: String) throws {
        deleteCalls.append(id)
    }

    func deleteAttachment(entryID: String, assetID: String) throws {
        attachmentDeleteCalls.append([entryID, assetID])
    }

    func get(id: String) throws -> JournalEntryText {
        if let result = getResults[id] {
            return result
        }
        return JournalEntryText(id: id, title: "Title", body: "Body")
    }

    func list() throws -> [JournalEntrySummary] {
        listResults
    }

    func musicAttachments(id: String) throws -> [JournalMusicAttachment] {
        musicCalls.append(id)
        return musicResults
    }

    func runRaw(_ arguments: [String]) throws -> String {
        rawCalls.append(arguments)
        return ""
    }

    private func copyBodyFile(_ url: URL) throws -> URL {
        let copy = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("md")
        try FileManager.default.copyItem(at: url, to: copy)
        return copy
    }
}
