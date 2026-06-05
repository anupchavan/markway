import Foundation
import XCTest
@testable import MarkwayCore

final class MarkwayFileBridgeTests: XCTestCase {
    func testProcessesJournalPushRequestThroughBackend() throws {
        let temp = try temporaryDirectory()
        let note = temp.appendingPathComponent("Entry.md")
        try "Bridge body".write(to: note, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "JOURNAL-ID")
        let bridge = MarkwayFileBridge(vaultURL: temp, journal: backend)
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "REQUEST-ID",
            kind: .journalPush,
            filePath: note.path
        )
        let requestData = try JSONEncoder.markway.encode(request)
        try requestData.write(
            to: bridge.requestsURL.appendingPathComponent("REQUEST-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(responses.first?.journalID, "JOURNAL-ID")
        XCTAssertEqual(backend.addCalls.count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: bridge.requestsURL.appendingPathComponent("REQUEST-ID.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: bridge.responsesURL.appendingPathComponent("REQUEST-ID.json").path))
        XCTAssertEqual(try String(contentsOf: note), "Bridge body")
    }

    func testProcessesDoctorRequestThroughBackend() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(vaultURL: temp, journal: backend)
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

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
