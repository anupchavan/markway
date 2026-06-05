import XCTest
@testable import MarkwayCore

final class MarkdownDocumentTests: XCTestCase {
    func testParsesFrontmatterAndBody() {
        let document = MarkdownDocument.parse("""
        ---
        title: "Flexoki"
        markway.appleJournalID: "ABC"
        ---
        Body text
        """)

        XCTAssertEqual(document[MarkwayMetadataKey.title], "Flexoki")
        XCTAssertEqual(document[MarkwayMetadataKey.appleJournalID], "ABC")
        XCTAssertEqual(document.body, "Body text")
    }

    func testSerializesStableQuotedFrontmatter() {
        let document = MarkdownDocument(frontmatter: [
            MarkwayMetadataKey.title: "A title: with colon",
            MarkwayMetadataKey.appleJournalID: "ABC"
        ], body: "Body")

        XCTAssertEqual(document.serialized(), """
        ---
        markway.appleJournalID: "ABC"
        title: "A title: with colon"
        ---
        Body
        """)
    }
}
