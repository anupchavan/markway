import XCTest
@testable import MarkwayCore

final class JournalGenericAttachmentTests: XCTestCase {
    func testParsesAllAssetTypesInJournalOrder() throws {
        let attachments = try JournalTextTool.parseGenericAttachments(fromJSON: Self.fixtureJSON)

        XCTAssertEqual(attachments.map(\.assetType), ["photo", "music", "reflection", "multiPinMap"])
        XCTAssertEqual(attachments.map(\.id), ["PHOTO-ID", "MUSIC-ID", "REFLECTION-ID", "MAP-ID"])
    }

    func testSkipsRemovedAttachments() throws {
        let attachments = try JournalTextTool.parseGenericAttachments(fromJSON: Self.fixtureJSON)
        XCTAssertFalse(attachments.contains { $0.id == "REMOVED-ID" })
    }

    func testParsesPhotoFiles() throws {
        let attachments = try JournalTextTool.parseGenericAttachments(fromJSON: Self.fixtureJSON)
        let photo = attachments[0]

        XCTAssertEqual(photo.files.count, 1)
        XCTAssertEqual(photo.files.first?.relativePath, "ENTRY-ID/PHOTO-ID/photo.heic")
        XCTAssertEqual(photo.source, "suggestionSheet")
    }

    func testDecodesReflectionPromptAndColors() throws {
        let attachments = try JournalTextTool.parseGenericAttachments(fromJSON: Self.fixtureJSON)
        let reflection = attachments[2]

        guard case .object(let metadata) = reflection.metadata else {
            return XCTFail("reflection metadata should be an object")
        }
        XCTAssertEqual(
            metadata["prompt"]?.stringValue,
            "Who is your wisest friend? What have you learned from them recently?"
        )
        XCTAssertEqual(metadata["colorLight"]?.stringValue, "#212438")
    }

    func testDropsMapItemBlobsButKeepsVisits() throws {
        let attachments = try JournalTextTool.parseGenericAttachments(fromJSON: Self.fixtureJSON)
        let map = attachments[3]

        guard case .object(let metadata) = map.metadata,
              case .array(let visits) = metadata["visitsData"],
              case .object(let visit) = visits.first else {
            return XCTFail("map metadata should contain visitsData objects")
        }
        XCTAssertEqual(visit["city"]?.stringValue, "Mamidipalle")
        XCTAssertNil(visit["mapItemData"])
        if case .number(let latitude)? = visit["latitude"] {
            XCTAssertEqual(latitude, 17.5946539, accuracy: 0.000001)
        } else {
            XCTFail("latitude should be numeric")
        }
    }

    func testMusicMetadataPassesThrough() throws {
        let attachments = try JournalTextTool.parseGenericAttachments(fromJSON: Self.fixtureJSON)
        let music = attachments[1]

        guard case .object(let metadata) = music.metadata else {
            return XCTFail("music metadata should be an object")
        }
        XCTAssertEqual(metadata["song"]?.stringValue, "Sahiba")
        XCTAssertEqual(metadata["artistName"]?.stringValue, "Aditya Rikhari")
    }

