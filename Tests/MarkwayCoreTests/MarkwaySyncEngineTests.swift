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
    var rawCalls: [[String]] = []
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

    func get(id: String) throws -> JournalEntryText {
        JournalEntryText(id: id, title: "Title", body: "Body")
    }

    func list() throws -> [JournalEntrySummary] {
        []
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
