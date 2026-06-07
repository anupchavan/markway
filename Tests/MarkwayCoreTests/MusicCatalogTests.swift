import Foundation
import XCTest
@testable import MarkwayCore

final class MusicCatalogTests: XCTestCase {
    func testReadsSongsAndAlbumRelationshipsFromServerObjectDatabase() throws {
        let fixture = try MusicCatalogFixture()
        let catalog = SQLiteMusicCatalog(databaseURL: fixture.databaseURL, analysisDatabaseURL: fixture.analysisDatabaseURL)

        let songs = try catalog.songs()

        XCTAssertEqual(songs.map(\.id), ["1129452297", "1642495805", "1212020454"])
        XCTAssertEqual(songs[0].title, "Ale")
        XCTAssertEqual(songs[0].artistName, "Pritam, Neeraj Shridhar & Antara Mitra")
        XCTAssertEqual(songs[0].albumID, "1129452209")
        XCTAssertEqual(songs[0].albumTitle, "Golmaal 3 (Original Motion Picture Soundtrack)")
        XCTAssertEqual(songs[0].duration, 210.5)
        XCTAssertEqual(songs[0].genres, ["Bollywood", "Music"])
        XCTAssertTrue(songs[0].hasLyrics)
    }

    func testEnrichesMissingSongDurationAndGenresFromMusicKitAnalysisCache() throws {
        let fixture = try MusicCatalogFixture()
        let catalog = SQLiteMusicCatalog(databaseURL: fixture.databaseURL, analysisDatabaseURL: fixture.analysisDatabaseURL)

        let song = try catalog.resolveSong("Sahiba")

        XCTAssertEqual(song.id, "1212020454")
        XCTAssertEqual(song.duration, 250.25)
        XCTAssertEqual(song.genres, ["Bollywood", "Music", "Indian"])
    }

    func testSearchMatchesTitleArtistAlbumAndID() throws {
        let fixture = try MusicCatalogFixture()
        let catalog = SQLiteMusicCatalog(databaseURL: fixture.databaseURL, analysisDatabaseURL: fixture.analysisDatabaseURL)

        XCTAssertEqual(try catalog.search("Antara").map(\.title), ["Ale"])
        XCTAssertEqual(try catalog.search("Soundtrack").map(\.title), ["Ale"])
        XCTAssertEqual(try catalog.search("121202").map(\.title), ["Sahiba"])
    }

    func testResolvePrefersExactTitleBeforeFuzzyTitleMatches() throws {
        let fixture = try MusicCatalogFixture()
        let catalog = SQLiteMusicCatalog(databaseURL: fixture.databaseURL, analysisDatabaseURL: fixture.analysisDatabaseURL)

        let song = try catalog.resolveSong("Ale")

        XCTAssertEqual(song.id, "1129452297")
        XCTAssertEqual(song.title, "Ale")
    }

    func testInfoReturnsDatabasePathsAndSongCount() throws {
        let fixture = try MusicCatalogFixture()
        let catalog = SQLiteMusicCatalog(databaseURL: fixture.databaseURL, analysisDatabaseURL: fixture.analysisDatabaseURL)

        let info = try catalog.info()

        XCTAssertEqual(info.databasePath, fixture.databaseURL.path)
        XCTAssertEqual(info.analysisDatabasePath, fixture.analysisDatabaseURL.path)
        XCTAssertEqual(info.songCount, 3)
    }

    func testEmptyServerObjectDatabaseReturnsEmptySongs() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let databaseURL = directory.appendingPathComponent("EmptyMusicDatabase.sqlite")
        try runSQLite(databaseURL: databaseURL, sql: """
        create table objects (identifier text not null, person_id text not null, source integer not null default 0, expiration_date integer not null default 0, type text not null, payload text, identifier_set text not null, explicit integer not null default 0, primary key (identifier, person_id));
        create table object_relationships (parent_identifier text not null, child_identifier text not null, person_id text not null, suborder integer not null default 0, child_key text not null, parent_version_hash text, primary key (parent_identifier, person_id, suborder, child_key));
        """)

        let catalog = SQLiteMusicCatalog(databaseURL: databaseURL)

        XCTAssertEqual(try catalog.songs(), [])
        XCTAssertEqual(try catalog.search("anything"), [])
    }
}

