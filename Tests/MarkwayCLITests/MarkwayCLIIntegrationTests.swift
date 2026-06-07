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

    func testJournalEntriesPrintsSyncedMarkdownPathsOnly() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal:entries", "folder=Journal", "limit=1"], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "Journal/Flexoki.md")
    }

    func testJournalEntriesCanReturnCount() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal:entries", "folder=Journal", "count"], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "2")
    }

    func testJournalEntryShowsInfoForSyncedPath() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway([
            "journal:entry", "path=Journal/Flexoki.md",
            "--journal-tool", fake.scriptURL.path
        ], fake: fake)

        XCTAssertTrue(result.stdout.contains("path\tJournal/Flexoki.md"))
        XCTAssertTrue(result.stdout.contains("name\tFlexoki"))
        XCTAssertTrue(result.stdout.contains("extension\tmd"))
        XCTAssertTrue(result.stdout.contains("journalID\t11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(result.stdout.contains("journalCreated\t2026-06-01T00:00:00Z"))
        XCTAssertTrue(result.stdout.contains("attachments\t1"))
    }

    func testJournalEntrySaysNotJournalEntryForUnlinkedPath() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal:entry", "path=Notes/Recipe.md"], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "Not a Journal entry")
    }

    func testJournalReadReadsBodyForSyncedPath() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway([
            "journal:read", "path=Journal/Flexoki.md",
            "--journal-tool", fake.scriptURL.path
        ], fake: fake)

        XCTAssertFalse(result.stdout.contains("id: 11111111"))
        XCTAssertTrue(result.stdout.contains("A [link](https://google.com) and **bold**."))
    }

    func testJournalReadSaysNotJournalEntryForUnlinkedPath() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["journal:read", "path=Notes/Recipe.md"], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "Not a Journal entry")
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

    func testRootHelpGroupsJournalAndMusicCommands() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["--help"], fake: fake)

        XCTAssertTrue(result.stdout.contains("journal:entries"))
        XCTAssertTrue(result.stdout.contains("journal:push"))
        XCTAssertTrue(result.stdout.contains("music:songs"))
        XCTAssertTrue(result.stdout.contains("music:search"))
        XCTAssertTrue(result.stdout.contains("sync"))
        XCTAssertFalse(result.stdout.contains("  list "))
        XCTAssertFalse(result.stdout.contains("  push "))
    }

    func testJournalPushErrorUsesColonCommandName() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkwayAllowingFailure(["journal:push"], fake: fake)

        XCTAssertEqual(result.status, 64)
        XCTAssertTrue(result.stderr.contains("journal:push requires a markdown file"))
    }

    func testMusicPathPrintsDatabaseAndSongCount() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music", "path", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("database: \(fake.musicDatabaseURL.path)"))
        XCTAssertTrue(result.stdout.contains("songs: 2"))
    }

    func testMusicListPrintsCachedSongs() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music", "list", "limit=1", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("1129452297  Ale"))
        XCTAssertFalse(result.stdout.contains("Sahiba"))
    }

    func testMusicSearchMatchesTitleAndPrintsTSV() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway([
            "music", "search", "query=Sahiba", "format=tsv",
            "--music-database", fake.musicDatabaseURL.path
        ], fake: fake)

        XCTAssertEqual(
            result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            "1212020454\tSahiba\tShashwat Sachdev, Pawni Pandey & Romy\tSahiba - Single\thttps://music.apple.com/in/album/sahiba/1212020450?i=1212020454"
        )
    }

    func testMusicGetResolvesIDAndPrintsDetails() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music", "get", "112945", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("id: 1129452297"))
        XCTAssertTrue(result.stdout.contains("title: Ale"))
        XCTAssertTrue(result.stdout.contains("album: Golmaal 3 (Original Motion Picture Soundtrack)"))
        XCTAssertTrue(result.stdout.contains("duration: 210.500"))
    }

    func testMusicSongsDefaultsToLibrarySongs() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music:songs", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("1212020454  Sahiba"))
        XCTAssertFalse(result.stdout.contains("1129452297  Ale"))
    }

    func testMusicSongsSupportsArtistAlbumAndCountFilters() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway([
            "music:songs", "artist=Pawni", "album=Single", "count",
            "--music-database", fake.musicDatabaseURL.path
        ], fake: fake)

        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "1")
    }

    func testMusicSongShowsOneSongByTitle() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music:song", "song=Sahiba", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("id: 1212020454"))
        XCTAssertTrue(result.stdout.contains("title: Sahiba"))
        XCTAssertTrue(result.stdout.contains("album: Sahiba - Single"))
        XCTAssertTrue(result.stdout.contains("inLibrary: true"))
    }

    func testMusicSongUsesDiscoveredDatabaseFromEnvironment() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music:song", "song=Sahiba"], fake: fake)

        XCTAssertTrue(result.stdout.contains("id: 1212020454"))
        XCTAssertTrue(result.stdout.contains("title: Sahiba"))
        XCTAssertTrue(result.stdout.contains("album: Sahiba - Single"))
    }

    func testMusicAlbumsListsLibraryAlbums() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music:albums", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("1212020450  Sahiba - Single"))
        XCTAssertFalse(result.stdout.contains("1129452209  Golmaal 3"))
    }

    func testMusicAlbumShowsAlbumInfo() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music:album", "album=Sahiba", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("id: 1212020450"))
        XCTAssertTrue(result.stdout.contains("title: Sahiba - Single"))
        XCTAssertTrue(result.stdout.contains("songs: 1"))
        XCTAssertTrue(result.stdout.contains("1212020454  Sahiba"))
    }

    func testMusicSearchIncludesCachedSongsOutsideLibrary() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkway(["music:search", "query=Ale", "--music-database", fake.musicDatabaseURL.path], fake: fake)

        XCTAssertTrue(result.stdout.contains("1129452297  Ale"))
    }

    func testMusicPlaylistFilterFailsClearlyUntilDecoded() throws {
        let fake = try FakeJournalTool()
        let result = try runMarkwayAllowingFailure([
            "music:songs", "playlist=Favorites",
            "--music-database", fake.musicDatabaseURL.path
        ], fake: fake)

        XCTAssertEqual(result.status, 64)
        XCTAssertTrue(result.stderr.contains("music playlist filtering is not decoded"))
    }

    private func runMarkway(_ arguments: [String], fake: FakeJournalTool) throws -> ProcessResult {
        let result = try runMarkwayAllowingFailure(arguments, fake: fake)
        guard result.status == 0 else {
            XCTFail("markway exited \(result.status): \(result.stderr)")
            return result
        }
        return result
    }

    private func runMarkwayAllowingFailure(_ arguments: [String], fake: FakeJournalTool) throws -> ProcessResult {
        let process = Process()
        process.executableURL = try markwayExecutableURL()
        process.arguments = arguments
        process.currentDirectoryURL = fake.directory

        var environment = ProcessInfo.processInfo.environment
        environment["MARKWAY_FAKE_LOG"] = fake.logURL.path
        environment["MARKWAY_FAKE_BODY"] = fake.bodyURL.path
        environment["MARKWAY_MUSIC_DATABASE"] = fake.musicDatabaseURL.path
        environment["MARKWAY_MUSIC_ANALYSIS_DATABASE"] = fake.musicAnalysisDatabaseURL.path
        process.environment = environment

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ProcessResult(stdout: out, stderr: err, status: process.terminationStatus)
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
    let musicDatabaseURL: URL
    let musicAnalysisDatabaseURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        scriptURL = directory.appendingPathComponent("journal_text_fake.zsh")
        logURL = directory.appendingPathComponent("calls.log")
        bodyURL = directory.appendingPathComponent("body.md")
        musicDatabaseURL = directory.appendingPathComponent("MusicDatabase.sqlite")
        musicAnalysisDatabaseURL = directory.appendingPathComponent("MusicCatalogData.sqlite")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        try createMusicDatabase(at: musicDatabaseURL)
        try createMusicAnalysisDatabase(at: musicAnalysisDatabaseURL)
        try createVaultFiles()
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
          attachments)
            if [[ "${1:-}" == "list" ]]; then
              cat <<EOF
        {"attachments":[{"id":"ASSET-1","isFullyRemoved":false},{"id":"ASSET-2","isUndoablyDeleted":true}]}
        EOF
            else
              print -- "raw:$command $*"
            fi
            ;;
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

    private func createVaultFiles() throws {
        let journalURL = directory.appendingPathComponent("Journal", isDirectory: true)
        let notesURL = directory.appendingPathComponent("Notes", isDirectory: true)
        let pluginURL = directory
            .appendingPathComponent(".obsidian", isDirectory: true)
            .appendingPathComponent("plugins", isDirectory: true)
            .appendingPathComponent("obsidian-markway", isDirectory: true)
        try FileManager.default.createDirectory(at: journalURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: notesURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: pluginURL, withIntermediateDirectories: true)

        try "Local Flexoki body\n".write(to: journalURL.appendingPathComponent("Flexoki.md"), atomically: true, encoding: .utf8)
        try "Local Other body\n".write(to: journalURL.appendingPathComponent("Other.md"), atomically: true, encoding: .utf8)
        try "Recipe\n".write(to: notesURL.appendingPathComponent("Recipe.md"), atomically: true, encoding: .utf8)
        try Data([0xFF, 0xFE, 0x00]).write(to: journalURL.appendingPathComponent("Broken.md"))

        let data = """
        {
          "settings": {},
          "journalLinks": {
            "11111111-1111-1111-1111-111111111111": {
              "path": "Journal/Flexoki.md",
              "title": "Flexoki"
            },
            "22222222-2222-2222-2222-222222222222": {
              "path": "Journal/Other.md",
              "title": "Other"
            }
          }
        }
        """
        try data.write(to: pluginURL.appendingPathComponent("data.json"), atomically: true, encoding: .utf8)
    }
}

