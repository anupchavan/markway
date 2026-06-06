import Foundation
import XCTest

final class JournalMarkdownRoundTripTests: XCTestCase {
    func testRoundTripsBoldItalicBoldItalicAndInlineCode() throws {
        try assertJournalMarkdownRoundTrip(
            "bold **text** and *italic* and ***both*** plus `code`"
        )
    }

    func testRoundTripsMarkdownLinkWithDisplayText() throws {
        try assertJournalMarkdownRoundTrip(
            "[link](https://google.com)"
        )
    }

    func testRoundTripsMarkdownLinkInsideParagraph() throws {
        try assertJournalMarkdownRoundTrip(
            "Open [Flexoki](https://github.com/kepano/flexoki) today."
        )
    }

    func testKeepsRelativeMarkdownLinksLiteral() throws {
        try assertJournalMarkdownRoundTrip(
            "[local note](notes/local file.md)"
        )
    }

    func testRoundTripsUnorderedLists() throws {
        try assertJournalMarkdownRoundTrip("""
        - list item
        - list item another
        """)
    }

    func testRoundTripsOrderedLists() throws {
        try assertJournalMarkdownRoundTrip("""
        1. first
        1. second
        """)
    }

    func testRoundTripsTaskListsAsMarkdownText() throws {
        try assertJournalMarkdownRoundTrip("""
        - [ ] todo
        - [x] done
        """)
    }

    func testRoundTripsBlockQuotes() throws {
        try assertJournalMarkdownRoundTrip(
            "> quote **bold** and *italic*"
        )
    }

    func testRoundTripsFencedCodeBlocks() throws {
        try assertJournalMarkdownRoundTrip("""
        ```
        const ok = 1
        ```
        """)
    }

    func testRoundTripsHeadings() throws {
        try assertJournalMarkdownRoundTrip("""
        # One

        ## Two

        ### Three

        #### Four
        """)
    }

    func testPreservesUnsupportedMarkdownAsLiteralText() throws {
        try assertJournalMarkdownRoundTrip(
            "~~strike~~ ==highlight== [[Wikilink]] ![[Embed]]"
        )
    }

    func testPreservesMarkdownTablesAsLiteralText() throws {
        try assertJournalMarkdownRoundTrip("""
        | A | B |
        | --- | --- |
        | 1 | 2 |
        """)
    }

    func testPreservesFootnotesAsLiteralText() throws {
        try assertJournalMarkdownRoundTrip("""
        A sentence with a footnote.[^1]

        [^1]: Footnote text.
        """)
    }

    func testRoundTripsMixedMarkdownSample() throws {
        try assertJournalMarkdownRoundTrip("""
        # Flexoki

        Flexoki is **bold**, *italic*, and has [source](https://github.com/kepano/flexoki).

        - list item
        - `code` item

        > Keep the quote.

        ```
        const ok = 1
        ```

        [[Obsidian link]] and ==unsupported highlight== stay literal.
        """)
    }

    private func assertJournalMarkdownRoundTrip(
        _ markdown: String,
        equals expected: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let temp = try temporaryDirectory()
        let bodyURL = temp.appendingPathComponent("body.md")
        try markdown.write(to: bodyURL, atomically: true, encoding: .utf8)

        let result = try runJournalText(["debug-markdown", "--body", bodyURL.path])
        XCTAssertEqual(result.stdout, expected ?? markdown, file: file, line: line)
    }

    private func runJournalText(_ arguments: [String]) throws -> ProcessResult {
        let process = Process()
        process.executableURL = helperScriptURL()
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            XCTFail("journal_text exited \(process.terminationStatus): \(err)")
            return ProcessResult(stdout: out, stderr: err)
        }
        return ProcessResult(stdout: out, stderr: err)
    }

    private func helperScriptURL() -> URL {
        repositoryRoot()
            .appendingPathComponent("Vendor/AppleJournalCRDT/tools/journal_text.zsh")
    }

    private func repositoryRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        if url.pathExtension == "swift" {
            url.deleteLastPathComponent()
        }
        while url.path != "/" {
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
                return url
            }
            url.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private struct ProcessResult {
    var stdout: String
    var stderr: String
}
