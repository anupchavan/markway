import Foundation

public enum MusicCatalogError: Error, CustomStringConvertible, Sendable {
    case notFound
    case sqliteFailed(status: Int32, stdout: String, stderr: String)
    case automationFailed(status: Int32, stdout: String, stderr: String)
    case invalidOutput(String)
    case selectorNotFound(String)
    case ambiguousSelector(String, [MusicSong])

    public var description: String {
        switch self {
        case .notFound:
            return "Apple Music catalog database was not found. Set MARKWAY_MUSIC_DATABASE or pass --music-database."
        case .sqliteFailed(let status, let stdout, let stderr):
            let details = stderr.isEmpty ? stdout : stderr
            return "sqlite3 failed with status \(status): \(details)"
        case .automationFailed(let status, let stdout, let stderr):
            let details = stderr.isEmpty ? stdout : stderr
            return "Music.app automation failed with status \(status): \(details)"
        case .invalidOutput(let output):
            return "Apple Music catalog output could not be parsed: \(output)"
        case .selectorNotFound(let selector):
            return "no Apple Music song matched '\(selector)'"
        case .ambiguousSelector(let selector, let matches):
            let list = matches.prefix(8).map { "\($0.id)  \($0.title)" }.joined(separator: "\n")
            return "song selector '\(selector)' is ambiguous:\n\(list)"
        }
    }
}

public struct MusicSong: Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var artistName: String
    public var albumID: String
    public var albumTitle: String
    public var albumArtist: String?
    public var url: String
    public var artworkURLTemplate: String
    public var duration: Double?
    public var genres: [String]
    public var hasLyrics: Bool
    public var hasTimeSyncedLyrics: Bool
    public var inLibrary: Bool
    public var persistentID: String?
    public var databaseID: Int?
    public var cloudStatus: String?
    public var kind: String?
    public var dateAdded: String?
    public var releaseDate: String?
    public var playedDate: String?
    public var playedCount: Int?
    public var skippedCount: Int?
    public var favorited: Bool?
    public var disliked: Bool?

    public init(
        id: String,
        title: String,
        artistName: String = "",
        albumID: String = "",
        albumTitle: String = "",
        albumArtist: String? = nil,
        url: String = "",
        artworkURLTemplate: String = "",
        duration: Double? = nil,
        genres: [String] = [],
        hasLyrics: Bool = false,
        hasTimeSyncedLyrics: Bool = false,
        inLibrary: Bool = false,
        persistentID: String? = nil,
        databaseID: Int? = nil,
        cloudStatus: String? = nil,
        kind: String? = nil,
        dateAdded: String? = nil,
        releaseDate: String? = nil,
        playedDate: String? = nil,
        playedCount: Int? = nil,
        skippedCount: Int? = nil,
        favorited: Bool? = nil,
        disliked: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumID = albumID
        self.albumTitle = albumTitle
        self.albumArtist = albumArtist
        self.url = url
        self.artworkURLTemplate = artworkURLTemplate
        self.duration = duration
        self.genres = genres
        self.hasLyrics = hasLyrics
        self.hasTimeSyncedLyrics = hasTimeSyncedLyrics
        self.inLibrary = inLibrary
        self.persistentID = persistentID
        self.databaseID = databaseID
        self.cloudStatus = cloudStatus
        self.kind = kind
        self.dateAdded = dateAdded
        self.releaseDate = releaseDate
        self.playedDate = playedDate
        self.playedCount = playedCount
        self.skippedCount = skippedCount
        self.favorited = favorited
        self.disliked = disliked
    }
}

public struct AppleMusicLibrary: Sendable {
    public init() {}

    public func resolveSong(
        selector: String,
        artist: String? = nil,
        album: String? = nil,
        playlist: String? = nil
    ) throws -> MusicSong {
        let songs = try matchingSongs(
            selector: selector,
            artist: artist,
            album: album,
            playlist: playlist
        )
        guard let first = songs.first else {
            throw MusicCatalogError.selectorNotFound(selector)
        }
        guard songs.count == 1 else {
            throw MusicCatalogError.ambiguousSelector(selector, songs)
        }
        return first
    }