final class MusicCatalogFixture {
    let directory: URL
    let databaseURL: URL
    let analysisDatabaseURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databaseURL = directory.appendingPathComponent("MusicDatabase.sqlite")
        analysisDatabaseURL = directory.appendingPathComponent("MusicCatalogData.sqlite")
        try Self.createServerObjectDatabase(at: databaseURL)
        try Self.createAnalysisDatabase(at: analysisDatabaseURL)
    }

    private static func createServerObjectDatabase(at url: URL) throws {
        let albumPayload = """
        {"id":"1129452209","type":"albums","attributes":{"name":"Golmaal 3 (Original Motion Picture Soundtrack)","artistName":"Pritam"}}
        """
        let alePayload = """
        {"id":"1129452297","type":"songs","attributes":{"name":"Ale","artistName":"Pritam, Neeraj Shridhar & Antara Mitra","url":"https://music.apple.com/in/album/ale/1129452209?i=1129452297","artwork":{"url":"https://example.com/{w}x{h}.jpg"},"durationInMillis":210500,"genreNames":["Bollywood","Music"],"hasLyrics":true,"hasTimeSyncedLyrics":true,"inLibrary":false}}
        """
        let sahibaPayload = """
        {"id":"1212020454","type":"songs","attributes":{"name":"Sahiba","artistName":"Shashwat Sachdev, Pawni Pandey & Romy","url":"https://music.apple.com/in/album/sahiba/1212020450?i=1212020454","artwork":{"url":"https://example.com/sahiba/{w}x{h}.jpg"},"hasLyrics":true,"hasTimeSyncedLyrics":false,"inLibrary":true}}
        """
        let chaloPayload = """
        {"id":"1642495805","type":"songs","attributes":{"name":"Chalo Chalein (feat. Seedhe Maut)","artistName":"Ritviz","url":"https://music.apple.com/in/song/chalo-chalein/1642495805","artwork":{"url":"https://example.com/chalo/{w}x{h}.jpg"},"hasLyrics":false,"hasTimeSyncedLyrics":false,"inLibrary":false}}
        """
        let sql = """
        create table objects (identifier text not null, person_id text not null, source integer not null default 0, expiration_date integer not null default 0, type text not null, payload text, identifier_set text not null, explicit integer not null default 0, primary key (identifier, person_id));
        create table object_relationships (parent_identifier text not null, child_identifier text not null, person_id text not null, suborder integer not null default 0, child_key text not null, parent_version_hash text, primary key (parent_identifier, person_id, suborder, child_key));
        create table assets (identifier text not null, hashed_person_id text not null, flavor text not null, url text not null, url_expiration_date integer not null default 0, mini_sinf blob, sinfs blob, primary key (identifier, hashed_person_id, flavor));
        create table hls_assets (identifier text not null);
        insert into objects (identifier, person_id, type, payload, identifier_set) values ('1129452209', 'person', 'albums', \(sqlString(albumPayload)), '{}');
        insert into objects (identifier, person_id, type, payload, identifier_set) values ('1129452297', 'person', 'songs', \(sqlString(alePayload)), '{}');
        insert into objects (identifier, person_id, type, payload, identifier_set) values ('1642495805', 'person', 'songs', \(sqlString(chaloPayload)), '{}');
        insert into objects (identifier, person_id, type, payload, identifier_set) values ('1212020454', 'person', 'songs', \(sqlString(sahibaPayload)), '{}');
        insert into object_relationships (parent_identifier, child_identifier, person_id, suborder, child_key, parent_version_hash) values ('1129452297', '1129452209', 'person', 0, 'MPModelChildSongAlbum', '');
        """
        try runSQLite(databaseURL: url, sql: sql)
    }

    private static func createAnalysisDatabase(at url: URL) throws {
        let genres = """
        {"value":{"data":[{"attributes":{"name":"Bollywood"}},{"attributes":{"name":"Music"}},{"attributes":{"name":"Indian"}}]}}
        """
        let sql = """
        create table catalog_song (adam_id integer primary key not null, duration real, all_genres text);
        insert into catalog_song (adam_id, duration, all_genres) values (1212020454, 250.25, \(sqlString(genres)));
        """
        try runSQLite(databaseURL: url, sql: sql)
    }
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