    // Reflection blobs are real values captured from a Journal store snapshot.
    static let fixtureJSON = """
    {
      "attachmentRoot": "/tmp/Attachments",
      "attachments": [
        {
          "id": "PHOTO-ID",
          "assetType": "photo",
          "source": "suggestionSheet",
          "isHidden": false,
          "isSlim": false,
          "createdDate": "2026-06-04T18:09:27Z",
          "suggestionDate": "2026-06-03T20:30:02Z",
          "metadata": {
            "assetIdentifier": "8515CF3B-9AD0-430E-9CB5-83F010241A25:001:token:/var/mobile/Media",
            "date": 752084878.321
          },
          "fileAttachments": [
            {
              "id": "FILE-ID",
              "index": 0,
              "name": "image",
              "relativePath": "ENTRY-ID/PHOTO-ID/photo.heic",
              "absolutePath": "/tmp/Attachments/ENTRY-ID/PHOTO-ID/photo.heic",
              "exists": true,
              "byteLength": 300229
            }
          ]
        },
        {
          "id": "MUSIC-ID",
          "assetType": "music",
          "source": "suggestionSheet",
          "metadata": {
            "song": "Sahiba",
            "artistName": "Aditya Rikhari",
            "mediaId": "1798404742"
          },
          "fileAttachments": []
        },
        {
          "id": "REFLECTION-ID",
          "assetType": "reflection",
          "source": "suggestionSheet",
          "metadata": {
            "type": 1,
            "prompt": "e1xydGYxXGFuc2lcYW5zaWNwZzEyNTJcY29jb2FydGYyODY5Clxjb2NvYXRleHRzY2FsaW5nMVxjb2NvYXBsYXRmb3JtMXtcZm9udHRibFxmMFxmc3dpc3NcZmNoYXJzZXQwIEhlbHZldGljYTt9CntcY29sb3J0Ymw7XHJlZDI1NVxncmVlbjI1NVxibHVlMjU1O30Ke1wqXGV4cGFuZGVkY29sb3J0Ymw7O30KXHBhcmRcdHg1NjBcdHgxMTIwXHR4MTY4MFx0eDIyNDBcdHgyODAwXHR4MzM2MFx0eDM5MjBcdHg0NDgwXHR4NTA0MFx0eDU2MDBcdHg2MTYwXHR4NjcyMFxwYXJkaXJuYXR1cmFsXHBhcnRpZ2h0ZW5mYWN0b3IwCgpcZjBcZnMyNCBcY2YwIFdobyBpcyB5b3VyIHdpc2VzdCBmcmllbmQ/IFdoYXQgaGF2ZSB5b3UgbGVhcm5lZCBmcm9tIHRoZW0gcmVjZW50bHk/fQ==",
            "colorLight": "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwjVSRudWxs2w0ODxAREhMUFRYXGBkaGxwdHh8gISJfEBVVSUNvbG9yQ29tcG9uZW50Q291bnRXVUlHcmVlblZVSUJsdWVdVUlCbHVlLURvdWJsZVdVSUFscGhhVU5TUkdCXFVJUmVkLURvdWJsZVVVSVJlZFxOU0NvbG9yU3BhY2VWJGNsYXNzXlVJR3JlZW4tRG91YmxlEAQiPhCQkSI+YODhIz/MHBwcHBwcIj+AAABPEBAwLjEyOSAwLjE0MSAwLjIyIz/AkJCQkJCRIj4EhIUQAoACIz/CEhISEhIS0yQlJicoKlokY2xhc3NuYW1lWCRjbGFzc2VzWyRjbGFzc2hpbnRzV1VJQ29sb3KiJylYTlNPYmplY3ShK1dOU0NvbG9yAAgAEQAaACQAKQAyADcASQBMAFEAUwBXAF0AdACMAJQAmwCpALEAtwDEAMoA1wDeAO0A7wD0APkBAgEHARoBIwEoASoBLAE1ATwBRwFQAVwBZAFnAXABcgAAAAAAAAIBAAAAAAAAACwAAAAAAAAAAAAAAAAAAAF6"
          },
          "fileAttachments": []
        },
        {
          "id": "MAP-ID",
          "assetType": "multiPinMap",
          "source": "locationPicker",
          "metadata": {
            "visitsData": [
              {
                "assetSource": "automatic",
                "city": "Mamidipalle",
                "latitude": 17.5946539,
                "longitude": 78.123258,
                "isWork": false,
                "createdDate": 802197235.614703,
                "mapItemData": "YnBsaXN0MDA="
              }
            ]
          },
          "fileAttachments": []
        },
        {
          "id": "REMOVED-ID",
          "assetType": "photo",
          "isFullyRemoved": true,
          "metadata": {},
          "fileAttachments": []
        }
      ]
    }
    """
}