    public func matchingSongs(
        selector: String,
        artist: String? = nil,
        album: String? = nil,
        playlist: String? = nil
    ) throws -> [MusicSong] {
        let output = try runJavaScript(script: Self.matchingSongsScript(
            selector: selector,
            artist: artist,
            album: album,
            playlist: playlist
        ))
        do {
            let rows = try JSONDecoder().decode([AppleMusicLibrarySongRow].self, from: Data(output.utf8))
            return rows.map(\.song)
        } catch {
            throw MusicCatalogError.invalidOutput(output)
        }
    }

    public func songs(playlist: String? = nil) throws -> [MusicSong] {
        let output = try runJavaScript(script: Self.songsScript(playlist: playlist))
        do {
            let rows = try JSONDecoder().decode([AppleMusicLibrarySongRow].self, from: Data(output.utf8))
            return rows.map(\.song)
        } catch {
            throw MusicCatalogError.invalidOutput(output)
        }
    }

    private func runJavaScript(script: String) throws -> String {
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputURL = tempDirectory.appendingPathComponent("markway-music-\(UUID().uuidString).json")
        let errorURL = tempDirectory.appendingPathComponent("markway-music-\(UUID().uuidString).err")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        FileManager.default.createFile(atPath: errorURL.path, contents: nil)
        defer {
            try? FileManager.default.removeItem(at: outputURL)
            try? FileManager.default.removeItem(at: errorURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-l", "JavaScript"]

        let stdin = Pipe()
        let stdout = try FileHandle(forWritingTo: outputURL)
        let stderr = try FileHandle(forWritingTo: errorURL)
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        stdin.fileHandleForWriting.write(Data(script.utf8))
        try stdin.fileHandleForWriting.close()
        process.waitUntilExit()
        try stdout.close()
        try stderr.close()

        let stdoutText = (try? String(contentsOf: outputURL, encoding: .utf8)) ?? ""
        let stderrText = (try? String(contentsOf: errorURL, encoding: .utf8)) ?? ""
        guard process.terminationStatus == 0 else {
            throw MusicCatalogError.automationFailed(
                status: process.terminationStatus,
                stdout: stdoutText,
                stderr: stderrText
            )
        }
        return stdoutText
    }

    private static func matchingSongsScript(
        selector: String,
        artist: String?,
        album: String?,
        playlist: String?
    ) -> String {
        let selectorLiteral = jsStringLiteral(selector.trimmingCharacters(in: .whitespacesAndNewlines))
        let artistLiteral = jsStringLiteral(artist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        let albumLiteral = jsStringLiteral(album?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        let playlistLiteral = jsStringLiteral(playlist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        return """
        function iso(value) {
          if (!value) return "";
          try {
            return new Date(value).toISOString();
          } catch (_) {
            return "";
          }
        }
        function str(value) {
          return value === undefined || value === null ? "" : String(value);
        }
        function num(value) {
          const n = Number(value || 0);
          return Number.isFinite(n) ? n : 0;
        }
        function includes(value, needle) {
          return needle.length === 0 || str(value).toLocaleLowerCase().includes(needle);
        }
        function row(track) {
          const p = track.properties();
          return {
            id: str(p.persistentID || p.databaseID || p.id),
            persistentID: str(p.persistentID),
            databaseID: num(p.databaseID),
            title: str(p.name),
            artistName: str(p.artist),
            albumTitle: str(p.album),
            albumArtist: str(p.albumArtist),
            duration: num(p.duration),
            genre: str(p.genre),
            trackNumber: num(p.trackNumber),
            trackCount: num(p.trackCount),
            discNumber: num(p.discNumber),
            discCount: num(p.discCount),
            year: num(p.year),
            cloudStatus: str(p.cloudStatus),
            kind: str(p.kind),
            favorited: !!p.favorited,
            disliked: !!p.disliked,
            playedCount: num(p.playedCount),
            skippedCount: num(p.skippedCount),
            dateAdded: iso(p.dateAdded),
            releaseDate: iso(p.releaseDate),
            playedDate: iso(p.playedDate),
            size: num(p.size)
          };
        }
        const selector = \(selectorLiteral);
        const selectorNeedle = selector.toLocaleLowerCase();
        const artistNeedle = \(artistLiteral).toLocaleLowerCase();
        const albumNeedle = \(albumLiteral).toLocaleLowerCase();
        const playlistName = \(playlistLiteral);
        const Music = Application("Music");
        let trackSpecifier;
        if (playlistName.length > 0) {
          const playlistNeedle = playlistName.toLocaleLowerCase();
          const matches = Music.playlists().filter(p => str(p.properties().name).toLocaleLowerCase() === playlistNeedle);
          if (matches.length === 0) {
            throw new Error("playlist not found: " + playlistName);
          }
          if (matches.length > 1) {
            throw new Error("playlist is ambiguous: " + playlistName);
          }
          trackSpecifier = matches[0].tracks;
        } else {
          trackSpecifier = Music.libraryPlaylists[0].tracks;
        }

        const exact = [];
        if (selector.length > 0) {
          exact.push(...trackSpecifier.whose({persistentID: selector})());
          if (/^\\d+$/.test(selector)) {
            exact.push(...trackSpecifier.whose({databaseID: Number(selector)})());
          }
          exact.push(...trackSpecifier.whose({name: selector})());
        }

        const seen = new Set();
        const exactUnique = exact.filter(track => {
          const p = track.properties();
          const key = str(p.persistentID || p.databaseID || p.id);
          if (seen.has(key)) return false;
          seen.add(key);
          return true;
        });
        const exactOnly = exactUnique.length > 0;
        const candidates = exactOnly ? exactUnique : trackSpecifier();

        const rows = [];
        for (const track of candidates) {
          const p = track.properties();
          if (str(p.mediaKind) !== "song") continue;
          const id = str(p.persistentID || p.databaseID || p.id).toLocaleLowerCase();
          const title = str(p.name).toLocaleLowerCase();
          if (!exactOnly && selectorNeedle.length > 0 && !id.startsWith(selectorNeedle) && !title.includes(selectorNeedle)) continue;
          if (!includes(p.artist, artistNeedle)) continue;
          if (!includes(p.album, albumNeedle)) continue;
          rows.push(row(track));
        }
        JSON.stringify(rows);
        """
    }

    private static func songsScript(playlist: String?) -> String {
        let playlistLiteral = jsStringLiteral(playlist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        return """
        function iso(value) {
          if (!value) return "";
          try {
            return new Date(value).toISOString();
          } catch (_) {
            return "";
          }
        }
        function str(value) {
          return value === undefined || value === null ? "" : String(value);
        }
        function num(value) {
          const n = Number(value || 0);
          return Number.isFinite(n) ? n : 0;
        }
        const playlistName = \(playlistLiteral);
        const Music = Application("Music");
        let sourceTracks;
        if (playlistName.length > 0) {
          const needle = playlistName.toLocaleLowerCase();
          const matches = Music.playlists().filter(p => str(p.properties().name).toLocaleLowerCase() === needle);
          if (matches.length === 0) {
            throw new Error("playlist not found: " + playlistName);
          }
          if (matches.length > 1) {
            throw new Error("playlist is ambiguous: " + playlistName);
          }
          sourceTracks = matches[0].tracks();
        } else {
          sourceTracks = Music.libraryPlaylists[0].tracks();
        }
        const rows = [];
        for (const track of sourceTracks) {
          const p = track.properties();
          if (str(p.mediaKind) !== "song") continue;
          rows.push({
            id: str(p.persistentID || p.databaseID || p.id),
            persistentID: str(p.persistentID),
            databaseID: num(p.databaseID),
            title: str(p.name),
            artistName: str(p.artist),
            albumTitle: str(p.album),
            albumArtist: str(p.albumArtist),
            duration: num(p.duration),
            genre: str(p.genre),
            trackNumber: num(p.trackNumber),
            trackCount: num(p.trackCount),
            discNumber: num(p.discNumber),
            discCount: num(p.discCount),
            year: num(p.year),
            cloudStatus: str(p.cloudStatus),
            kind: str(p.kind),
            favorited: !!p.favorited,
            disliked: !!p.disliked,
            playedCount: num(p.playedCount),
            skippedCount: num(p.skippedCount),
            dateAdded: iso(p.dateAdded),
            releaseDate: iso(p.releaseDate),
            playedDate: iso(p.playedDate),
            size: num(p.size)
          });
        }
        JSON.stringify(rows);
        """
    }
}

public struct MusicCatalogInfo: Codable, Equatable, Sendable {
    public var databasePath: String
    public var analysisDatabasePath: String?
    public var songCount: Int

    public init(databasePath: String, analysisDatabasePath: String? = nil, songCount: Int = 0) {
        self.databasePath = databasePath
        self.analysisDatabasePath = analysisDatabasePath
        self.songCount = songCount
    }
}

public struct SQLiteMusicCatalog: Sendable {
    public let databaseURL: URL
    public let analysisDatabaseURL: URL?

    public init(databaseURL: URL, analysisDatabaseURL: URL? = nil) {
        self.databaseURL = databaseURL
        self.analysisDatabaseURL = analysisDatabaseURL
    }

    public static func discover(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> SQLiteMusicCatalog? {
        let environment = ProcessInfo.processInfo.environment
        if let explicit = environment["MARKWAY_MUSIC_DATABASE"], !explicit.isEmpty {
            return SQLiteMusicCatalog(
                databaseURL: URL(fileURLWithPath: explicit),
                analysisDatabaseURL: explicitAnalysisDatabase(from: environment)
            )
        }

        let databaseURL = homeDirectory
            .appendingPathComponent("Library/Application Support/com.apple.MediaPlayer/ServerObjectDatabases/com.apple.Music-ServerObjectDatabase.sqlpkg/Database")
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            return nil
        }

        let analysisURL = homeDirectory
            .appendingPathComponent("Music/Music/Music Library.musiclibrary/com.apple.MusicKit/downloaded_catalog_data/MusicCatalogData.db")
        return SQLiteMusicCatalog(
            databaseURL: databaseURL,
            analysisDatabaseURL: FileManager.default.fileExists(atPath: analysisURL.path) ? analysisURL : nil
        )
    }

    public func info() throws -> MusicCatalogInfo {
        let rows = try decodeSQLiteJSON([CountRow].self, sql: "select count(*) as count from objects where type='songs';")
        return MusicCatalogInfo(
            databasePath: databaseURL.path,
            analysisDatabasePath: analysisDatabaseURL?.path,
            songCount: rows.first?.count ?? 0
        )
    }

    public func songs() throws -> [MusicSong] {
        let rows = try decodeSQLiteJSON([MusicSongRow].self, sql: Self.songSQL)
        let analysis = try analysisBySongID()
        return rows.map { row in
            let enrichment = analysis[row.id]
            let genres = row.genres.isEmpty ? enrichment?.genres ?? [] : row.genres
            return MusicSong(
                id: row.id,
                title: row.title,
                artistName: row.artistName,
                albumID: row.albumID,
                albumTitle: row.albumTitle,
                url: row.url,
                artworkURLTemplate: row.artworkURLTemplate,
                duration: row.duration ?? enrichment?.duration,
                genres: genres,
                hasLyrics: row.hasLyrics,
                hasTimeSyncedLyrics: row.hasTimeSyncedLyrics,
                inLibrary: row.inLibrary
            )
        }
    }

    public func search(_ query: String, limit: Int? = nil) throws -> [MusicSong] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matches = try songs().filter { song in
            needle.isEmpty
            || song.id.lowercased().hasPrefix(needle)
            || song.title.lowercased().contains(needle)
            || song.artistName.lowercased().contains(needle)
            || song.albumTitle.lowercased().contains(needle)
        }
        guard let limit else {
            return matches
        }
        return Array(matches.prefix(max(0, limit)))
    }

    public func resolveSong(_ selector: String) throws -> MusicSong {
        let needle = selector.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let songs = try songs()
        let exactMatches = songs.filter { song in
            song.id.lowercased() == needle || song.title.lowercased() == needle
        }
        if let resolved = resolveUniqueMatch(exactMatches) {
            return resolved
        }
        if exactMatches.count > 1 {
            throw MusicCatalogError.ambiguousSelector(selector, exactMatches)
        }

        let prefixMatches = songs.filter { song in
            song.id.lowercased().hasPrefix(needle)
        }
        if let resolved = resolveUniqueMatch(prefixMatches) {
            return resolved
        }
        if prefixMatches.count > 1 {
            throw MusicCatalogError.ambiguousSelector(selector, prefixMatches)
        }

        let containsMatches = songs.filter { song in
            song.title.lowercased().contains(needle)
        }
        guard let first = containsMatches.first else {
            throw MusicCatalogError.selectorNotFound(selector)
        }
        guard containsMatches.count == 1 else {
            throw MusicCatalogError.ambiguousSelector(selector, containsMatches)
        }
        return first
    }

    private func analysisBySongID() throws -> [String: MusicAnalysisRow] {
        guard let analysisDatabaseURL else {
            return [:]
        }

        let sql = """
        select
          cast(adam_id as text) as id,
          duration,
          all_genres as all_genres_json
        from catalog_song;
        """
        let rows = try decodeSQLiteJSON([MusicAnalysisSQLiteRow].self, databaseURL: analysisDatabaseURL, sql: sql)
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.analysis) })
    }

    private func decodeSQLiteJSON<T: Decodable>(_ type: T.Type, sql: String) throws -> T {
        try decodeSQLiteJSON(type, databaseURL: databaseURL, sql: sql)
    }

    private func decodeSQLiteJSON<T: Decodable>(_ type: T.Type, databaseURL: URL, sql: String) throws -> T {
        let output = try runSQLite(databaseURL: databaseURL, sql: sql)
        let json = output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "[]" : output
        do {
            return try JSONDecoder().decode(T.self, from: Data(json.utf8))
        } catch {
            throw MusicCatalogError.invalidOutput(output)
        }
    }

    private func runSQLite(databaseURL: URL, sql: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = ["-readonly", "-json", databaseURL.path, sql]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let stdoutText = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderrText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw MusicCatalogError.sqliteFailed(status: process.terminationStatus, stdout: stdoutText, stderr: stderrText)
        }
        return stdoutText
    }

    private static func explicitAnalysisDatabase(from environment: [String: String]) -> URL? {
        guard let path = environment["MARKWAY_MUSIC_ANALYSIS_DATABASE"], !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    private static let songSQL = """
    select
      o.identifier as id,
      coalesce(json_extract(o.payload, '$.attributes.name'), '') as title,
      coalesce(json_extract(o.payload, '$.attributes.artistName'), '') as artist_name,
      coalesce(a.identifier, '') as album_id,
      coalesce(json_extract(a.payload, '$.attributes.name'), '') as album_title,
      coalesce(json_extract(o.payload, '$.attributes.url'), '') as url,
      coalesce(json_extract(o.payload, '$.attributes.artwork.url'), '') as artwork_url_template,
      json_extract(o.payload, '$.attributes.durationInMillis') as duration_ms,
      coalesce(json_extract(o.payload, '$.attributes.genreNames'), '[]') as genre_names_json,
      coalesce(json_extract(o.payload, '$.attributes.hasLyrics'), 0) as has_lyrics,
      coalesce(json_extract(o.payload, '$.attributes.hasTimeSyncedLyrics'), 0) as has_time_synced_lyrics,
      coalesce(json_extract(o.payload, '$.attributes.inLibrary'), 0) as in_library
    from objects o
    left join object_relationships r
      on r.parent_identifier = o.identifier
     and r.person_id = o.person_id
     and r.child_key = 'MPModelChildSongAlbum'
    left join objects a
      on a.identifier = r.child_identifier
     and a.person_id = o.person_id
     and a.type = 'albums'
    where o.type = 'songs'
    order by title collate nocase, artist_name collate nocase, o.identifier;
    """
}

private struct CountRow: Decodable {
    var count: Int
}

private struct MusicSongRow: Decodable {
    var id: String
    var title: String
    var artistName: String
    var albumID: String
    var albumTitle: String
    var url: String
    var artworkURLTemplate: String
    var duration: Double?
    var genres: [String]
    var hasLyrics: Bool
    var hasTimeSyncedLyrics: Bool
    var inLibrary: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistName = "artist_name"
        case albumID = "album_id"
        case albumTitle = "album_title"
        case url
        case artworkURLTemplate = "artwork_url_template"
        case durationMS = "duration_ms"
        case genreNamesJSON = "genre_names_json"
        case hasLyrics = "has_lyrics"
        case hasTimeSyncedLyrics = "has_time_synced_lyrics"
        case inLibrary = "in_library"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artistName = try container.decode(String.self, forKey: .artistName)
        albumID = try container.decode(String.self, forKey: .albumID)
        albumTitle = try container.decode(String.self, forKey: .albumTitle)
        url = try container.decode(String.self, forKey: .url)
        artworkURLTemplate = try container.decode(String.self, forKey: .artworkURLTemplate)
        if let durationMS = try container.decodeFlexibleDoubleIfPresent(forKey: .durationMS) {
            duration = durationMS / 1000
        } else {
            duration = nil
        }
        let genreNamesJSON = try container.decodeIfPresent(String.self, forKey: .genreNamesJSON) ?? "[]"
        genres = decodeStringArrayJSON(genreNamesJSON)
        hasLyrics = try container.decodeSQLiteBool(forKey: .hasLyrics)
        hasTimeSyncedLyrics = try container.decodeSQLiteBool(forKey: .hasTimeSyncedLyrics)
        inLibrary = try container.decodeSQLiteBool(forKey: .inLibrary)
    }
}

private struct AppleMusicLibrarySongRow: Decodable {
    var id: String
    var persistentID: String
    var databaseID: Int
    var title: String
    var artistName: String
    var albumTitle: String
    var albumArtist: String
    var duration: Double
    var genre: String
    var trackNumber: Int
    var trackCount: Int
    var discNumber: Int
    var discCount: Int
    var year: Int
    var cloudStatus: String
    var kind: String
    var favorited: Bool
    var disliked: Bool
    var playedCount: Int
    var skippedCount: Int
    var dateAdded: String
    var releaseDate: String
    var playedDate: String
    var size: Int

