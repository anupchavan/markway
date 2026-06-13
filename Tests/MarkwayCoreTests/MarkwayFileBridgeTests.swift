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

    func testCanReadJournalEntryWithPhotoAttachments() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.photoResults = [
            JournalPhotoAttachment(
                id: "PHOTO-ID",
                source: "suggestionSheet",
                assetIdentifier: "ASSET-ID:001:token:/var/mobile/Media",
                createdDate: "2026-06-04T18:09:27Z",
                files: [
                    JournalAttachmentFile(
                        id: "FILE-ID",
                        name: "image",
                        relativePath: "ENTRY-ID/PHOTO-ID/photo.heic",
                        absolutePath: "/tmp/Attachments/ENTRY-ID/PHOTO-ID/photo.heic",
                        exists: true,
                        byteLength: 1234
                    )
                ]
            )
        ]
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let getRequest = MarkwayBridgeRequest(
            id: "GET-PHOTO-ID",
            kind: .journalGet,
            journalID: "ENTRY-ID",
            includePhotoAttachments: true
        )
        try JSONEncoder.markway.encode(getRequest).write(
            to: bridge.requestsURL.appendingPathComponent("GET-PHOTO-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.entry?.photoAttachments.first?.id, "PHOTO-ID")
        XCTAssertEqual(responses.first?.entry?.photoAttachments.first?.files.first?.relativePath, "ENTRY-ID/PHOTO-ID/photo.heic")
        XCTAssertEqual(responses.first?.entry?.photoAttachments.first?.files.first?.byteLength, 1234)
        XCTAssertEqual(backend.photoCalls, ["ENTRY-ID"])
        XCTAssertEqual(backend.musicCalls, [], "music should not be fetched unless requested")
    }

    func testPushUsesProvidedBodyInsteadOfFileContents() throws {
        let vault = try temporaryDirectory()
        let fileURL = vault.appendingPathComponent("Entry.md")
        try """
        %% photos %%
        ![[Testing - 1.jpg]]

        %% content %%
        bugis
        """.write(to: fileURL, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "PUSH-BODY-ID",
            kind: .journalPush,
            relativePath: "Entry.md",
            journalID: "ENTRY-ID",
            title: "Entry",
            body: "bugis"
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("PUSH-BODY-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(backend.updateCalls.count, 1)
        let pushedBody = try String(contentsOf: backend.updateCalls[0].bodyFile, encoding: .utf8)
        XCTAssertEqual(pushedBody, "bugis", "the bridge must push the plugin-extracted journal text, not the raw file")
    }

    func testJournalPushCanUpdateCreatedDate() throws {
        let vault = try temporaryDirectory()
        let fileURL = vault.appendingPathComponent("Entry.md")
        try "Bridge body".write(to: fileURL, atomically: true, encoding: .utf8)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "PUSH-CREATED-ID",
            kind: .journalPush,
            relativePath: "Entry.md",
            journalID: "ENTRY-ID",
            title: "Entry",
            body: "Bridge body",
            created: "2026-06-05T01:02:03Z"
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("PUSH-CREATED-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(backend.updateCalls.first?.id, "ENTRY-ID")
        XCTAssertEqual(backend.rawCalls, [["update", "ENTRY-ID", "--created", "2026-06-05T01:02:03Z"]])
    }

    func testIncludesGenericAttachmentsOnRequest() throws {
        let vault = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.attachmentResults = [
            JournalGenericAttachment(
                id: "REFLECTION-ID",
                assetType: "reflection",
                source: "suggestionSheet",
                metadata: .object(["prompt": .string("Who is your wisest friend?")])
            )
        ]
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "GET-GENERIC-ID",
            kind: .journalGet,
            journalID: "ENTRY-ID",
            includeAttachments: true
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("GET-GENERIC-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.entry?.attachments.count, 1)
        XCTAssertEqual(responses.first?.entry?.attachments.first?.assetType, "reflection")
        XCTAssertEqual(backend.attachmentCalls, ["ENTRY-ID"])
        XCTAssertEqual(backend.photoCalls, [], "photos should not be fetched unless requested")
    }

    func testExportConvertsImagesWhenExtensionsDiffer() throws {
        let vault = try temporaryDirectory()
        let store = try temporaryDirectory()
        let sourceURL = store.appendingPathComponent("photo.png")
        // 1x1 red pixel PNG.
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
        try Data(base64Encoded: pngBase64)!.write(to: sourceURL)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.photoResults = [
            JournalPhotoAttachment(
                id: "PHOTO-ID",
                files: [
                    JournalAttachmentFile(
                        id: "FILE-ID",
                        name: "image",
                        relativePath: "ENTRY-ID/PHOTO-ID/photo.png",
                        absolutePath: sourceURL.path,
                        exists: true
                    )
                ]
            )
        ]
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "EXPORT-CONVERT-ID",
            kind: .journalExportAttachment,
            relativePath: "Attachments/My Trip - 1.jpg",
            journalID: "ENTRY-ID",
            assetID: "PHOTO-ID"
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("EXPORT-CONVERT-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()
        let exported = try Data(contentsOf: vault.appendingPathComponent("Attachments/My Trip - 1.jpg"))

        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(exported.prefix(2), Data([0xFF, 0xD8]), "converted file should be JPEG")
    }

    func testExportsJournalPhotoFileIntoVault() throws {
        let vault = try temporaryDirectory()
        let store = try temporaryDirectory()
        let sourceURL = store.appendingPathComponent("photo.heic")
        try Data("photo-bytes".utf8).write(to: sourceURL)

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        backend.photoResults = [
            JournalPhotoAttachment(
                id: "PHOTO-ID",
                files: [
                    JournalAttachmentFile(
                        id: "FILE-ID",
                        name: "image",
                        relativePath: "ENTRY-ID/PHOTO-ID/photo.heic",
                        absolutePath: sourceURL.path,
                        exists: true
                    )
                ]
            )
        ]
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "EXPORT-ID",
            kind: .journalExportAttachment,
            relativePath: "Attachments/My Trip - 1.heic",
            journalID: "ENTRY-ID",
            assetID: "PHOTO-ID"
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("EXPORT-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()
        let exportedURL = vault.appendingPathComponent("Attachments/My Trip - 1.heic")

        XCTAssertEqual(responses.first?.ok, true)
        XCTAssertEqual(try String(contentsOf: exportedURL, encoding: .utf8), "photo-bytes")
        XCTAssertEqual(backend.photoCalls, ["ENTRY-ID"])
    }

    func testExportFailsForUnknownPhotoAsset() throws {
        let vault = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "EXPORT-MISSING-ID",
            kind: .journalExportAttachment,
            relativePath: "Attachments/Missing.heic",
            journalID: "ENTRY-ID",
            assetID: "MISSING-ASSET"
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("EXPORT-MISSING-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.ok, false)
        XCTAssertEqual(
            FileManager.default.fileExists(atPath: vault.appendingPathComponent("Attachments/Missing.heic").path),
            false
        )
    }

    func testAddsVaultImageAndVideoAttachments() throws {
        let vault = try temporaryDirectory()
        try Data("png-bytes".utf8).write(to: vault.appendingPathComponent("Sunset.png"))
        try Data("mov-bytes".utf8).write(to: vault.appendingPathComponent("Clip.mov"))

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        for (id, path) in [("ADD-IMAGE-ID", "Sunset.png"), ("ADD-VIDEO-ID", "Clip.mov")] {
            let request = MarkwayBridgeRequest(
                id: id,
                kind: .journalAddAttachment,
                relativePath: path,
                journalID: "ENTRY-ID"
            )
            try JSONEncoder.markway.encode(request).write(
                to: bridge.requestsURL.appendingPathComponent("\(id).json"),
                options: .atomic
            )
        }

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.map(\.ok), [true, true])
        XCTAssertEqual(backend.rawCalls, [
            ["attachments", "add-photo", "ENTRY-ID", vault.appendingPathComponent("Sunset.png").resolvingSymlinksInPath().path],
            ["attachments", "add-video", "ENTRY-ID", vault.appendingPathComponent("Clip.mov").resolvingSymlinksInPath().path],
        ])
    }

    func testRejectsUnsupportedAttachmentTypes() throws {
        let vault = try temporaryDirectory()
        try Data("text".utf8).write(to: vault.appendingPathComponent("Notes.txt"))

        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "ADD-TEXT-ID",
            kind: .journalAddAttachment,
            relativePath: "Notes.txt",
            journalID: "ENTRY-ID"
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("ADD-TEXT-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.ok, false)
        XCTAssertEqual(backend.rawCalls, [])
    }

    func testRejectsAttachmentRequestsOutsideVault() throws {
        let vault = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: vault,
            journal: backend,
            bridgeBaseURL: vault.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(
            id: "ADD-ESCAPE-ID",
            kind: .journalAddAttachment,
            relativePath: "../outside.png",
            journalID: "ENTRY-ID"
        )
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("ADD-ESCAPE-ID.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.first?.ok, false)
        XCTAssertEqual(backend.rawCalls, [])
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

    func testRejectsUnsafeBridgeRequestIDWithoutWritingOutsideResponses() throws {
        let temp = try temporaryDirectory()
        let backend = RecordingJournalBackend(nextID: "UNUSED")
        let bridge = MarkwayFileBridge(
            vaultURL: temp,
            journal: backend,
            bridgeBaseURL: temp.appendingPathComponent("BridgeBase")
        )
        try bridge.prepare()

        let request = MarkwayBridgeRequest(id: "../ESCAPED", kind: .doctor)
        try JSONEncoder.markway.encode(request).write(
            to: bridge.requestsURL.appendingPathComponent("MALICIOUS.json"),
            options: .atomic
        )

        let responses = try bridge.processPendingRequests()

        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?.id, "MALICIOUS")
        XCTAssertEqual(responses.first?.ok, false)
        XCTAssertTrue(responses.first?.message.contains("unsafe characters") == true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: bridge.bridgeURL.appendingPathComponent("ESCAPED.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: bridge.responsesURL.appendingPathComponent("MALICIOUS.json").path))
        XCTAssertEqual(backend.rawCalls, [])
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
