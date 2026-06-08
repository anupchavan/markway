import Foundation
import XCTest
@testable import MarkwayCore

final class MarkwayFileBridgeTests: XCTestCase {
    func testDefaultBridgeLivesInsideVaultPluginDataDirectory() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(vaultURL: temp, journal: backend)

        XCTAssertEqual(
            bridge.bridgeURL.path,
            temp
                .appendingPathComponent(".obsidian", isDirectory: true)
                .appendingPathComponent("plugins", isDirectory: true)
                .appendingPathComponent("markway", isDirectory: true)
                .appendingPathComponent("bridge", isDirectory: true)
                .path
        )

        try bridge.prepare()
        XCTAssertTrue(FileManager.default.fileExists(atPath: bridge.requestsURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: bridge.responsesURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: bridge.eventsURL.path))
    }

    func testExplicitBridgeBaseKeepsHashedVaultDirectory() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridgeBaseURL = temp.appendingPathComponent("BridgeBase", isDirectory: true)
        let bridge = MarkwayFileBridge(vaultURL: temp, journal: backend, bridgeBaseURL: bridgeBaseURL)

        XCTAssertEqual(bridge.bridgeURL.deletingLastPathComponent().path, bridgeBaseURL.path)
        XCTAssertNotEqual(bridge.bridgeURL.path, bridgeBaseURL.path)
    }

    func testProcessesJournalPushRequestThroughBackend() throws {
        let temp = try temporaryDirectory()
        let note = temp.appendingPathComponent("Entry.md")
        try "Bridge body".write(to: note, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "JOURNAL-ID")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "REQUEST-ID",
            kind: .journalPush,
            relativePath: "Entry.md",
            journalID: "EXISTING-ID"
        )
        let requestData = try JSONEncoder.markway.encode(request)
        try requestData.write(
            to: bridge.requestsURL.appendingPathComponent("REQUEST-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(responses.first?.journalID, "EXISTING-ID")
        XCTAssertEqual(backend.addCalls.count, 0)
        XCTAssertEqual(backend.updateCalls.count, 1)
        XCTAssertEqual(backend.updateCalls.first?.id, "EXISTING-ID")
        XCTAssertFalse(FileManager.default.fileExists(atPath: bridge.requestsURL.appendingPathComponent("REQUEST-ID.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: bridge.responsesURL.appendingPathComponent("REQUEST-ID.json").path))
        XCTAssertEqual(try String(contentsOf: note), "Bridge body")
        XCTAssertFalse(bridge.bridgeURL.path.hasPrefix(temp.appendingPathComponent(".markway").path))
    }

    func testProcessesDoctorRequestThroughBackend() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(id: "DOCTOR-ID", kind: .doctor)
        let requestData = try JSONEncoder.markway.encode(request)
        try requestData.write(
            to: bridge.requestsURL.appendingPathComponent("DOCTOR-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(backend.rawCalls, [["sync-status"]])
    }

    func testEmitsPrivateBridgeEvent() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )

        try bridge.emitEvent(kind: .journalChanged)

        let eventFiles = try FileManager.default.contentsOfDirectory(
            at: bridge.eventsURL,
            includingPropertiesForKeys: nil
        )
        XCTAssertEqual(eventFiles.count, 1)

        let eventData = try Data(contentsOf: eventFiles[0])
        let event = try JSONDecoder.markway.decode(MarkwayBridgeEvent.self, from: eventData)
        XCTAssertEqual(event.kind, .journalChanged)

        let attributes = try FileManager.default.attributesOfItem(atPath: eventFiles[0].path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        XCTAssertEqual(permissions?.intValue, 0o600)
    }

    func testBridgeAgentProcessesRequestsWrittenAfterStart() throws {
        let temp = try temporaryDirectory()
        let journalContainer = temp.appendingPathComponent("JournalContainer", isDirectory: true)
        try FileManager.default.createDirectory(at: journalContainer, withIntermediateDirectories: true)
        let note = temp.appendingPathComponent("Entry.md")
        try "Agent body".write(to: note, atomically: true, encoding: .utf8)

        let bridgeBase = temp.appendingPathComponent("BridgeBase", isDirectory: true)
        let backend = RecordingJournalBackend(nextID: "AGENT-ID")
        let agent = MarkwayBridgeAgent(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: bridgeBase,
            journalContainerURL: journalContainer
        )
        try agent.start()
        defer {
            agent.stop()
        }

        let bridge = MarkwayFileBridge(vaultURL: temp, journal: backend, bridgeBaseURL: bridgeBase)
        try bridge.prepare()
        let request = MarkwayBridgeRequest(id: "AGENT-REQUEST", kind: .journalPush, relativePath: "Entry.md")
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("AGENT-REQUEST.json"),
            options: .atomic
        )

        let responseURL = bridge.responsesURL.appendingPathComponent("AGENT-REQUEST.json")
        let response = try waitForBridgeResponse(at: responseURL)

        XCTAssertEqual(response.ok, true)
        XCTAssertEqual(response.journalID, "AGENT-ID")
        XCTAssertEqual(backend.addCalls.count, 1)
        XCTAssertEqual(try String(contentsOf: backend.addCalls[0].bodyFile), "Agent body")
    }

    func testListsAndReadsJournalEntriesThroughBackend() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.listResults = [
            JournalEntrySummary(id: "ENTRY-ID", status: "active", created: "2026-06-05T00:00:00Z", title: "Title")
        ]
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let listRequest = MarkwayBridgeRequest(id: "LIST-ID", kind: .journalList)
        try JSONEncoder.markway.encode(listRequest).write(
            to: bridge.requestsURL.appendingPathComponent("LIST-ID.json"),
            options: .atomic
        )
        let getRequest = MarkwayBridgeRequest(id: "GET-ID", kind: .journalGet, journalID: "ENTRY-ID")
        try JSONEncoder.markway.encode(getRequest).write(
            to: bridge.requestsURL.appendingPathComponent("GET-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()
        let responsesByID = Dictionary(uniqueKeysWithValues: responses.map { ($0.id, $0) })

        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responsesByID["LIST-ID"]?.entries?.first?.id, "ENTRY-ID")
        XCTAssertEqual(responsesByID["GET-ID"]?.entry?.id, "ENTRY-ID")
        XCTAssertEqual(responsesByID["GET-ID"]?.entry?.body, "Body")
    }

    func testCanReadJournalEntryWithMusicAttachments() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.musicResults = [
            JournalMusicAttachment(id: "MUSIC-ID", song: "Song title", artistName: "Artist", mediaId: "MEDIA-ID")
        ]
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let getRequest = MarkwayBridgeRequest(
            id: "GET-MUSIC-ID",
            kind: .journalGet,
            journalID: "ENTRY-ID",
            includeMusicAttachments: true
        )
        try JSONEncoder.markway.encode(getRequest).write(
            to: bridge.requestsURL.appendingPathComponent("GET-MUSIC-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.entry?.musicAttachments.first?.song, "Song title")
        XCTAssertEqual(responses.first?.entry?.musicAttachments.first?.mediaId, "MEDIA-ID")
        XCTAssertEqual(backend.musicCalls, ["ENTRY-ID"])
    }

    func testProcessesJournalPullRequestThroughBackend() throws {
        let temp = try temporaryDirectory()
        let note = temp.appendingPathComponent("Pulled.md")

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "PULL-ID",
            kind: .journalPull,
            relativePath: "Pulled.md",
            journalID: "ENTRY-ID"
        )
        let requestData = try JSONEncoder.markway.encode(request)
        try requestData.write(
            to: bridge.requestsURL.appendingPathComponent("PULL-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(responses.first?.journalID, "ENTRY-ID")
        let pulled = try MarkdownDocument.read(from: note)
        XCTAssertEqual(pulled[MarkwayMetadataKey.appleJournalID], "ENTRY-ID")
        XCTAssertEqual(pulled[MarkwayMetadataKey.title], "Title")
        XCTAssertEqual(pulled.body, "Body")
    }

    func testProcessesJournalDeleteRequestThroughBackend() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "DELETE-ID",
            kind: .journalDelete,
            journalID: "ENTRY-ID"
        )
        let requestData = try JSONEncoder.markway.encode(request)
        try requestData.write(
            to: bridge.requestsURL.appendingPathComponent("DELETE-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(responses.first?.journalID, "ENTRY-ID")
        XCTAssertEqual(backend.deleteCalls, ["ENTRY-ID"])
    }

    func testProcessesJournalAttachmentDeleteRequestThroughBackend() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "DELETE-ASSET-ID",
            kind: .journalDeleteAttachment,
            journalID: "ENTRY-ID",
            assetID: "ASSET-ID"
        )
        let requestData = try JSONEncoder.markway.encode(request)
        try requestData.write(
            to: bridge.requestsURL.appendingPathComponent("DELETE-ASSET-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(responses.first?.journalID, "ENTRY-ID")
        XCTAssertEqual(backend.attachmentDeleteCalls, [["ENTRY-ID", "ASSET-ID"]])
    }

    func testRejectsBridgeRequestPathOutsideVault() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "ESCAPE-ID",
            kind: .journalPull,
            relativePath: "../outside.md",
            journalID: "ENTRY-ID"
        )
        let requestData = try JSONEncoder.markway.encode(request)
        try requestData.write(
            to: bridge.requestsURL.appendingPathComponent("ESCAPE-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?.ok, false)
        XCTAssertTrue(responses.first?.message.contains("escapes the vault") == true)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func waitForBridgeResponse(at url: URL, timeout: TimeInterval = 3) throws -> MarkwayBridgeResponse {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                return try JSONDecoder.markway.decode(MarkwayBridgeResponse.self, from: data)
            }
        }
        XCTFail("Timed out waiting for bridge response at \(url.path)")
        throw CocoaError(.fileNoSuchFile)
    }
}