    var song: MusicSong {
        MusicSong(
            id: id,
            title: title,
            artistName: artistName,
            albumID: "",
            albumTitle: albumTitle,
            albumArtist: albumArtist,
            duration: duration > 0 ? duration : nil,
            genres: genre.isEmpty ? [] : [genre],
            inLibrary: true,
            persistentID: persistentID.isEmpty ? nil : persistentID,
            databaseID: databaseID > 0 ? databaseID : nil,
            cloudStatus: cloudStatus.isEmpty ? nil : cloudStatus,
            kind: kind.isEmpty ? nil : kind,
            dateAdded: dateAdded.isEmpty ? nil : dateAdded,
            releaseDate: releaseDate.isEmpty ? nil : releaseDate,
            playedDate: playedDate.isEmpty ? nil : playedDate,
            playedCount: playedCount,
            skippedCount: skippedCount,
            favorited: favorited,
            disliked: disliked
        )
    }
}

private struct MusicAnalysisRow: Equatable {
    var duration: Double?
    var genres: [String]
}

private struct MusicAnalysisSQLiteRow: Decodable {
    var id: String
    var duration: Double?
    var allGenresJSON: String?

    var analysis: MusicAnalysisRow {
        MusicAnalysisRow(duration: duration, genres: decodeGenrePayload(allGenresJSON))
    }

