import XCTest
@testable import MarkwayCore

final class JournalTextToolTests: XCTestCase {
    func testSanitizedEnvironmentRemovesXcodeDyldVariables() {
        let environment = JournalTextTool.sanitizedSubprocessEnvironment([
            "DYLD_INSERT_LIBRARIES": "/Applications/Xcode.app/libViewDebuggerSupport.dylib",
            "DYLD_FRAMEWORK_PATH": "/Applications/Xcode.app/Frameworks",
            "__XPC_DYLD_INSERT_LIBRARIES": "/Applications/Xcode.app/libViewDebuggerSupport.dylib",
            "__XCODE_BUILT_PRODUCTS_DIR_PATHS": "/tmp/DerivedData",
            "OS_ACTIVITY_DT_MODE": "YES",
            "PATH": "/usr/bin",
            "HOME": "/Users/test"
        ])

        XCTAssertNil(environment["DYLD_INSERT_LIBRARIES"])
        XCTAssertNil(environment["DYLD_FRAMEWORK_PATH"])
        XCTAssertNil(environment["__XPC_DYLD_INSERT_LIBRARIES"])
        XCTAssertNil(environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"])
        XCTAssertNil(environment["OS_ACTIVITY_DT_MODE"])
        XCTAssertEqual(environment["PATH"], "/usr/bin")
        XCTAssertEqual(environment["HOME"], "/Users/test")
    }

    func testAddAndUpdateRequireRichTextConverter() {
        let addEnvironment = JournalTextTool.subprocessEnvironment(
            for: ["add", "--title", "Title", "--body", "body.md"],
            base: ["PATH": "/usr/bin"]
        )
        let updateEnvironment = JournalTextTool.subprocessEnvironment(
            for: ["update", "entry-id", "--body", "body.md"],
            base: ["PATH": "/usr/bin"]
        )

        XCTAssertEqual(addEnvironment["MARKWAY_JOURNAL_RICH_TEXT_REQUIRED"], "1")
        XCTAssertEqual(updateEnvironment["MARKWAY_JOURNAL_RICH_TEXT_REQUIRED"], "1")
    }

    func testReadCommandsDoNotRequireRichTextConverter() {
        let environment = JournalTextTool.subprocessEnvironment(
            for: ["get", "entry-id"],
            base: ["PATH": "/usr/bin"]
        )

        XCTAssertNil(environment["MARKWAY_JOURNAL_RICH_TEXT_REQUIRED"])
    }

    func testParsePhotoAttachmentsFromAttachmentListJSON() throws {
        let photos = try JournalTextTool.parsePhotoAttachments(fromJSON: Self.attachmentListJSON)

        XCTAssertEqual(photos.count, 2)

        let first = try XCTUnwrap(photos.first)
        XCTAssertEqual(first.id, "C0CA3030-B29F-4CE2-AC30-EDB35E9E2BCB")
        XCTAssertEqual(first.source, "suggestionSheet")
        XCTAssertFalse(first.isHidden)
        XCTAssertFalse(first.isSlim)
        XCTAssertEqual(first.assetIdentifier, "8515CF3B-9AD0-430E-9CB5-83F010241A25:001:Aayo8Ow4z+PiXsSyimBmuP180gNM:/var/mobile/Media")
        XCTAssertEqual(first.assetDate ?? 0, 752084878.321, accuracy: 0.001)
        XCTAssertEqual(first.createdDate, "2026-06-04T18:09:27Z")
        XCTAssertEqual(first.suggestionDate, "2026-06-03T20:30:02Z")
        XCTAssertEqual(first.files.count, 1)
        XCTAssertEqual(first.files.first?.name, "image")
        XCTAssertEqual(first.files.first?.relativePath, "ENTRY-ID/C0CA3030-B29F-4CE2-AC30-EDB35E9E2BCB/5D52141E_resized.heic")
        XCTAssertEqual(first.files.first?.absolutePath, "/tmp/Attachments/ENTRY-ID/C0CA3030-B29F-4CE2-AC30-EDB35E9E2BCB/5D52141E_resized.heic")
        XCTAssertEqual(first.files.first?.exists, true)
        XCTAssertEqual(first.files.first?.byteLength, 300229)

        let second = try XCTUnwrap(photos.last)
        XCTAssertEqual(second.id, "8D981B70-C82B-4D48-B6E9-B8686AA95CEE")
        XCTAssertTrue(second.isHidden)
        XCTAssertEqual(second.files.map(\.name), ["image", "video"])
        XCTAssertEqual(second.files.first?.exists, false)
        XCTAssertNil(second.files.first?.byteLength)
    }

    func testParsePhotoAttachmentsSkipsRemovedAndNonPhotoAssets() throws {
        let photos = try JournalTextTool.parsePhotoAttachments(fromJSON: Self.attachmentListJSON)
        let ids = photos.map(\.id)

        XCTAssertFalse(ids.contains("REMOVED-PHOTO-ID"), "fully removed photos should be skipped")
        XCTAssertFalse(ids.contains("UNDOABLY-DELETED-ID"), "undoably deleted photos should be skipped")
        XCTAssertFalse(ids.contains("A4C8502B-746C-4C8C-B1B2-FB90C34D134F"), "videos should be skipped")
        XCTAssertFalse(ids.contains("11409B4B-AFB8-456F-A68D-B186F7568509"), "live photos should be skipped")
        XCTAssertFalse(ids.contains("3473717A-CF90-47DE-8CF4-423FB05245FF"), "music should be skipped")
    }

    func testParsePhotoAttachmentsRejectsInvalidJSON() {
        XCTAssertThrowsError(try JournalTextTool.parsePhotoAttachments(fromJSON: "not json"))
    }

    private static let attachmentListJSON = """
    {
      "attachmentRoot" : "/tmp/Attachments",
      "attachments" : [
        {
          "assetType" : "photo",
          "contentType" : "",
          "createdDate" : "2026-06-04T18:09:27Z",
          "dataAttachments" : [],
          "fileAttachment" : "",
          "fileAttachments" : [
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/C0CA3030-B29F-4CE2-AC30-EDB35E9E2BCB/5D52141E_resized.heic",
              "byteLength" : 300229,
              "exists" : true,
              "id" : "BA8854C7-524C-4AA5-B7F7-7EDC52A822A9",
              "index" : 0,
              "isRemovedFromCloud" : false,
              "isUploadedToCloud" : true,
              "name" : "image",
              "needsProcessing" : false,
              "parentID" : "C0CA3030-B29F-4CE2-AC30-EDB35E9E2BCB",
              "recordSystemFieldsBytes" : 1945,
              "relativePath" : "ENTRY-ID/C0CA3030-B29F-4CE2-AC30-EDB35E9E2BCB/5D52141E_resized.heic"
            }
          ],
          "id" : "C0CA3030-B29F-4CE2-AC30-EDB35E9E2BCB",
          "isFullyRemoved" : false,
          "isHidden" : false,
          "isSlim" : false,
          "isUndoablyDeleted" : false,
          "legacyOrder" : 0,
          "metadata" : {
            "assetIdentifier" : "8515CF3B-9AD0-430E-9CB5-83F010241A25:001:Aayo8Ow4z+PiXsSyimBmuP180gNM:/var/mobile/Media",
            "date" : 752084878.321,
            "landscapeCropRect" : "{{0, 0.2651515007019043}, {1, 0.375}}",
            "portraitCropRect" : "{{0.22263157367706299, 0}, {0.66666668653488159, 1}}",
            "squareCropRect" : "{{0, 0.10606060922145844}, {1, 0.75}}"
          },
          "metadataByteLength" : 324,
          "parentID" : "ENTRY-ID",
          "source" : "suggestionSheet",
          "suggestionDate" : "2026-06-03T20:30:02Z",
          "suggestionID" : "BC1AB8BA-5730-47B6-B6E0-FB2ED65BB142"
        },
        {
          "assetType" : "photo",
          "createdDate" : "2026-06-04T18:09:28Z",
          "fileAttachments" : [
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/8D981B70/video.mov",
              "exists" : false,
              "id" : "FILE-VIDEO-ID",
              "index" : 1,
              "name" : "video",
              "relativePath" : "ENTRY-ID/8D981B70/video.mov"
            },
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/8D981B70/image.heic",
              "exists" : false,
              "id" : "FILE-IMAGE-ID",
              "index" : 0,
              "name" : "image",
              "relativePath" : "ENTRY-ID/8D981B70/image.heic"
            },
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/8D981B70/orphan.heic",
              "exists" : false,
              "index" : 2,
              "name" : "image",
              "relativePath" : "ENTRY-ID/8D981B70/orphan.heic"
            }
          ],
          "id" : "8D981B70-C82B-4D48-B6E9-B8686AA95CEE",
          "isFullyRemoved" : false,
          "isHidden" : true,
          "isSlim" : false,
          "isUndoablyDeleted" : false,
          "metadata" : {
            "assetIdentifier" : "ED83F6EF-2F58-42DE-BEE7-7BD68938C4AC:001:token:/var/mobile/Media",
            "date" : 749237681.886
          },
          "parentID" : "ENTRY-ID",
          "source" : "suggestionSheet",
          "suggestionDate" : "2026-06-03T20:30:02Z"
        },
        {
          "assetType" : "photo",
          "fileAttachments" : [],
          "id" : "REMOVED-PHOTO-ID",
          "isFullyRemoved" : true,
          "isHidden" : false,
          "isSlim" : false,
          "isUndoablyDeleted" : false,
          "parentID" : "ENTRY-ID",
          "source" : "suggestionSheet"
        },
        {
          "assetType" : "photo",
          "fileAttachments" : [],
          "id" : "UNDOABLY-DELETED-ID",
          "isFullyRemoved" : false,
          "isHidden" : false,
          "isSlim" : false,
          "isUndoablyDeleted" : true,
          "parentID" : "ENTRY-ID",
          "source" : "suggestionSheet"
        },
        {
          "assetType" : "video",
          "fileAttachments" : [
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/A4C8502B/video.mov",
              "exists" : true,
              "id" : "VIDEO-FILE-ID",
              "index" : 0,
              "name" : "video",
              "relativePath" : "ENTRY-ID/A4C8502B/video.mov"
            }
          ],
          "id" : "A4C8502B-746C-4C8C-B1B2-FB90C34D134F",
          "isFullyRemoved" : false,
          "isHidden" : false,
          "isSlim" : false,
          "isUndoablyDeleted" : false,
          "metadata" : {
            "assetIdentifier" : "VIDEO-ASSET:001:token:/var/mobile/Media",
            "date" : 749237681.886
          },
          "parentID" : "ENTRY-ID",
          "source" : "suggestionSheet"
        },
        {
          "assetType" : "livePhoto",
          "fileAttachments" : [
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/11409B4B/video.mov",
              "exists" : true,
              "id" : "LIVE-VIDEO-FILE-ID",
              "index" : 0,
              "name" : "video",
              "relativePath" : "ENTRY-ID/11409B4B/video.mov"
            },
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/11409B4B/image.heic",
              "exists" : true,
              "id" : "LIVE-IMAGE-FILE-ID",
              "index" : 1,
              "name" : "image",
              "relativePath" : "ENTRY-ID/11409B4B/image.heic"
            }
          ],
          "id" : "11409B4B-AFB8-456F-A68D-B186F7568509",
          "isFullyRemoved" : false,
          "isHidden" : false,
          "isSlim" : false,
          "isUndoablyDeleted" : false,
          "parentID" : "ENTRY-ID",
          "source" : "suggestionSheet"
        },
        {
          "assetType" : "music",
          "fileAttachments" : [
            {
              "absolutePath" : "/tmp/Attachments/ENTRY-ID/3473717A/cover.heic",
              "byteLength" : 38146,
              "exists" : true,
              "id" : "MUSIC-COVER-FILE-ID",
              "index" : 0,
              "name" : "image",
              "relativePath" : "ENTRY-ID/3473717A/cover.heic"
            }
          ],
          "id" : "3473717A-CF90-47DE-8CF4-423FB05245FF",
          "isFullyRemoved" : false,
          "isHidden" : false,
          "isSlim" : false,
          "isUndoablyDeleted" : false,
          "metadata" : {
            "artistName" : "Devenderpal Singh & Amit Trivedi",
            "mediaId" : "1893886427",
            "mediaType" : {
              "song" : {}
            },
            "song" : "Ghar Di Rounak",
            "startTime" : 801747235.998275
          },
          "parentID" : "ENTRY-ID",
          "source" : "manual"
        }
      ]
    }
    """
}
