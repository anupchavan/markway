import Foundation
import XCTest
@testable import MarkwayCore

final class MarkwayCLIIntegrationTests: XCTestCase {
    func testDoctorUsesExplicitJournalTool() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["doctor", "--journal-tool", fake.scriptURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("journal tool: \(fake.scriptURL.path)"))
        XCTAssertTrue(result.stdout.contains("completion: markway --generate-completion-script zsh"))
    }

    func testJournalListPrintsShortIDsDatesStatusAndTitles() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal", "list", "--journal-tool", fake.scriptURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("11111111  2026-06-01T00:00:00Z  active  Flexoki"))
        XCTAssertTrue(result.stdout.contains("22222222  2026-06-02T00:00:00Z  active  Other"))
    }

    func testJournalListFiltersByTitleQuery() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal", "list", "query=Flex", "--journal-tool", fake.scriptURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("Flexoki"))
        XCTAssertFalse(result.stdout.contains("Other"))
    }

    func testJournalGetResolvesTitleSelectorAndPrintsMarkdownBody() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal", "get", "Flexoki", "--journal-tool", fake.scriptURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("id: 11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(result.stdout.contains("[link](https://google.com)"))
        XCTAssertTrue(result.stdout.contains("**bold**"))
        XCTAssertTrue(result.stdout.contains("- item"))
        XCTAssertTrue(result.stdout.contains("> quote"))
    }

    func testJournalGetAcceptsKeyValueSelector() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal", "get", "id=Other", "--journal-tool", fake.scriptURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("id: 22222222-2222-2222-2222-222222222222"))
        XCTAssertTrue(result.stdout.contains("title: Other"))
    }

    func testJournalPullWritesMarkdownDocument() throws {
        let fake = try FakeJournalTool()
        let out = fake.directory.appendingPathComponent("Pulled.md")

        _ = try runMarkway(["journal", "pull", "Flexoki", "--out", out.path, "--journal-tool", fake.scriptURL.path], fake: fake)

        let document = try MarkdownDocument.read(from: out)
        XCTAssertEqual(document[MarkwayMetadataKey.appleJournalID], "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(document[MarkwayMetadataKey.title], "Flexoki")
        XCTAssertTrue(document.body.contains("[link](https://google.com)"))
        XCTAssertTrue(document.body.contains("**bold**"))
    }

    func testJournalPushSendsMarkdownBodyWithoutFrontmatter() throws {
        let fake = try FakeJournalTool()
        let file = fake.directory.appendingPathComponent("Entry.md")
        try """
        ---
        title: "Entry"
        ---
        A [link](https://google.com) with **bold**.

        - item
        """.write(to: file, atomically: true, encoding: .utf8)

        let result = try runMarkway([
            "journal", "push", file.path,
            "--title", "Entry",
            "--journal-tool", fake.scriptURL.path,
            "--no-write-frontmatter"
        ], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(try String(contentsOf: fake.bodyURL), """
        A [link](https://google.com) with **bold**.

        - item
        """)
    }

    func testJournalPushUpdatesExistingEntryFromFrontmatter() throws {
        let fake = try FakeJournalTool()
        let file = fake.directory.appendingPathComponent("Existing.md")
        try """
        ---
        markway.appleJournalID: "11111111-1111-1111-1111-111111111111"
        title: "Existing"
        ---
        Updated **body**
        """.write(to: file, atomically: true, encoding: .utf8)

        let result = try runMarkway([
            "journal", "push", "file=\(file.path)",
            "--journal-tool", fake.scriptURL.path,
            "--no-write-frontmatter"
        ], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "11111111-1111-1111-1111-111111111111")
        XCTAssertTrue(try String(contentsOf: fake.logURL).contains("update 11111111-1111-1111-1111-111111111111"))
        XCTAssertEqual(try String(contentsOf: fake.bodyURL), "Updated **body**")
    }

    func testJournalRawPassesArgumentsToJournalTool() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal", "raw", "--journal-tool", fake.scriptURL.path, "attachments", "types"], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "raw:attachments types")
    }

    private func runMarkway(_ arguments: [String], fake: FakeJournalTool) throws -> ProcessResult {
        let process = Process()
        process.executableURL = try markwayExecutableURL()
        process.arguments = arguments
        process.currentDirectoryURL = fake.directory

        var environment = ProcessInfo.processInfo.environment
        environment["MARKWAY_FAKE_LOG"] = fake.logURL.path
        environment["MARKWAY_FAKE_BODY"] = fake.bodyURL.path
        process.environment = environment

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            XCTFail("markway exited \(process.terminationStatus): \(err)")
            return ProcessResult(stdout: out, stderr: err)
        }
        return ProcessResult(stdout: out, stderr: err)
    }

    private func markwayExecutableURL() throws -> URL {
        let direct = productsDirectory().appendingPathComponent("markway")
        if FileManager.default.isExecutableFile(atPath: direct.path) {
            return direct
        }

        let fallback = repositoryRoot().appendingPathComponent(".build/debug/markway")
        if FileManager.default.isExecutableFile(atPath: fallback.path) {
            return fallback
        }

        throw XCTSkip("markway executable was not built")
    }

    private func productsDirectory() -> URL {
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
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
}

private final class FakeJournalTool {
    let directory: URL
    let scriptURL: URL
    let logURL: URL
    let bodyURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        scriptURL = directory.appendingPathComponent("journal_text_fake.zsh")
        logURL = directory.appendingPathComponent("calls.log")
        bodyURL = directory.appendingPathComponent("body.md")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
    }

    private var script: String {
        """
        #!/bin/zsh
        set -euo pipefail

        log="${MARKWAY_FAKE_LOG:-/tmp/markway-fake.log}"
        body_out="${MARKWAY_FAKE_BODY:-/tmp/markway-fake-body.md}"
        print -- "$*" >> "$log"

        command="${1:-}"
        if [[ "$#" -gt 0 ]]; then
          shift
        fi

        copy_body_arg() {
          local body=""
          while [[ "$#" -gt 0 ]]; do
            case "$1" in
              --body)
                body="$2"
                shift 2
                ;;
              *)
                shift
                ;;
            esac
          done
          if [[ -n "$body" ]]; then
            cp "$body" "$body_out"
          fi
        }

        case "$command" in
          list)
            print -- $'11111111-1111-1111-1111-111111111111\\tactive\\t2026-06-01T00:00:00Z\\t2026-06-01T00:00:01Z\\tFlexoki'
            print -- $'22222222-2222-2222-2222-222222222222\\tactive\\t2026-06-02T00:00:00Z\\t2026-06-02T00:00:01Z\\tOther'
            ;;
          get)
            id="${1:-11111111-1111-1111-1111-111111111111}"
            title="Flexoki"
            if [[ "$id" == "22222222-2222-2222-2222-222222222222" ]]; then
              title="Other"
            fi
            cat <<EOF
        id: $id
        title: $title
        created: 2026-06-01T00:00:00Z
        updated: 2026-06-01T00:00:01Z
        ---
        # Heading

        A [link](https://google.com) and **bold**.

        - item

        > quote
        EOF
            ;;
          add)
            copy_body_arg "$@"
            print -- "33333333-3333-3333-3333-333333333333"
            ;;
          update)
            id="$1"
            shift
            copy_body_arg "$@"
            print -- "$id"
            ;;
          sync-status)
            print -- "status: ok"
            ;;
          *)
            print -- "raw:$command $*"
            ;;
        esac
        """
    }
}

private struct ProcessResult {
    var stdout: String
    var stderr: String
}