    enum CodingKeys: String, CodingKey {
        case id
        case duration
        case allGenresJSON = "all_genres_json"
    }
}

private extension KeyedDecodingContainer {
    func decodeSQLiteBool(forKey key: Key) throws -> Bool {
        if let bool = try? decodeIfPresent(Bool.self, forKey: key) {
            return bool
        }
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return int != 0
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return ["1", "true", "yes"].contains(string.lowercased())
        }
        return false
    }

    func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        if let double = try? decodeIfPresent(Double.self, forKey: key) {
            return double
        }
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(int)
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Double(string)
        }
        return nil
    }
}

private func decodeStringArrayJSON(_ text: String) -> [String] {
    guard let data = text.data(using: .utf8),
          let values = try? JSONDecoder().decode([String].self, from: data) else {
        return []
    }
    return values
}

private func decodeGenrePayload(_ text: String?) -> [String] {
    guard let text,
          let data = text.data(using: .utf8),
          let payload = try? JSONDecoder().decode(MusicGenrePayload.self, from: data) else {
        return []
    }
    return payload.value.data.compactMap { item in
        let name = item.attributes.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }
}

private func resolveUniqueMatch(_ matches: [MusicSong]) -> MusicSong? {
    guard matches.count == 1 else {
        return nil
    }
    return matches[0]
}

private struct MusicGenrePayload: Decodable {
    var value: MusicGenreValue
}

private struct MusicGenreValue: Decodable {
    var data: [MusicGenreItem]
}

private struct MusicGenreItem: Decodable {
    var attributes: MusicGenreAttributes
}

private struct MusicGenreAttributes: Decodable {
    var name: String
}

private func jsStringLiteral(_ value: String) -> String {
    guard let data = try? JSONEncoder().encode(value),
          let literal = String(data: data, encoding: .utf8) else {
        return "\"\""
    }
    return literal
}