private func createMusicDatabase(at url: URL) throws {
    let albumPayload = """
    {"id":"1129452209","type":"albums","attributes":{"name":"Golmaal 3 (Original Motion Picture Soundtrack)","artistName":"Pritam"}}
    """
    let sahibaAlbumPayload = """
    {"id":"1212020450","type":"albums","attributes":{"name":"Sahiba - Single","artistName":"Shashwat Sachdev, Pawni Pandey & Romy"}}
    """
    let alePayload = """
    {"id":"1129452297","type":"songs","attributes":{"name":"Ale","artistName":"Pritam, Neeraj Shridhar & Antara Mitra","url":"https://music.apple.com/in/album/ale/1129452209?i=1129452297","artwork":{"url":"https://example.com/{w}x{h}.jpg"},"durationInMillis":210500,"genreNames":["Bollywood","Music"],"hasLyrics":true,"hasTimeSyncedLyrics":true,"inLibrary":false}}
    """
    let sahibaPayload = """
    {"id":"1212020454","type":"songs","attributes":{"name":"Sahiba","artistName":"Shashwat Sachdev, Pawni Pandey & Romy","url":"https://music.apple.com/in/album/sahiba/1212020450?i=1212020454","artwork":{"url":"https://example.com/sahiba/{w}x{h}.jpg"},"hasLyrics":true,"hasTimeSyncedLyrics":false,"inLibrary":true}}
    """
    let sql = """
    create table objects (identifier text not null, person_id text not null, source integer not null default 0, expiration_date integer not null default 0, type text not null, payload text, identifier_set text not null, explicit integer not null default 0, primary key (identifier, person_id));
    create table object_relationships (parent_identifier text not null, child_identifier text not null, person_id text not null, suborder integer not null default 0, child_key text not null, parent_version_hash text, primary key (parent_identifier, person_id, suborder, child_key));
    create table assets (identifier text not null, hashed_person_id text not null, flavor text not null, url text not null, url_expiration_date integer not null default 0, mini_sinf blob, sinfs blob, primary key (identifier, hashed_person_id, flavor));
    create table hls_assets (identifier text not null);
    insert into objects (identifier, person_id, type, payload, identifier_set) values ('1129452209', 'person', 'albums', \(sqlString(albumPayload)), '{}');
    insert into objects (identifier, person_id, type, payload, identifier_set) values ('1212020450', 'person', 'albums', \(sqlString(sahibaAlbumPayload)), '{}');
    insert into objects (identifier, person_id, type, payload, identifier_set) values ('1129452297', 'person', 'songs', \(sqlString(alePayload)), '{}');
    insert into objects (identifier, person_id, type, payload, identifier_set) values ('1212020454', 'person', 'songs', \(sqlString(sahibaPayload)), '{}');
    insert into object_relationships (parent_identifier, child_identifier, person_id, suborder, child_key, parent_version_hash) values ('1129452297', '1129452209', 'person', 0, 'MPModelChildSongAlbum', '');
    insert into object_relationships (parent_identifier, child_identifier, person_id, suborder, child_key, parent_version_hash) values ('1212020454', '1212020450', 'person', 0, 'MPModelChildSongAlbum', '');
    """
    try runSQLite(databaseURL: url, sql: sql)
}

private func createMusicAnalysisDatabase(at url: URL) throws {
    let genres = """
    {"value":{"data":[{"attributes":{"name":"Bollywood"}},{"attributes":{"name":"Music"}},{"attributes":{"name":"Indian"}}]}}
    """
    let sql = """
    create table catalog_song (adam_id integer primary key not null, duration real, all_genres text);
    insert into catalog_song (adam_id, duration, all_genres) values (1212020454, 250.25, \(sqlString(genres)));
    """
    try runSQLite(databaseURL: url, sql: sql)
}

private func runSQLite(databaseURL: URL, sql: String) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
    process.arguments = [databaseURL.path]

    let stdin = Pipe()
    let stderr = Pipe()
    process.standardInput = stdin
    process.standardError = stderr

    try process.run()
    stdin.fileHandleForWriting.write(Data(sql.utf8))
    try stdin.fileHandleForWriting.close()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        let message = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTFail("sqlite3 failed: \(message)")
    }
}

private func sqlString(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "''"))'"
}

private struct ProcessResult {
    var stdout: String
    var stderr: String
    var status: Int32
}
