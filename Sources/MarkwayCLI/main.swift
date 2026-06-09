import ArgumentParser
import Darwin
import Foundation
import MarkwayCore

@main
struct Markway: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "markway",
        abstract: "A gateway between Apple services and Markdown.",
        version: "0.1.2",
        subcommands: [
            Doctor.self,
            JournalEntriesCommand.self,
            JournalEntryCommand.self,
            JournalReadCommand.self,
            JournalPushCommand.self,
            JournalPullCommand.self,
            MusicSongsCommand.self,
            MusicSongCommand.self,
            MusicAlbumsCommand.self,
            MusicAlbumCommand.self,
            MusicSearchCommand.self,
            Journal.self,
            Music.self,
            Sync.self,
            Agent.self
        ]
    )

    func run() throws {
        let tui = MarkwayTUI()
        try tui.run()
    }
}

struct Doctor: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check local Markway dependencies.",
        shouldDisplay: false
    )

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    @Flag(help: "Also verify that this process can read the Apple Journal store.")
    var journalAccess = false

    func run() throws {
        let tool = try resolveJournalTool(journalTool)
        print("journal tool: \(tool.executableURL.path)")
        print("completion: markway --generate-completion-script zsh")
        if journalAccess {
            _ = try tool.runRaw(["sync-status"])
            print("journal access: ok")
        }
    }
}

struct Journal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journal",
        abstract: "Work with Apple Journal entries.",
        shouldDisplay: false,
        subcommands: [
            JournalList.self,
            JournalGet.self,
            JournalPush.self,
            JournalPull.self,
            JournalRaw.self
        ]
    )
}

struct JournalEntriesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journal:entries",
        abstract: "List synced Journal Markdown entry paths."
    )

    @Argument(help: "Optional key=value parameters. Accepts folder=Journal file=Recipe path=Journal/Recipe.md count total limit=10 vault=/path/to/vault.")
    var arguments: [String] = []

    @Option(help: "Vault or Markdown folder path.")
    var vault: String?

    @Option(help: "Maximum paths to print.")
    var limit: Int?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let index = try JournalVaultIndex.load(vaultURL: try resolveVaultURL(vault ?? parameters.value("vault")))
        var files = try index.filter(
            folder: parameters.value("folder"),
            file: parameters.value("file"),
            path: parameters.value("path")
        )
        if let limit = limit ?? parameters.intValue("limit") {
            files = Array(files.prefix(max(0, limit)))
        }

        if parameters.boolFlag("count") || parameters.boolFlag("total") {
            print(files.count)
        } else if files.isEmpty {
            print("No Journal entries.")
        } else {
            print(files.map(\.path).joined(separator: "\n"))
        }
    }
}

struct JournalEntryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journal:entry",
        abstract: "Show synced Journal Markdown entry info."
    )

    @Argument(help: "Target file. Accepts file=Recipe path=Journal/Recipe.md vault=/path/to/vault.")
    var arguments: [String] = []

    @Option(help: "Vault or Markdown folder path.")
    var vault: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let index = try JournalVaultIndex.load(vaultURL: try resolveVaultURL(vault ?? parameters.value("vault")))
        guard let file = try index.resolveFile(parameters: parameters) else {
            print("Not a Journal entry")
            return
        }

        let tool = try? resolveJournalTool(journalTool ?? parameters.value("journalTool"))
        let entry = tool.flatMap { try? $0.get(id: file.journalID) }
        let attachments = tool.flatMap { try? journalAttachmentCount(tool: $0, entryID: file.journalID) }
        print(formatJournalFileInfo(file, entry: entry, attachmentCount: attachments))
    }
}

struct JournalReadCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journal:read",
        abstract: "Read the Apple Journal body for a synced Markdown entry."
    )

    @Argument(help: "Target file. Accepts file=Recipe path=Journal/Recipe.md vault=/path/to/vault.")
    var arguments: [String] = []

    @Option(help: "Vault or Markdown folder path.")
    var vault: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let index = try JournalVaultIndex.load(vaultURL: try resolveVaultURL(vault ?? parameters.value("vault")))
        guard let file = try index.resolveFile(parameters: parameters) else {
            print("Not a Journal entry")
            return
        }

        let tool = try resolveJournalTool(journalTool ?? parameters.value("journalTool"))
        let entry = try tool.get(id: file.journalID)
        print(entry.body, terminator: entry.body.hasSuffix("\n") ? "" : "\n")
    }
}

struct JournalPushCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journal:push",
        abstract: "Create or update a Journal entry from a Markdown file."
    )

    @Argument(help: "Markdown file and optional key=value parameters. Accepts file=Entry.md title=Title.")
    var arguments: [String] = []

    @Option(help: "Entry title. Defaults to frontmatter title or the file name.")
    var title: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    @Flag(help: "Do not write Markway frontmatter back to the Markdown file.")
    var noWriteFrontmatter = false

    func run() throws {
        try runJournalPush(
            arguments: arguments,
            title: title,
            journalTool: journalTool,
            noWriteFrontmatter: noWriteFrontmatter,
            commandName: "journal:push"
        )
    }
}

struct JournalPullCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journal:pull",
        abstract: "Write a Journal entry into a Markdown file."
    )

    @Argument(help: "Entry selector and optional key=value parameters. Accepts id=Flexoki out=Entry.md.")
    var arguments: [String] = []

    @Option(name: .shortAndLong, help: "Markdown file to write.")
    var out: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        try runJournalPull(
            arguments: arguments,
            out: out,
            journalTool: journalTool,
            commandName: "journal:pull"
        )
    }
}

struct JournalList: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List Journal entries.")

    @Argument(help: "Optional title or UUID prefix query.")
    var arguments: [String] = []

    @Option(help: "Maximum rows to print.")
    var limit: Int?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let query = parameters.value("query") ?? parameters.firstPositional
        let tool = try resolveJournalTool(journalTool)
        var entries = try tool.list()
        if let query, !query.isEmpty {
            let needle = query.lowercased()
            entries = entries.filter { entry in
                entry.id.lowercased().hasPrefix(needle)
                || entry.title.lowercased().contains(needle)
            }
        }
        if let limit {
            entries = Array(entries.prefix(max(0, limit)))
        }
        print(formatEntries(entries))
    }
}

struct JournalGet: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "get", abstract: "Retrieve a Journal entry.")

    @Argument(help: "Entry selector. Use a full UUID, UUID prefix, or title substring. Also accepts id=value.")
    var arguments: [String] = []

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        guard let selector = parameters.value("id") ?? parameters.firstPositional else {
            throw ValidationError("get requires an entry selector, for example id=Flexoki")
        }
        let tool = try resolveJournalTool(journalTool)
        let id = try tool.resolveEntryID(selector)
        print(try tool.runRaw(["get", id]), terminator: "")
    }
}

struct JournalPush: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "push",
        abstract: "Create or update a Journal entry from a Markdown file."
    )

    @Argument(help: "Markdown file and optional key=value parameters. Accepts file=Entry.md title=Title.")
    var arguments: [String] = []

    @Option(help: "Entry title. Defaults to frontmatter title or the file name.")
    var title: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    @Flag(help: "Do not write Markway frontmatter back to the Markdown file.")
    var noWriteFrontmatter = false

    func run() throws {
        try runJournalPush(
            arguments: arguments,
            title: title,
            journalTool: journalTool,
            noWriteFrontmatter: noWriteFrontmatter,
            commandName: "journal:push"
        )
    }
}

struct JournalPull: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pull",
        abstract: "Write a Journal entry into a Markdown file."
    )

    @Argument(help: "Entry selector and optional key=value parameters. Accepts id=Flexoki out=Entry.md.")
    var arguments: [String] = []

    @Option(name: .shortAndLong, help: "Markdown file to write.")
    var out: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        try runJournalPull(
            arguments: arguments,
            out: out,
            journalTool: journalTool,
            commandName: "journal:pull"
        )
    }
}

struct JournalRaw: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "raw",
        abstract: "Pass arguments directly to journal_text.zsh."
    )

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    @Argument(parsing: .remaining, help: "Arguments for journal_text.zsh.")
    var arguments: [String]

    func run() throws {
        let tool = try resolveJournalTool(journalTool)
        print(try tool.runRaw(arguments), terminator: "")
    }
}

struct Music: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music",
        abstract: "Work with Apple Music catalog data.",
        discussion: "Reads Apple Music's local ServerObjectDatabase SQLite cache.",
        shouldDisplay: false,
        subcommands: [
            MusicList.self,
            MusicSearch.self,
            MusicGet.self,
            MusicPath.self
        ]
    )
}

struct MusicSongsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music:songs",
        abstract: "List songs from the local Apple Music library."
    )

    @Argument(help: "Optional key=value parameters. Accepts artist= album= playlist= count limit=10 limit=all format=json.")
    var arguments: [String] = []

    @Option(help: "Maximum rows to print.")
    var limit: Int?

    @Option(help: "Output format: text, json, or tsv.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        if try shouldUseFastMusicSongCount(parameters: parameters, musicDatabase: musicDatabase, explicitLimit: limit) {
            print(try AppleMusicLibrary().songCount(playlist: parameters.value("playlist")))
            return
        }

        let songs = try rootMusicSongs(
            parameters: parameters,
            musicDatabase: musicDatabase,
            libraryOnly: true,
            limit: musicDisplayLimit(option: limit, parameters: parameters)
        )
        if parameters.boolFlag("count") || parameters.boolFlag("total") {
            print(songs.count)
        } else {
            print(try formatMusicSongs(songs, format: format ?? parameters.value("format") ?? "text"))
        }
    }
}

struct MusicSongCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music:song",
        abstract: "Show one song from the local Apple Music library."
    )

    @Argument(help: "Song selector and optional key=value parameters. Accepts id= song= title= artist= album= format=json.")
    var arguments: [String] = []

    @Option(help: "Output format: text or json.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let song = try resolveRootMusicSong(parameters: parameters, musicDatabase: musicDatabase)
        print(try formatMusicSong(song, format: format ?? parameters.value("format") ?? "text"))
    }
}

struct MusicAlbumsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music:albums",
        abstract: "List albums from the local Apple Music library."
    )

    @Argument(help: "Optional key=value parameters. Accepts artist= album= count limit=10 limit=all format=json.")
    var arguments: [String] = []

    @Option(help: "Maximum rows to print.")
    var limit: Int?

    @Option(help: "Output format: text or json.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let albums = try rootMusicAlbums(
            parameters: parameters,
            musicDatabase: musicDatabase,
            libraryOnly: true,
            limit: musicDisplayLimit(option: limit, parameters: parameters)
        )
        if parameters.boolFlag("count") || parameters.boolFlag("total") {
            print(albums.count)
        } else {
            print(try formatMusicAlbums(albums, format: format ?? parameters.value("format") ?? "text"))
        }
    }
}

struct MusicAlbumCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music:album",
        abstract: "Show one album from the local Apple Music library."
    )

    @Argument(help: "Album selector and optional key=value parameters. Accepts id= album= title= artist= format=json.")
    var arguments: [String] = []

    @Option(help: "Output format: text or json.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let album = try resolveRootMusicAlbum(parameters: parameters, musicDatabase: musicDatabase)
        print(try formatMusicAlbum(album, format: format ?? parameters.value("format") ?? "text"))
    }
}

struct MusicSearchCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music:search",
        abstract: "Search songs in the local Apple Music library."
    )

    @Argument(help: "Search text and optional key=value parameters. Accepts query=Sahiba artist= album= count limit=10 limit=all format=json.")
    var arguments: [String] = []

    @Option(help: "Search query.")
    var query: String?

    @Option(help: "Maximum rows to print.")
    var limit: Int?

    @Option(help: "Output format: text, json, or tsv.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let baseParameters = CommandParameters(arguments)
        guard let query = query ?? baseParameters.value("query") ?? baseParameters.firstPositional else {
            throw ValidationError("music:search requires query=Song")
        }
        let parameters = baseParameters.setting("query", to: query)
        let songs = try rootMusicSongs(
            parameters: parameters,
            musicDatabase: musicDatabase,
            libraryOnly: false,
            limit: musicDisplayLimit(option: limit, parameters: parameters)
        )
        if parameters.boolFlag("count") || parameters.boolFlag("total") {
            print(songs.count)
        } else {
            print(try formatMusicSongs(songs, format: format ?? parameters.value("format") ?? "text"))
        }
    }
}

struct MusicList: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List Apple Music songs cached locally.")

    @Argument(help: "Optional query and key=value parameters. Accepts query=Sahiba format=json.")
    var arguments: [String] = []

    @Option(help: "Maximum rows to print.")
    var limit: Int?

    @Option(help: "Output format: text, json, or tsv.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let query = parameters.value("query") ?? parameters.firstPositional
        let requestedLimit = musicDisplayLimit(option: limit, parameters: parameters)
        let effectiveParameters = query.map { parameters.setting("query", to: $0) } ?? parameters
        let songs = try rootMusicSongs(
            parameters: effectiveParameters,
            musicDatabase: musicDatabase,
            libraryOnly: false,
            limit: requestedLimit
        )
        print(try formatMusicSongs(songs, format: format ?? parameters.value("format") ?? "text"))
    }
}

struct MusicSearch: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "search", abstract: "Search Apple Music songs cached locally.")

    @Argument(help: "Search text and optional key=value parameters. Accepts query=Sahiba format=json.")
    var arguments: [String] = []

    @Option(help: "Search query.")
    var query: String?

    @Option(help: "Maximum rows to print.")
    var limit: Int?

    @Option(help: "Output format: text, json, or tsv.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        guard let query = query ?? parameters.value("query") ?? parameters.firstPositional else {
            throw ValidationError("music search requires query=Song")
        }
        let effectiveParameters = parameters.setting("query", to: query)
        let songs = try rootMusicSongs(
            parameters: effectiveParameters,
            musicDatabase: musicDatabase,
            libraryOnly: false,
            limit: musicDisplayLimit(option: limit, parameters: parameters)
        )
        print(try formatMusicSongs(songs, format: format ?? parameters.value("format") ?? "text"))
    }
}

struct MusicGet: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "get", abstract: "Show one Apple Music song.")

    @Argument(help: "Song selector. Use catalog ID, ID prefix, title, or id=value.")
    var arguments: [String] = []

    @Option(help: "Output format: text or json.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        guard let selector = parameters.value("id") ?? parameters.value("song") ?? parameters.firstPositional else {
            throw ValidationError("music get requires a song selector, for example id=1129452297")
        }
        let song = try resolveRootMusicSong(
            parameters: parameters.setting("id", to: selector),
            musicDatabase: musicDatabase
        )
        print(try formatMusicSong(song, format: format ?? parameters.value("format") ?? "text"))
    }
}

struct MusicPath: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "path", abstract: "Show the Apple Music SQLite cache Markway will read.")

    @Argument(help: "Optional key=value parameters. Accepts format=json.")
    var arguments: [String] = []

    @Option(help: "Output format: text or json.")
    var format: String?

    @Option(help: "Path to Apple Music ServerObjectDatabase SQLite file.")
    var musicDatabase: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        let catalog = try resolveMusicCatalog(musicDatabase ?? parameters.value("musicDatabase") ?? parameters.value("database"))
        let info = try catalog.info()
        let resolvedFormat = format ?? parameters.value("format") ?? "text"
        switch resolvedFormat {
        case "json":
            print(try encodeJSON(info))
        case "text":
            print("database: \(info.databasePath)")
            if let analysisDatabasePath = info.analysisDatabasePath {
                print("analysis database: \(analysisDatabasePath)")
            }
            print("songs: \(info.songCount)")
        default:
            throw ValidationError("unknown format '\(resolvedFormat)'")
        }
    }
}

struct Sync: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Prepare and inspect Markdown sync state.",
        subcommands: [
            SyncInit.self,
            SyncOnce.self
        ]
    )
}

struct SyncInit: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "init", abstract: "Create .markway/config.json.")

    @Argument(help: "Optional key=value parameters. Accepts vault=/path/to/vault.")
    var arguments: [String] = []

    @Option(help: "Vault or Markdown folder path.")
    var vault: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        guard let vaultPath = vault ?? parameters.value("vault") ?? parameters.firstPositional else {
            throw ValidationError("sync init requires vault=/path/to/vault")
        }
        let vaultURL = URL(fileURLWithPath: vaultPath).standardizedFileURL
        let config = MarkwayConfig(vaultPath: vaultURL.path, journalToolPath: journalTool)
        let configURL = MarkwayConfig.configURL(forVault: vaultURL)
        try config.write(to: configURL)
        print(configURL.path)
    }
}

struct SyncOnce: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "once", abstract: "Scan a vault and print the planned Journal actions.")

    @Argument(help: "Optional key=value parameters. Accepts vault=/path/to/vault.")
    var arguments: [String] = []

    @Option(help: "Vault or Markdown folder path.")
    var vault: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        guard let vaultPath = vault ?? parameters.value("vault") ?? parameters.firstPositional else {
            throw ValidationError("sync once requires vault=/path/to/vault")
        }
        try printVaultScan(vaultPath: vaultPath)
    }
}

struct Agent: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Run the Markway background bridge agent.",
        shouldDisplay: false,
        subcommands: [AgentRun.self],
        defaultSubcommand: AgentRun.self
    )
}

struct AgentRun: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run the Markway background bridge agent.",
        shouldDisplay: false
    )

    @Option(help: "Obsidian vault path.")
    var vault: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let vaultURL = try resolveVaultURL(vault)
        let journal = try resolveJournalTool(journalTool)
        let agent = MarkwayBridgeAgent(vaultURL: vaultURL, journal: journal) { event in
            fputs("[\(ISO8601DateFormatter().string(from: Date()))] \(event)\n", stderr)
        }

        try agent.start()
        RunLoop.main.run()
    }
}

struct NoopJournalBackend: JournalBackend {
    func list() throws -> [JournalEntrySummary] { [] }
    func add(title: String, bodyFile: URL) throws -> String { "" }
    func update(id: String, title: String, bodyFile: URL) throws {}
    func delete(id: String) throws {}
    func deleteAttachment(entryID: String, assetID: String) throws {}
    func get(id: String) throws -> JournalEntryText { JournalEntryText(id: id, title: "", body: "") }
    func musicAttachments(id: String) throws -> [JournalMusicAttachment] { [] }
    func runRaw(_ arguments: [String]) throws -> String { "" }
}

func resolveJournalTool(_ explicitPath: String?) throws -> JournalTextTool {
    if let explicitPath, !explicitPath.isEmpty {
        return JournalTextTool(executableURL: URL(fileURLWithPath: explicitPath))
    }

    guard let tool = JournalTextTool.discover() else {
        throw JournalTextToolError.notFound
    }

    return tool
}

func resolveMusicCatalog(_ explicitPath: String?) throws -> SQLiteMusicCatalog {
    if let explicitPath, !explicitPath.isEmpty {
        return SQLiteMusicCatalog(databaseURL: URL(fileURLWithPath: explicitPath))
    }

    guard let catalog = SQLiteMusicCatalog.discover() else {
        throw MusicCatalogError.notFound
    }

    return catalog
}

struct CommandParameters {
    var values: [String: String] = [:]
    var flags: Set<String> = []
    var positionals: [String] = []

    init(_ arguments: [String]) {
        for argument in arguments {
            if let equals = argument.firstIndex(of: "="), equals != argument.startIndex {
                let key = String(argument[..<equals])
                let value = String(argument[argument.index(after: equals)...])
                values[key] = value
            } else if argument.hasPrefix("--") {
                flags.insert(String(argument.dropFirst(2)))
            } else {
                positionals.append(argument)
            }
        }
    }

    var firstPositional: String? {
        positionals.first
    }

    func value(_ key: String) -> String? {
        values[key]
    }

    func intValue(_ key: String) -> Int? {
        values[key].flatMap(Int.init)
    }

    func boolFlag(_ key: String) -> Bool {
        flags.contains(key) || positionals.contains(key) || values[key] == "true"
    }

    func setting(_ key: String, to value: String?) -> CommandParameters {
        guard let value, !value.isEmpty else {
            return self
        }
        var copy = self
        copy.values[key] = value
        return copy
    }
}

private struct JournalLinkedFile {
    var path: String
    var url: URL
    var journalID: String
}

private struct JournalVaultIndex {
    var vaultURL: URL
    var files: [JournalLinkedFile]

    static func load(vaultURL: URL) throws -> JournalVaultIndex {
        var byPath: [String: JournalLinkedFile] = [:]
        for link in pluginDataLinks(vaultURL: vaultURL) {
            byPath[vaultPathKey(link.path)] = link
        }

        for link in legacyFrontmatterLinks(vaultURL: vaultURL) {
            byPath[vaultPathKey(link.path)] = byPath[vaultPathKey(link.path)] ?? link
        }

        return JournalVaultIndex(
            vaultURL: vaultURL,
            files: byPath.values.sorted { $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending }
        )
    }

    func filter(folder: String?, file: String?, path: String?) throws -> [JournalLinkedFile] {
        if let resolved = try resolve(file: file, path: path) {
            return [resolved]
        }

        guard let folder, !folder.isEmpty else {
            return files
        }

        let normalizedFolder = normalizeVaultPath(folder).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !normalizedFolder.isEmpty else {
            return files
        }

        return files.filter { linked in
            linked.path == normalizedFolder || linked.path.hasPrefix(normalizedFolder + "/")
        }
    }

    func resolveFile(parameters: CommandParameters) throws -> JournalLinkedFile? {
        try resolve(file: parameters.value("file") ?? parameters.firstPositional, path: parameters.value("path"))
    }

    func resolve(file: String?, path: String?) throws -> JournalLinkedFile? {
        if let path, !path.isEmpty {
            return linkForPath(path)
        }

        guard let file, !file.isEmpty else {
            return nil
        }

        if let direct = linkForPath(file) {
            return direct
        }

        let selector = stripMarkdownExtension(normalizeVaultPath(file)).lowercased()
        let matches = files.filter { linked in
            let linkedWithoutExtension = stripMarkdownExtension(linked.path).lowercased()
            let basename = stripMarkdownExtension(URL(fileURLWithPath: linked.path).lastPathComponent).lowercased()
            return linkedWithoutExtension == selector || basename == selector
        }

        guard let first = matches.first else {
            return nil
        }
        guard matches.count == 1 else {
            let list = matches.prefix(8).map(\.path).joined(separator: "\n")
            throw ValidationError("file selector '\(file)' is ambiguous:\n\(list)")
        }
        return first
    }

    private func linkForPath(_ path: String) -> JournalLinkedFile? {
        let normalized = normalizeVaultPath(path)
        let candidates = normalized.hasSuffix(".md") ? [normalized] : [normalized, normalized + ".md"]
        return files.first { linked in
            candidates.contains { sameVaultPath($0, linked.path) }
        }
    }

    private static func pluginDataLinks(vaultURL: URL) -> [JournalLinkedFile] {
        let dataURL = vaultURL
            .appendingPathComponent(".obsidian", isDirectory: true)
            .appendingPathComponent("plugins", isDirectory: true)
            .appendingPathComponent("obsidian-markway", isDirectory: true)
            .appendingPathComponent("data.json")
        guard let data = try? Data(contentsOf: dataURL),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let links = root["journalLinks"] as? [String: Any] else {
            return []
        }

        return links.compactMap { id, raw in
            guard let link = raw as? [String: Any],
                  let path = link["path"] as? String,
                  !path.isEmpty else {
                return nil
            }
            let normalized = normalizeVaultPath(path)
            let url = vaultURL.appendingPathComponent(normalized)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            return JournalLinkedFile(path: normalized, url: url, journalID: id)
        }
    }

    private static func legacyFrontmatterLinks(vaultURL: URL) -> [JournalLinkedFile] {
        guard let enumerator = FileManager.default.enumerator(
            at: vaultURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) else {
            return []
        }

        var links: [JournalLinkedFile] = []
        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            if shouldSkipVaultChild(name), (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                enumerator.skipDescendants()
                continue
            }
            guard url.pathExtension == "md" else {
                continue
            }
            guard let document = try? MarkdownDocument.read(from: url) else {
                continue
            }
            guard let id = document[MarkwayMetadataKey.appleJournalID], !id.isEmpty else {
                continue
            }
            links.append(JournalLinkedFile(path: relativeVaultPath(for: url, vaultURL: vaultURL), url: url, journalID: id))
        }
        return links
    }
}

private func runJournalPush(
    arguments: [String],
    title: String?,
    journalTool: String?,
    noWriteFrontmatter: Bool,
    commandName: String
) throws {
    let parameters = CommandParameters(arguments)
    guard let file = parameters.value("file") ?? parameters.value("path") ?? parameters.firstPositional else {
        throw ValidationError("\(commandName) requires a markdown file, for example file=Entry.md")
    }
    let tool = try resolveJournalTool(journalTool ?? parameters.value("journalTool"))
    let engine = MarkwaySyncEngine(journal: tool)
    let id = try engine.pushMarkdownFile(
        URL(fileURLWithPath: file),
        title: title ?? parameters.value("title"),
        writeMetadata: !noWriteFrontmatter
    )
    print(id)
}

private func runJournalPull(
    arguments: [String],
    out: String?,
    journalTool: String?,
    commandName: String
) throws {
    let parameters = CommandParameters(arguments)
    guard let selector = parameters.value("id") ?? parameters.firstPositional else {
        throw ValidationError("\(commandName) requires an entry selector, for example id=Flexoki")
    }
    guard let outputPath = out ?? parameters.value("out") ?? parameters.value("path") else {
        throw ValidationError("\(commandName) requires an output markdown file, for example out=Entry.md")
    }
    let tool = try resolveJournalTool(journalTool ?? parameters.value("journalTool"))
    let id = try tool.resolveEntryID(selector)
    let engine = MarkwaySyncEngine(journal: tool)
    try engine.pullJournalEntry(id: id, to: URL(fileURLWithPath: outputPath))
    print(outputPath)
}

private func resolveVaultURL(_ explicitPath: String?) throws -> URL {
    if let explicitPath = nonEmptyTrimmed(explicitPath) {
        return try validateVaultURL(explicitPath, source: "vault")
    }

    if let environmentPath = nonEmptyTrimmed(ProcessInfo.processInfo.environment["MARKWAY_VAULT"]) {
        return try validateVaultURL(environmentPath, source: "MARKWAY_VAULT")
    }

    if let currentVault = currentDirectoryVaultURL() {
        return currentVault
    }

    if let appVault = persistedAppVaultURL() {
        return appVault
    }

    throw ValidationError("vault is required. Pass vault=/path/to/vault, run inside an Obsidian vault, or set the vault in Markway.app.")
}

private func validateVaultURL(_ path: String, source: String) throws -> URL {
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL
    guard FileManager.default.directoryExists(at: url.appendingPathComponent(".obsidian", isDirectory: true)) else {
        throw ValidationError("\(source) does not point to an Obsidian vault: \(url.path)")
    }
    return url
}

private func currentDirectoryVaultURL() -> URL? {
    var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
    while current.path != "/" {
        if FileManager.default.directoryExists(at: current.appendingPathComponent(".obsidian", isDirectory: true)) {
            return current
        }
        current.deleteLastPathComponent()
    }
    return nil
}

private func persistedAppVaultURL() -> URL? {
    let preferenceURLs = [
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/com.anupchavan.markway.plist"),
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/com.anupchavan.Markway.plist")
    ]

    for url in preferenceURLs {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dictionary = plist as? [String: Any],
              let path = nonEmptyTrimmed(dictionary["vaultPath"] as? String),
              let vaultURL = try? validateVaultURL(path, source: url.lastPathComponent) else {
            continue
        }
        return vaultURL
    }

    return nil
}

private func nonEmptyTrimmed(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
        return nil
    }
    return trimmed
}

private func formatJournalFileInfo(
    _ file: JournalLinkedFile,
    entry: JournalEntryText?,
    attachmentCount: Int?
) -> String {
    let values = (try? file.url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])) ?? URLResourceValues()
    var rows = [
        ("path", file.path),
        ("name", stripMarkdownExtension(file.url.lastPathComponent)),
        ("extension", file.url.pathExtension),
        ("size", String(values.fileSize ?? 0)),
        ("created", millisecondsString(values.creationDate)),
        ("modified", millisecondsString(values.contentModificationDate)),
        ("journalID", file.journalID)
    ]
    if let entry {
        rows.append(("journalCreated", entry.created))
        rows.append(("journalModified", entry.updated))
    }
    if let attachmentCount {
        rows.append(("attachments", String(attachmentCount)))
    }
    return rows.map { "\($0.0)\t\($0.1)" }.joined(separator: "\n")
}

private func journalAttachmentCount(tool: JournalTextTool, entryID: String) throws -> Int {
    let output = try tool.runRaw(["attachments", "list", entryID, "--json"])
    guard let data = output.data(using: .utf8),
          let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let attachments = root["attachments"] as? [[String: Any]] else {
        return 0
    }

    return attachments.filter { attachment in
        attachment["isFullyRemoved"] as? Bool != true
        && attachment["isUndoablyDeleted"] as? Bool != true
    }.count
}

private func millisecondsString(_ date: Date?) -> String {
    guard let date else {
        return ""
    }
    return String(Int64((date.timeIntervalSince1970 * 1000).rounded()))
}

private func relativeVaultPath(for url: URL, vaultURL: URL) -> String {
    let path = url.standardizedFileURL.path
    let root = vaultURL.standardizedFileURL.path
    guard path == root || path.hasPrefix(root + "/") else {
        return normalizeVaultPath(url.path)
    }
    return normalizeVaultPath(String(path.dropFirst(root.count + 1)))
}

private func normalizeVaultPath(_ path: String) -> String {
    path.replacingOccurrences(of: "\\", with: "/")
        .split(separator: "/", omittingEmptySubsequences: true)
        .joined(separator: "/")
}

private func stripMarkdownExtension(_ path: String) -> String {
    path.hasSuffix(".md") ? String(path.dropLast(3)) : path
}

private func vaultPathKey(_ path: String) -> String {
    normalizeVaultPath(path).lowercased()
}

private func sameVaultPath(_ left: String, _ right: String) -> Bool {
    vaultPathKey(left) == vaultPathKey(right)
}

private func shouldSkipVaultChild(_ name: String) -> Bool {
    [".obsidian", ".git", ".markway"].contains(name)
}

private extension FileManager {
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

func formatEntries(_ entries: [JournalEntrySummary]) -> String {
    guard !entries.isEmpty else {
        return "No entries."
    }

    let rows = entries.map { entry in
        let shortID = String(entry.id.prefix(8))
        let title = entry.title.isEmpty ? "(untitled)" : entry.title
        return "\(shortID)  \(entry.created)  \(entry.status)  \(title)"
    }
    return rows.joined(separator: "\n")
}

func printVaultScan(vaultPath: String) throws {
    let engine = MarkwaySyncEngine(journal: NoopJournalBackend())
    let summary = try engine.scanVault(at: URL(fileURLWithPath: vaultPath))
    print("markdown files: \(summary.markdownFiles)")
    print("linked journal entries: \(summary.linkedJournalEntries)")
    print("unlinked markdown files: \(summary.unlinkedMarkdownFiles)")
    for action in summary.actions {
        switch action {
        case .createJournalEntry(let path):
            print("create \(path)")
        case .updateJournalEntry(let path, let id):
            print("update \(id) \(path)")
        }
    }
}

private struct MusicAlbumSummary: Codable {
    var id: String
    var title: String
    var artistName: String
    var songCount: Int
    var inLibrary: Bool
    var songs: [MusicSong]
}

private func rootMusicSongs(
    parameters: CommandParameters,
    musicDatabase: String?,
    libraryOnly: Bool,
    limit: Int?
) throws -> [MusicSong] {
    if let databasePath = musicDatabasePath(option: musicDatabase, parameters: parameters) {
        let catalog = try resolveMusicCatalog(databasePath)
        return try filteredMusicSongs(
            catalog: catalog,
            parameters: parameters,
            libraryOnly: libraryOnly,
            limit: limit
        )
    }

    if let catalog = try discoveredMusicCatalogWithSongs() {
        return try filteredMusicSongs(
            catalog: catalog,
            parameters: parameters,
            libraryOnly: libraryOnly,
            limit: limit
        )
    }

    let songs = try AppleMusicLibrary().filteredSongs(
        query: parameters.value("query"),
        artist: parameters.value("artist"),
        album: parameters.value("album"),
        limit: limit,
        playlist: parameters.value("playlist")
    )
    return filterMusicSongs(songs, parameters: parameters, limit: nil)
}

private func resolveRootMusicSong(parameters: CommandParameters, musicDatabase: String?) throws -> MusicSong {
    let selector = nonEmptyTrimmed(
        parameters.value("id")
        ?? parameters.value("song")
        ?? parameters.value("title")
        ?? parameters.firstPositional
    )

    if let databasePath = musicDatabasePath(option: musicDatabase, parameters: parameters) {
        let catalog = try resolveMusicCatalog(databasePath)
        return try resolveFilteredMusicSong(catalog: catalog, parameters: parameters)
    }

    if let catalog = try discoveredMusicCatalogWithSongs() {
        return try resolveFilteredMusicSong(catalog: catalog, parameters: parameters)
    }

    guard let selector else {
        throw ValidationError("music:song requires id=, song=, or title=")
    }

    do {
        return try AppleMusicLibrary().resolveSong(
            selector: selector,
            artist: parameters.value("artist"),
            album: parameters.value("album"),
            playlist: parameters.value("playlist")
        )
    } catch let error as MusicCatalogError {
        throw ValidationError(error.description)
    }
}

private func rootMusicAlbums(
    parameters: CommandParameters,
    musicDatabase: String?,
    libraryOnly: Bool,
    limit: Int?
) throws -> [MusicAlbumSummary] {
    if let databasePath = musicDatabasePath(option: musicDatabase, parameters: parameters) {
        let catalog = try resolveMusicCatalog(databasePath)
        return try filteredMusicAlbums(
            catalog: catalog,
            parameters: parameters,
            libraryOnly: libraryOnly,
            limit: limit
        )
    }

    if let catalog = try discoveredMusicCatalogWithSongs() {
        return try filteredMusicAlbums(
            catalog: catalog,
            parameters: parameters,
            libraryOnly: libraryOnly,
            limit: limit
        )
    }

    let albums = try AppleMusicLibrary().albums(
        album: parameters.value("album") ?? parameters.value("title"),
        artist: parameters.value("artist"),
        limit: limit,
        playlist: parameters.value("playlist")
    )
    return albums.map { album in
        MusicAlbumSummary(
            id: "",
            title: album.title,
            artistName: album.artistName,
            songCount: album.songCount,
            inLibrary: true,
            songs: album.songs
        )
    }
}

private func resolveRootMusicAlbum(parameters: CommandParameters, musicDatabase: String?) throws -> MusicAlbumSummary {
    let selector = nonEmptyTrimmed(
        parameters.value("id")
        ?? parameters.value("album")
        ?? parameters.value("title")
        ?? parameters.firstPositional
    )
    let lookupParameters: CommandParameters
    if let selector,
       parameters.value("id") == nil,
       parameters.value("album") == nil,
       parameters.value("title") == nil {
        lookupParameters = parameters.setting("album", to: selector)
    } else {
        lookupParameters = parameters
    }

    var albums = try rootMusicAlbums(parameters: lookupParameters, musicDatabase: musicDatabase, libraryOnly: false, limit: nil)
    if let selector {
        albums = albums.filter { musicAlbum($0, matches: selector) }
    }

    guard let first = albums.first else {
        throw ValidationError(selector.map { "no Apple Music album matched '\($0)'" } ?? "music:album requires id=, album=, or title=")
    }
    guard albums.count == 1 else {
        let list = albums.prefix(8).map { "\($0.id)  \($0.title)" }.joined(separator: "\n")
        throw ValidationError(selector.map { "album selector '\($0)' is ambiguous:\n\(list)" } ?? "album selector is ambiguous:\n\(list)")
    }
    return first
}

private func musicDatabasePath(option: String?, parameters: CommandParameters) -> String? {
    nonEmptyTrimmed(option ?? parameters.value("musicDatabase") ?? parameters.value("database"))
}

private func musicDisplayLimit(option: Int?, parameters: CommandParameters) -> Int? {
    if let raw = parameters.value("limit")?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
       ["all", "none", "unlimited"].contains(raw) {
        return nil
    }
    return option ?? parameters.intValue("limit") ?? 20
}

private func shouldUseFastMusicSongCount(
    parameters: CommandParameters,
    musicDatabase: String?,
    explicitLimit: Int?
) throws -> Bool {
    guard explicitLimit == nil,
          parameters.intValue("limit") == nil,
          musicDatabasePath(option: musicDatabase, parameters: parameters) == nil,
          nonEmptyTrimmed(parameters.value("query")) == nil,
          nonEmptyTrimmed(parameters.value("artist")) == nil,
          nonEmptyTrimmed(parameters.value("album")) == nil,
          try discoveredMusicCatalogWithSongs() == nil else {
        return false
    }
    return parameters.boolFlag("count") || parameters.boolFlag("total")
}

private func discoveredMusicCatalogWithSongs() throws -> SQLiteMusicCatalog? {
    guard let catalog = SQLiteMusicCatalog.discover() else {
        return nil
    }
    return try catalog.info().songCount > 0 ? catalog : nil
}

private func filteredMusicSongs(
    catalog: SQLiteMusicCatalog,
    parameters: CommandParameters,
    libraryOnly: Bool,
    limit: Int?
) throws -> [MusicSong] {
    if let playlist = nonEmptyTrimmed(parameters.value("playlist")) {
        throw ValidationError("music playlist filtering is not decoded from Apple's local SQLite cache yet: \(playlist)")
    }

    var songs = try catalog.songs()
    if libraryOnly {
        songs = songs.filter(\.inLibrary)
    }
    return filterMusicSongs(songs, parameters: parameters, limit: limit)
}

private func filterMusicSongs(_ songs: [MusicSong], parameters: CommandParameters, limit: Int?) -> [MusicSong] {
    var songs = songs
    if let query = nonEmptyTrimmed(parameters.value("query")) {
        songs = songs.filter { musicSong($0, matches: query) }
    }
    if let artist = nonEmptyTrimmed(parameters.value("artist")) {
        songs = songs.filter { containsCaseInsensitive($0.artistName, artist) }
    }
    if let album = nonEmptyTrimmed(parameters.value("album")) {
        songs = songs.filter {
            containsCaseInsensitive($0.albumTitle, album) || containsCaseInsensitive($0.albumID, album)
        }
    }

    guard let limit else {
        return songs
    }
    return Array(songs.prefix(max(0, limit)))
}

private func resolveFilteredMusicSong(catalog: SQLiteMusicCatalog, parameters: CommandParameters) throws -> MusicSong {
    let selector = nonEmptyTrimmed(
        parameters.value("id")
        ?? parameters.value("song")
        ?? parameters.value("title")
        ?? parameters.firstPositional
    )
    var songs = try filteredMusicSongs(catalog: catalog, parameters: parameters, libraryOnly: false, limit: nil)
    if let selector {
        songs = songs.filter { musicSong($0, matches: selector) }
    }

    guard let first = songs.first else {
        throw ValidationError(selector.map { "no Apple Music song matched '\($0)'" } ?? "music:song requires id=, song=, or title=")
    }
    guard songs.count == 1 else {
        let list = songs.prefix(8).map { "\($0.id)  \($0.title)" }.joined(separator: "\n")
        throw ValidationError(selector.map { "song selector '\($0)' is ambiguous:\n\(list)" } ?? "song selector is ambiguous:\n\(list)")
    }
    return first
}

private func filteredMusicAlbums(
    catalog: SQLiteMusicCatalog,
    parameters: CommandParameters,
    libraryOnly: Bool,
    limit: Int?
) throws -> [MusicAlbumSummary] {
    let songs = try filteredMusicSongs(catalog: catalog, parameters: parameters, libraryOnly: libraryOnly, limit: nil)
    return musicAlbums(from: songs, limit: limit)
}

private func musicAlbums(from songs: [MusicSong], limit: Int?) -> [MusicAlbumSummary] {
    var groups: [String: [MusicSong]] = [:]
    for song in songs where !song.albumID.isEmpty || !song.albumTitle.isEmpty {
        let key = song.albumID.isEmpty
            ? "title:\(song.albumTitle.lowercased())|\((song.albumArtist ?? "").lowercased())"
            : "id:\(song.albumID)"
        groups[key, default: []].append(song)
    }

    var albums = groups.values.map { songs -> MusicAlbumSummary in
        let first = songs[0]
        let title = first.albumTitle.isEmpty ? "(unknown album)" : first.albumTitle
        let artist = commonArtistName(for: songs)
        return MusicAlbumSummary(
            id: first.albumID,
            title: title,
            artistName: artist,
            songCount: songs.count,
            inLibrary: songs.contains(where: \.inLibrary),
            songs: songs
        )
    }
    .sorted {
        let titleCompare = $0.title.localizedCaseInsensitiveCompare($1.title)
        if titleCompare != .orderedSame {
            return titleCompare == .orderedAscending
        }
        return $0.artistName.localizedCaseInsensitiveCompare($1.artistName) == .orderedAscending
    }

    guard let limit else {
        return albums
    }
    albums = Array(albums.prefix(max(0, limit)))
    return albums
}

private func resolveFilteredMusicAlbum(catalog: SQLiteMusicCatalog, parameters: CommandParameters) throws -> MusicAlbumSummary {
    let selector = nonEmptyTrimmed(
        parameters.value("id")
        ?? parameters.value("album")
        ?? parameters.value("title")
        ?? parameters.firstPositional
    )
    var albums = try filteredMusicAlbums(catalog: catalog, parameters: parameters, libraryOnly: false, limit: nil)
    if let selector {
        albums = albums.filter { musicAlbum($0, matches: selector) }
    }

    guard let first = albums.first else {
        throw ValidationError(selector.map { "no Apple Music album matched '\($0)'" } ?? "music:album requires id=, album=, or title=")
    }
    guard albums.count == 1 else {
        let list = albums.prefix(8).map { "\($0.id)  \($0.title)" }.joined(separator: "\n")
        throw ValidationError(selector.map { "album selector '\($0)' is ambiguous:\n\(list)" } ?? "album selector is ambiguous:\n\(list)")
    }
    return first
}

func formatMusicSongs(_ songs: [MusicSong], format: String) throws -> String {
    switch format {
    case "json":
        return try encodeJSON(songs)
    case "tsv":
        guard !songs.isEmpty else { return "" }
        return songs.map { song in
            [
                song.id,
                song.title,
                song.artistName,
                song.albumTitle,
                song.url
            ].map(escapeTSV).joined(separator: "\t")
        }.joined(separator: "\n")
    case "text":
        guard !songs.isEmpty else {
            return "No songs."
        }
        return songs.map { song in
            let title = song.title.isEmpty ? "(untitled)" : song.title
            let artist = song.artistName.isEmpty ? "(unknown artist)" : song.artistName
            let album = song.albumTitle.isEmpty ? "" : "  \(song.albumTitle)"
            return "\(song.id)  \(title)  \(artist)\(album)"
        }.joined(separator: "\n")
    default:
        throw ValidationError("unknown format '\(format)'")
    }
}

func formatMusicSong(_ song: MusicSong, format: String) throws -> String {
    switch format {
    case "json":
        return try encodeJSON(song)
    case "text":
        var lines = [
            "id: \(song.id)",
            "title: \(song.title)",
            "artist: \(song.artistName)"
        ]
        if !song.albumTitle.isEmpty {
            lines.append("album: \(song.albumTitle)")
        }
        if let albumArtist = nonEmptyTrimmed(song.albumArtist) {
            lines.append("albumArtist: \(albumArtist)")
        }
        if !song.albumID.isEmpty {
            lines.append("albumID: \(song.albumID)")
        }
        if let persistentID = nonEmptyTrimmed(song.persistentID) {
            lines.append("persistentID: \(persistentID)")
        }
        if let databaseID = song.databaseID {
            lines.append("databaseID: \(databaseID)")
        }
        if let duration = song.duration {
            lines.append(String(format: "duration: %.3f", duration))
        }
        if !song.genres.isEmpty {
            lines.append("genres: \(song.genres.joined(separator: ", "))")
        }
        lines.append("hasLyrics: \(song.hasLyrics)")
        lines.append("hasTimeSyncedLyrics: \(song.hasTimeSyncedLyrics)")
        lines.append("inLibrary: \(song.inLibrary)")
        if let cloudStatus = nonEmptyTrimmed(song.cloudStatus) {
            lines.append("cloudStatus: \(cloudStatus)")
        }
        if let kind = nonEmptyTrimmed(song.kind) {
            lines.append("kind: \(kind)")
        }
        if let dateAdded = nonEmptyTrimmed(song.dateAdded) {
            lines.append("dateAdded: \(dateAdded)")
        }
        if let releaseDate = nonEmptyTrimmed(song.releaseDate) {
            lines.append("releaseDate: \(releaseDate)")
        }
        if let playedDate = nonEmptyTrimmed(song.playedDate) {
            lines.append("playedDate: \(playedDate)")
        }
        if let playedCount = song.playedCount {
            lines.append("playedCount: \(playedCount)")
        }
        if let skippedCount = song.skippedCount {
            lines.append("skippedCount: \(skippedCount)")
        }
        if let favorited = song.favorited {
            lines.append("favorited: \(favorited)")
        }
        if let disliked = song.disliked {
            lines.append("disliked: \(disliked)")
        }
        if !song.url.isEmpty {
            lines.append("url: \(song.url)")
        }
        if !song.artworkURLTemplate.isEmpty {
            lines.append("artwork: \(song.artworkURLTemplate)")
        }
        return lines.joined(separator: "\n")
    default:
        throw ValidationError("unknown format '\(format)'")
    }
}

private func formatMusicAlbums(_ albums: [MusicAlbumSummary], format: String) throws -> String {
    switch format {
    case "json":
        return try encodeJSON(albums)
    case "text":
        guard !albums.isEmpty else {
            return "No albums."
        }
        return albums.map { album in
            let id = album.id.isEmpty ? "-" : album.id
            let artist = album.artistName.isEmpty ? "(unknown artist)" : album.artistName
            return "\(id)  \(album.title)  \(artist)  songs:\(album.songCount)"
        }.joined(separator: "\n")
    default:
        throw ValidationError("unknown format '\(format)'")
    }
}

private func formatMusicAlbum(_ album: MusicAlbumSummary, format: String) throws -> String {
    switch format {
    case "json":
        return try encodeJSON(album)
    case "text":
        var lines = [
            "id: \(album.id)",
            "title: \(album.title)",
            "artist: \(album.artistName)",
            "songs: \(album.songCount)",
            "inLibrary: \(album.inLibrary)"
        ]
        if !album.songs.isEmpty {
            lines.append("---")
            lines.append(contentsOf: album.songs.map { song in
                "\(song.id)  \(song.title)  \(song.artistName)"
            })
        }
        return lines.joined(separator: "\n")
    default:
        throw ValidationError("unknown format '\(format)'")
    }
}

private func musicSong(_ song: MusicSong, matches selector: String) -> Bool {
    containsCaseInsensitive(song.id, selector)
    || containsCaseInsensitive(song.persistentID ?? "", selector)
    || containsCaseInsensitive(song.databaseID.map(String.init) ?? "", selector)
    || containsCaseInsensitive(song.title, selector)
    || containsCaseInsensitive(song.artistName, selector)
    || containsCaseInsensitive(song.albumTitle, selector)
    || containsCaseInsensitive(song.albumArtist ?? "", selector)
    || containsCaseInsensitive(song.cloudStatus ?? "", selector)
    || containsCaseInsensitive(song.kind ?? "", selector)
}

private func musicAlbum(_ album: MusicAlbumSummary, matches selector: String) -> Bool {
    containsCaseInsensitive(album.id, selector)
    || containsCaseInsensitive(album.title, selector)
    || containsCaseInsensitive(album.artistName, selector)
}

private func containsCaseInsensitive(_ value: String, _ needle: String) -> Bool {
    value.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
}

private func commonArtistName(for songs: [MusicSong]) -> String {
    let artists = songs
        .map { $0.albumArtist ?? $0.artistName }
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    guard let first = artists.first else {
        return ""
    }
    return artists.allSatisfy { $0 == first } ? first : "Various Artists"
}

func encodeJSON<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return String(data: try encoder.encode(value), encoding: .utf8) ?? ""
}

func escapeTSV(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\t", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
        .replacingOccurrences(of: "\n", with: " ")
}

private final class MarkwayTUI {
    private let commandName = CommandLine.arguments.first ?? "markway"
    private let catalog = TUICommandCatalog()
    private var cachedMusicSongs: [MusicSong]?
    private static let accent = "\u{001B}[38;2;49;113;178m"

    func run() throws {
        printBanner()
        if !Self.isInteractiveTerminal {
            try runPlainLoop()
            return
        }

        let editor = TerminalLineEditor { [self] line in
            self.suggestions(for: line)
        }

        while let line = editor.readLine() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }

            if ["q", "quit", "exit"].contains(trimmed.lowercased()) {
                return
            }

            if trimmed == "help" || trimmed == "?" {
                printCommandHelp()
                continue
            }

            do {
                try runTUICommand(tokens: tokenize(trimmed))
            } catch {
                print("error: \(error)")
            }
        }
    }

    private static var isInteractiveTerminal: Bool {
        isatty(STDIN_FILENO) == 1 && isatty(STDOUT_FILENO) == 1
    }

    private func runPlainLoop() throws {
        printCommandHelp()
        while true {
            print("\(Self.accent)>\u{001B}[0m ", terminator: "")
            guard let line = readLine() else {
                print()
                return
            }

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }

            if ["q", "quit", "exit"].contains(trimmed.lowercased()) {
                return
            }

            if trimmed == "help" || trimmed == "?" {
                printCommandHelp()
                continue
            }

            do {
                try runTUICommand(tokens: tokenize(trimmed))
            } catch {
                print("error: \(error)")
            }
        }
    }

    private func runTUICommand(tokens: [String]) throws {
        guard let command = tokens.first else {
            return
        }

        let rest = Array(tokens.dropFirst())
        let args: [String]
        switch command {
        case "doctor":
            print("doctor is a hidden diagnostics command. Run `markway doctor --help` outside the TUI.")
            return
        case let command where command.hasPrefix("journal:") || command.hasPrefix("music:"):
            args = [command] + rest
        case "journal":
            if let subcommand = rest.first {
                print("use journal:\(subcommand) ...")
            } else {
                print("use journal:entries, journal:entry, journal:read, journal:push, or journal:pull")
            }
            return
        case "music":
            print("use music:songs, music:song, music:albums, music:album, or music:search")
            return
        case "sync":
            args = tokens
        case "list", "entries", "get", "read", "push", "pull", "raw":
            print("use journal:\(command) ...")
            return
        case "scan", "init":
            print("use sync \(command == "scan" ? "once" : "init") ...")
            return
        default:
            print("unknown command: \(command)")
            printCommandHelp()
            return
        }

        try runProcess(arguments: args)
    }

    private func runProcess(arguments: [String]) throws {
        let process = Process()
        if let executableURL = Self.resolveExecutableURL(commandName) {
            process.executableURL = executableURL
            process.arguments = arguments
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [commandName] + arguments
        }
        try process.run()
        process.waitUntilExit()
    }

    private static func resolveExecutableURL(_ commandName: String) -> URL? {
        if commandName.contains("/") {
            return URL(fileURLWithPath: commandName).standardizedFileURL
        }

        let pathValue = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for directory in pathValue.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(commandName)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }

    private func printBanner() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        print("""
          \u{001B}[1m\(Self.accent)Markway 0.1.2
        \u{001B}[0m
          \u{001B}[1mA gateway between Apple services and Markdown\u{001B}[0m
          \u{001B}[2mTab to autocomplete, ↑/↓ for history, Ctrl+C to quit\u{001B}[0m

        """)
    }

    private func printCommandHelp() {
        print("""
          \u{001B}[1mApple Journal\u{001B}[0m
          \u{001B}[38;5;102mjournal:entries\u{001B}[0m  List synced Journal Markdown paths
          \u{001B}[38;5;102mjournal:entry\u{001B}[0m    Show info for a synced Journal file
          \u{001B}[38;5;102mjournal:read\u{001B}[0m     Read the Journal body for a file
          \u{001B}[38;5;102mjournal:push\u{001B}[0m     Push file=Entry.md title="Title"
          \u{001B}[38;5;102mjournal:pull\u{001B}[0m     Pull id=Entry out=Entry.md

          \u{001B}[1mApple Music\u{001B}[0m
          \u{001B}[38;5;102mmusic:songs\u{001B}[0m       List library songs
          \u{001B}[38;5;102mmusic:song\u{001B}[0m        Show a song by catalog ID or title
          \u{001B}[38;5;102mmusic:albums\u{001B}[0m      List library albums
          \u{001B}[38;5;102mmusic:album\u{001B}[0m       Show an album by catalog ID or title
          \u{001B}[38;5;102mmusic:search\u{001B}[0m      Search library songs

          \u{001B}[1mSync\u{001B}[0m
          \u{001B}[38;5;102msync init\u{001B}[0m         Create .markway/config.json
          \u{001B}[38;5;102msync once\u{001B}[0m         Scan vault=/path/to/vault
        """)
    }

    private func suggestions(for line: String) -> [TUISuggestion] {
        let context = TUICompletionContext(line: line)
        let commandPath = context.commandPath

        if commandPath.count <= 1, !context.hasTrailingSpace {
            return catalog.rootSuggestions(matching: context.currentToken)
        }

        if commandPath.count == 1, context.hasTrailingSpace {
            let children = catalog.childSuggestions(parent: commandPath[0], matching: "")
            return children.isEmpty
                ? catalog.parameterSuggestions(commandPath: context.resolvedCommandPath, matching: "")
                : children
        }

        if commandPath.count == 2, !context.hasTrailingSpace {
            let children = catalog.childSuggestions(parent: commandPath[0], matching: commandPath[1])
            if !children.isEmpty {
                return children
            }
        }

        let musicSuggestions = musicSuggestions(for: context)
        if !musicSuggestions.isEmpty {
            return musicSuggestions
        }

        return catalog.parameterSuggestions(commandPath: context.resolvedCommandPath, matching: context.currentToken)
    }

    private func musicSuggestions(for context: TUICompletionContext) -> [TUISuggestion] {
        guard context.resolvedCommandPath.first?.hasPrefix("music:") == true else {
            return []
        }

        let current = context.currentToken
        if context.resolvedCommandPath == ["music:song"], !current.contains("=") {
            return cachedSongs()
                .filter { song in
                    current.isEmpty
                    || song.id.lowercased().hasPrefix(current.lowercased())
                    || song.title.lowercased().contains(current.lowercased())
                    || song.artistName.lowercased().contains(current.lowercased())
                }
                .prefix(10)
                .map { song in
                    TUISuggestion(
                        insertText: quoteToken(song.title),
                        displayText: song.title,
                        detail: song.artistName.isEmpty ? song.id : "\(song.artistName)  \(song.id)"
                    )
                }
        }

        if context.resolvedCommandPath == ["music:album"], !current.contains("=") {
            return cachedAlbums()
                .filter { album in
                    current.isEmpty
                    || album.id.lowercased().hasPrefix(current.lowercased())
                    || album.title.lowercased().contains(current.lowercased())
                    || album.artistName.lowercased().contains(current.lowercased())
                }
                .prefix(10)
                .map { album in
                    TUISuggestion(
                        insertText: quoteToken(album.title),
                        displayText: album.title,
                        detail: album.artistName.isEmpty ? album.id : "\(album.artistName)  \(album.id)"
                    )
                }
        }

        if context.resolvedCommandPath == ["music:search"],
           current.hasPrefix("query="),
           let equalsIndex = current.firstIndex(of: "=") {
            let rawQuery = String(current[current.index(after: equalsIndex)...]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return cachedSongs()
                .filter { song in
                    rawQuery.isEmpty
                    || song.title.lowercased().contains(rawQuery.lowercased())
                    || song.artistName.lowercased().contains(rawQuery.lowercased())
                }
                .prefix(10)
                .map { song in
                    let value = "query=\(quoteToken(song.title))"
                    return TUISuggestion(insertText: value, displayText: value, detail: song.artistName)
                }
        }

        return []
    }

    private func cachedSongs() -> [MusicSong] {
        if let cachedMusicSongs {
            return cachedMusicSongs
        }

        do {
            let songs = try resolveMusicCatalog(nil).songs()
            cachedMusicSongs = songs
            return songs
        } catch {
            cachedMusicSongs = []
            return []
        }
    }

    private func cachedAlbums() -> [MusicAlbumSummary] {
        do {
            let catalog = try resolveMusicCatalog(nil)
            return try filteredMusicAlbums(catalog: catalog, parameters: CommandParameters([]), libraryOnly: false, limit: 40)
        } catch {
            return []
        }
    }

    private func tokenize(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character?
        var escaping = false

        for character in line {
            if escaping {
                current.append(character)
                escaping = false
                continue
            }

            if character == "\\" {
                escaping = true
                continue
            }

            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                }
                continue
            }

            if character == "\"" || character == "'" {
                quote = character
                continue
            }

            if character.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current.removeAll(keepingCapacity: true)
                }
            } else {
                current.append(character)
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }

    private func quoteToken(_ token: String) -> String {
        guard token.contains(where: \.isWhitespace) || token.contains("\"") else {
            return token
        }
        return "\"\(token.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}

private final class TerminalLineEditor {
    private let prompt = "\(TerminalLineEditor.accent)>\u{001B}[0m "
    private let promptWidth = 2
    private let suggestionsProvider: (String) -> [TUISuggestion]
    private var history: [String] = []
    private var renderedSuggestionLines = 0
    private var selectedSuggestionIndex: Int?
    private static let accent = "\u{001B}[38;2;49;113;178m"

    init(suggestionsProvider: @escaping (String) -> [TUISuggestion]) {
        self.suggestionsProvider = suggestionsProvider
    }

    func readLine() -> String? {
        var originalTermios = termios()
        guard tcgetattr(STDIN_FILENO, &originalTermios) == 0 else {
            return Swift.readLine()
        }

        var raw = originalTermios
        raw.c_iflag &= ~tcflag_t(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
        raw.c_cflag |= tcflag_t(CS8)
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | IEXTEN | ISIG)
        withUnsafeMutableBytes(of: &raw.c_cc) { bytes in
            bytes[Int(VMIN)] = 1
            bytes[Int(VTIME)] = 0
        }

        guard tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == 0 else {
            return Swift.readLine()
        }
        defer {
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        }

        var buffer = ""
        var cursor = 0
        var historyIndex = history.count
        var draft = ""
        selectedSuggestionIndex = nil
        render(buffer: buffer, cursor: cursor)

        while true {
            guard let byte = readByte() else {
                clearRenderedBlock()
                print()
                return nil
            }

            switch byte {
            case 3:
                clearRenderedBlock()
                print()
                return nil
            case 4:
                if buffer.isEmpty {
                    clearRenderedBlock()
                    print()
                    return nil
                }
            case 9:
                acceptCompletion(buffer: &buffer, cursor: &cursor)
            case 10, 13:
                if selectedSuggestionIndex != nil {
                    acceptCompletion(buffer: &buffer, cursor: &cursor)
                    historyIndex = history.count
                    render(buffer: buffer, cursor: cursor)
                    continue
                }
                clearRenderedBlock()
                print("\r\(prompt)\(buffer)")
                let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty, history.last != trimmed {
                    history.append(trimmed)
                }
                return buffer
            case 127, 8:
                deleteBackward(buffer: &buffer, cursor: &cursor)
                selectedSuggestionIndex = nil
                historyIndex = history.count
            case 27:
                handleEscape(buffer: &buffer, cursor: &cursor, historyIndex: &historyIndex, draft: &draft)
            case 1:
                cursor = 0
                selectedSuggestionIndex = nil
            case 2:
                cursor = max(0, cursor - 1)
                selectedSuggestionIndex = nil
            case 5:
                cursor = Array(buffer).count
                selectedSuggestionIndex = nil
            case 6:
                if cursor == Array(buffer).count, !suggestionsProvider(buffer).isEmpty {
                    acceptCompletion(buffer: &buffer, cursor: &cursor)
                } else {
                    cursor = min(Array(buffer).count, cursor + 1)
                }
            case 11:
                deleteToEnd(buffer: &buffer, cursor: cursor)
                selectedSuggestionIndex = nil
            case 12:
                clearRenderedBlock()
                print("\u{001B}[2J\u{001B}[H", terminator: "")
            case 14:
                moveSuggestionOrHistory(
                    direction: 1,
                    buffer: &buffer,
                    cursor: &cursor,
                    historyIndex: &historyIndex,
                    draft: &draft
                )
            case 16:
                moveSuggestionOrHistory(
                    direction: -1,
                    buffer: &buffer,
                    cursor: &cursor,
                    historyIndex: &historyIndex,
                    draft: &draft
                )
            case 21:
                deleteToStart(buffer: &buffer, cursor: &cursor)
                selectedSuggestionIndex = nil
            case 23:
                deletePreviousWord(buffer: &buffer, cursor: &cursor)
                selectedSuggestionIndex = nil
            default:
                if byte >= 32 {
                    insert(Character(UnicodeScalar(byte)), into: &buffer, cursor: &cursor)
                    selectedSuggestionIndex = nil
                    historyIndex = history.count
                }
            }

            render(buffer: buffer, cursor: cursor)
        }
    }

    private func acceptCompletion(buffer: inout String, cursor: inout Int) {
        let suggestions = suggestionsProvider(buffer)
        let selectedIndex = selectedSuggestionIndex ?? 0
        guard suggestions.indices.contains(selectedIndex) else {
            return
        }
        let suggestion = suggestions[selectedIndex]

        let replacement = suggestion.insertText + (suggestion.appendSpace ? " " : "")
        if suggestion.replacesLine {
            buffer = replacement
            cursor = Array(buffer).count
        } else {
            let tokenRange = currentTokenRange(buffer: buffer, cursor: cursor)
            var characters = Array(buffer)
            characters.replaceSubrange(tokenRange.start..<tokenRange.end, with: Array(replacement))
            buffer = String(characters)
            cursor = tokenRange.start + Array(replacement).count
        }
        selectedSuggestionIndex = nil
    }

    private func handleEscape(
        buffer: inout String,
        cursor: inout Int,
        historyIndex: inout Int,
        draft: inout String
    ) {
        guard let first = readByte() else {
            return
        }
        if first == 127 || first == 8 {
            deletePreviousWord(buffer: &buffer, cursor: &cursor)
            selectedSuggestionIndex = nil
            return
        }
        if first == 98 || first == 66 {
            cursor = previousWordCursor(buffer: buffer, cursor: cursor)
            selectedSuggestionIndex = nil
            return
        }
        if first == 102 || first == 70 {
            cursor = nextWordCursor(buffer: buffer, cursor: cursor)
            selectedSuggestionIndex = nil
            return
        }
        guard first == 91, let code = readByte() else {
            return
        }

        switch code {
        case 65:
            moveSuggestionOrHistory(
                direction: -1,
                buffer: &buffer,
                cursor: &cursor,
                historyIndex: &historyIndex,
                draft: &draft
            )
        case 66:
            moveSuggestionOrHistory(
                direction: 1,
                buffer: &buffer,
                cursor: &cursor,
                historyIndex: &historyIndex,
                draft: &draft
            )
        case 67:
            if cursor == Array(buffer).count, !suggestionsProvider(buffer).isEmpty {
                acceptCompletion(buffer: &buffer, cursor: &cursor)
            } else {
                cursor = min(Array(buffer).count, cursor + 1)
                selectedSuggestionIndex = nil
            }
        case 68:
            cursor = max(0, cursor - 1)
            selectedSuggestionIndex = nil
        case 51:
            if readByte() == 126 {
                deleteForward(buffer: &buffer, cursor: &cursor)
                selectedSuggestionIndex = nil
            }
        case 90:
            selectedSuggestionIndex = nil
        default:
            return
        }
    }

    private func insert(_ character: Character, into buffer: inout String, cursor: inout Int) {
        var characters = Array(buffer)
        characters.insert(character, at: cursor)
        buffer = String(characters)
        cursor += 1
    }

    private func deleteBackward(buffer: inout String, cursor: inout Int) {
        guard cursor > 0 else {
            return
        }
        var characters = Array(buffer)
        characters.remove(at: cursor - 1)
        buffer = String(characters)
        cursor -= 1
    }

    private func deleteForward(buffer: inout String, cursor: inout Int) {
        var characters = Array(buffer)
        guard cursor < characters.count else {
            return
        }
        characters.remove(at: cursor)
        buffer = String(characters)
    }

    private func deletePreviousWord(buffer: inout String, cursor: inout Int) {
        guard cursor > 0 else {
            return
        }
        var characters = Array(buffer)
        var start = cursor
        while start > 0, characters[start - 1].isWhitespace {
            start -= 1
        }
        while start > 0, !characters[start - 1].isWhitespace {
            start -= 1
        }
        characters.removeSubrange(start..<cursor)
        buffer = String(characters)
        cursor = start
    }

    private func deleteToStart(buffer: inout String, cursor: inout Int) {
        var characters = Array(buffer)
        characters.removeSubrange(0..<min(cursor, characters.count))
        buffer = String(characters)
        cursor = 0
    }

    private func deleteToEnd(buffer: inout String, cursor: Int) {
        var characters = Array(buffer)
        guard cursor < characters.count else {
            return
        }
        characters.removeSubrange(cursor..<characters.count)
        buffer = String(characters)
    }

    private func moveSuggestionOrHistory(
        direction: Int,
        buffer: inout String,
        cursor: inout Int,
        historyIndex: inout Int,
        draft: inout String
    ) {
        let suggestions = suggestionsProvider(buffer)
        if !suggestions.isEmpty {
            if let selectedSuggestionIndex {
                self.selectedSuggestionIndex = min(max(0, selectedSuggestionIndex + direction), suggestions.count - 1)
            } else {
                self.selectedSuggestionIndex = direction >= 0
                    ? 0
                    : (buffer.isEmpty ? nil : suggestions.count - 1)
            }
            if self.selectedSuggestionIndex != nil || direction >= 0 || !buffer.isEmpty {
                return
            }
        }

        if direction > 0 {
            return
        }

        guard buffer.isEmpty else {
            return
        }

        selectedSuggestionIndex = nil
        if direction < 0 {
            guard !history.isEmpty else { return }
            if historyIndex == history.count {
                draft = buffer
            }
            historyIndex = max(0, historyIndex - 1)
            buffer = history[historyIndex]
            cursor = Array(buffer).count
        } else {
            guard historyIndex < history.count else { return }
            historyIndex += 1
            if historyIndex == history.count {
                buffer = draft
            } else {
                buffer = history[historyIndex]
            }
            cursor = Array(buffer).count
        }
    }

    private func previousWordCursor(buffer: String, cursor: Int) -> Int {
        let characters = Array(buffer)
        var index = min(cursor, characters.count)
        while index > 0, characters[index - 1].isWhitespace {
            index -= 1
        }
        while index > 0, !characters[index - 1].isWhitespace {
            index -= 1
        }
        return index
    }

    private func nextWordCursor(buffer: String, cursor: Int) -> Int {
        let characters = Array(buffer)
        var index = min(cursor, characters.count)
        while index < characters.count, !characters[index].isWhitespace {
            index += 1
        }
        while index < characters.count, characters[index].isWhitespace {
            index += 1
        }
        return index
    }

    private func currentTokenRange(buffer: String, cursor: Int) -> (start: Int, end: Int) {
        let characters = Array(buffer)
        var start = min(cursor, characters.count)
        while start > 0, !characters[start - 1].isWhitespace {
            start -= 1
        }

        var end = min(cursor, characters.count)
        while end < characters.count, !characters[end].isWhitespace {
            end += 1
        }

        return (start, end)
    }

    private func render(buffer: String, cursor: Int) {
        clearRenderedBlock()
        let allSuggestions = suggestionsProvider(buffer)
        let visibleLimit = 10
        if allSuggestions.isEmpty {
            selectedSuggestionIndex = nil
        } else if let selectedSuggestionIndex, selectedSuggestionIndex >= allSuggestions.count {
            self.selectedSuggestionIndex = allSuggestions.count - 1
        }

        print("\r\(prompt)\(buffer)", terminator: "")
        renderedSuggestionLines = 0

        if !allSuggestions.isEmpty {
            let selectedIndex = selectedSuggestionIndex
            let lastVisibleStart = max(0, allSuggestions.count - visibleLimit)
            let visibleStart = selectedIndex.map { min(max(0, $0 - visibleLimit + 1), lastVisibleStart) } ?? 0
            let visibleEnd = min(allSuggestions.count, visibleStart + visibleLimit)
            let suggestions = Array(allSuggestions[visibleStart..<visibleEnd])
            let moreAbove = visibleStart
            let moreBelow = allSuggestions.count - visibleEnd

            print()
            print("\u{001B}[2m──────────────────────────────────────────────────────\u{001B}[0m", terminator: "")
            renderedSuggestionLines += 1

            if moreAbove > 0 {
                print()
                print("    \u{001B}[2m\(moreAbove) more\u{001B}[0m\u{001B}[K", terminator: "")
                renderedSuggestionLines += 1
            }

            for (index, suggestion) in suggestions.enumerated() {
                let absoluteIndex = visibleStart + index
                print()
                let padded = paddedSuggestionLabel(suggestion.displayText)
                if selectedIndex == absoluteIndex {
                    print("  \u{001B}[1m\(Self.accent)> \(padded)\u{001B}[0m\u{001B}[2m\(suggestion.detail)\u{001B}[0m\u{001B}[K", terminator: "")
                } else {
                    print("    \u{001B}[38;5;102m\(padded)\u{001B}[0m\u{001B}[2m\(suggestion.detail)\u{001B}[0m\u{001B}[K", terminator: "")
                }
                renderedSuggestionLines += 1
            }

            if moreBelow > 0 {
                print()
                print("    \u{001B}[2m\(moreBelow) more\u{001B}[0m\u{001B}[K", terminator: "")
                renderedSuggestionLines += 1
            }

            print("\u{001B}[\(renderedSuggestionLines)A", terminator: "")
        }

        print("\r", terminator: "")
        if promptWidth + cursor > 0 {
            print("\u{001B}[\(promptWidth + cursor)C", terminator: "")
        }
        fflush(stdout)
    }

    private func paddedSuggestionLabel(_ value: String) -> String {
        if value.count >= 18 {
            return value + "  "
        }
        return value.padding(toLength: 18, withPad: " ", startingAt: 0)
    }

    private func clearRenderedBlock() {
        print("\r\u{001B}[2K", terminator: "")
        guard renderedSuggestionLines > 0 else {
            return
        }

        for _ in 0..<renderedSuggestionLines {
            print("\u{001B}[B\r\u{001B}[2K", terminator: "")
        }
        print("\u{001B}[\(renderedSuggestionLines)A\r", terminator: "")
        renderedSuggestionLines = 0
    }

    private func readByte() -> UInt8? {
        var byte: UInt8 = 0
        let count = Darwin.read(STDIN_FILENO, &byte, 1)
        return count == 1 ? byte : nil
    }
}

private struct TUISuggestion {
    var insertText: String
    var displayText: String
    var detail: String
    var appendSpace: Bool
    var replacesLine: Bool

    init(
        insertText: String,
        displayText: String? = nil,
        detail: String,
        appendSpace: Bool = true,
        replacesLine: Bool = false
    ) {
        self.insertText = insertText
        self.displayText = displayText ?? insertText
        self.detail = detail
        self.appendSpace = appendSpace
        self.replacesLine = replacesLine
    }
}

private struct TUICompletionContext {
    var line: String
    var tokens: [String]
    var hasTrailingSpace: Bool
    var currentToken: String

    init(line: String) {
        self.line = line
        hasTrailingSpace = line.last?.isWhitespace == true
        tokens = Self.tokenizeCompletion(line)
        currentToken = hasTrailingSpace ? "" : tokens.last ?? ""
    }

    var commandPath: [String] {
        tokens
    }

    var resolvedCommandPath: [String] {
        guard let root = tokens.first else {
            return []
        }
        if root.contains(":") {
            return [root]
        }
        guard tokens.count > 1 else {
            return [root]
        }
        return [root, tokens[1]]
    }

    var prefixBeforeCurrentToken: String {
        guard !hasTrailingSpace, !currentToken.isEmpty else {
            return line
        }
        return String(line.dropLast(currentToken.count))
    }

    private static func tokenizeCompletion(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character?
        var escaping = false

        for character in line {
            if escaping {
                current.append(character)
                escaping = false
                continue
            }

            if character == "\\" {
                escaping = true
                continue
            }

            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                }
                continue
            }

            if character == "\"" || character == "'" {
                quote = character
            } else if character.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current.removeAll(keepingCapacity: true)
                }
            } else {
                current.append(character)
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }
}

private struct TUICommandCatalog {
    private let commands: [TUICommand] = [
        TUICommand(
            name: "journal:entries",
            detail: "List synced Journal Markdown paths",
            parameters: [
                TUIParameter(name: "folder=", detail: "Filter by folder"),
                TUIParameter(name: "file=", detail: "Filter by file name"),
                TUIParameter(name: "path=", detail: "Filter by exact path"),
                TUIParameter(name: "count", detail: "Return path count"),
                TUIParameter(name: "limit=", detail: "Maximum paths"),
                TUIParameter(name: "vault=", detail: "Vault path")
            ]
        ),
        TUICommand(
            name: "journal:entry",
            detail: "Show synced Journal file info",
            parameters: [
                TUIParameter(name: "file=", detail: "File name"),
                TUIParameter(name: "path=", detail: "Exact vault path"),
                TUIParameter(name: "vault=", detail: "Vault path"),
                TUIParameter(name: "journalTool=", detail: "Path to journal_text.zsh")
            ]
        ),
        TUICommand(
            name: "journal:read",
            detail: "Read Journal body for a file",
            parameters: [
                TUIParameter(name: "file=", detail: "File name"),
                TUIParameter(name: "path=", detail: "Exact vault path"),
                TUIParameter(name: "vault=", detail: "Vault path"),
                TUIParameter(name: "journalTool=", detail: "Path to journal_text.zsh")
            ]
        ),
        TUICommand(
            name: "journal:push",
            detail: "Push Markdown to Journal",
            parameters: [
                TUIParameter(name: "file=", detail: "Markdown file"),
                TUIParameter(name: "path=", detail: "Markdown file"),
                TUIParameter(name: "title=", detail: "Entry title"),
                TUIParameter(name: "noWriteFrontmatter", detail: "Do not write frontmatter"),
                TUIParameter(name: "journalTool=", detail: "Path to journal_text.zsh")
            ]
        ),
        TUICommand(
            name: "journal:pull",
            detail: "Pull Journal entry to Markdown",
            parameters: [
                TUIParameter(name: "id=", detail: "UUID prefix or title"),
                TUIParameter(name: "out=", detail: "Markdown output file"),
                TUIParameter(name: "path=", detail: "Markdown output file"),
                TUIParameter(name: "journalTool=", detail: "Path to journal_text.zsh")
            ]
        ),
        TUICommand(
            name: "music:songs",
            detail: "List library songs",
            parameters: musicSongsParameters
        ),
        TUICommand(
            name: "music:song",
            detail: "Show one cached song",
            parameters: musicSongParameters
        ),
        TUICommand(
            name: "music:albums",
            detail: "List library albums",
            parameters: musicAlbumsParameters
        ),
        TUICommand(
            name: "music:album",
            detail: "Show one cached album",
            parameters: musicAlbumParameters
        ),
        TUICommand(
            name: "music:search",
            detail: "Search library songs",
            parameters: musicSearchParameters
        ),
        TUICommand(
            name: "sync",
            detail: "Prepare and inspect Markdown sync state",
            children: [
                TUICommand(name: "init", detail: "Create .markway/config.json", parameters: [
                    TUIParameter(name: "vault=", detail: "Vault or Markdown folder path"),
                    TUIParameter(name: "journalTool=", detail: "Path to journal_text.zsh")
                ]),
                TUICommand(name: "once", detail: "Scan a vault", parameters: [
                    TUIParameter(name: "vault=", detail: "Vault or Markdown folder path")
                ])
            ]
        ),
        TUICommand(name: "help", detail: "Show commands"),
        TUICommand(name: "quit", detail: "Exit Markway")
    ]

    func rootSuggestions(matching token: String) -> [TUISuggestion] {
        filtered(commands, matching: token).map { command in
            TUISuggestion(insertText: command.name, detail: command.detail)
        }
    }

    func childSuggestions(parent: String, matching token: String) -> [TUISuggestion] {
        guard let command = commands.first(where: { $0.name == parent }) else {
            return []
        }
        return filtered(command.children, matching: token).map { child in
            TUISuggestion(insertText: child.name, detail: child.detail)
        }
    }

    func parameterSuggestions(commandPath: [String], matching token: String) -> [TUISuggestion] {
        guard let command = command(at: commandPath) else {
            return []
        }
        return filtered(command.parameters, matching: token).map { parameter in
            TUISuggestion(
                insertText: parameter.name,
                detail: parameter.detail,
                appendSpace: !parameter.name.hasSuffix("=")
            )
        }
    }

    private func command(at path: [String]) -> TUICommand? {
        guard let root = path.first,
              let command = commands.first(where: { $0.name == root }) else {
            return nil
        }
        guard path.count > 1 else {
            return command
        }
        return command.children.first(where: { $0.name == path[1] })
    }

    private func filtered<T: TUICompletable>(_ items: [T], matching token: String) -> [T] {
        let needle = token.lowercased()
        guard !needle.isEmpty else {
            return items
        }
        let prefix = items.filter { $0.name.lowercased().hasPrefix(needle) }
        let contains = items.filter {
            !$0.name.lowercased().hasPrefix(needle)
            && ($0.name.lowercased().contains(needle) || $0.detail.lowercased().contains(needle))
        }
        return prefix + contains
    }

    private static let musicSongsParameters = [
        TUIParameter(name: "artist=", detail: "Filter by artist"),
        TUIParameter(name: "album=", detail: "Filter by album"),
        TUIParameter(name: "playlist=", detail: "Playlist filter, not decoded yet"),
        TUIParameter(name: "count", detail: "Return song count"),
        TUIParameter(name: "limit=", detail: "Maximum rows, or all"),
        TUIParameter(name: "format=json", detail: "JSON output"),
        TUIParameter(name: "format=tsv", detail: "TSV output"),
        TUIParameter(name: "musicDatabase=", detail: "Path to Music SQLite cache")
    ]

    private static let musicSongParameters = [
        TUIParameter(name: "id=", detail: "Catalog ID"),
        TUIParameter(name: "song=", detail: "Song title"),
        TUIParameter(name: "title=", detail: "Song title"),
        TUIParameter(name: "artist=", detail: "Filter by artist"),
        TUIParameter(name: "album=", detail: "Filter by album"),
        TUIParameter(name: "format=json", detail: "JSON output"),
        TUIParameter(name: "musicDatabase=", detail: "Path to Music SQLite cache")
    ]

    private static let musicAlbumsParameters = [
        TUIParameter(name: "artist=", detail: "Filter by artist"),
        TUIParameter(name: "album=", detail: "Filter by album"),
        TUIParameter(name: "count", detail: "Return album count"),
        TUIParameter(name: "limit=", detail: "Maximum rows, or all"),
        TUIParameter(name: "format=json", detail: "JSON output"),
        TUIParameter(name: "musicDatabase=", detail: "Path to Music SQLite cache")
    ]

    private static let musicAlbumParameters = [
        TUIParameter(name: "id=", detail: "Catalog ID"),
        TUIParameter(name: "album=", detail: "Album title"),
        TUIParameter(name: "title=", detail: "Album title"),
        TUIParameter(name: "artist=", detail: "Filter by artist"),
        TUIParameter(name: "format=json", detail: "JSON output"),
        TUIParameter(name: "musicDatabase=", detail: "Path to Music SQLite cache")
    ]

    private static let musicSearchParameters = [
        TUIParameter(name: "query=", detail: "Title, artist, album, or catalog ID"),
        TUIParameter(name: "artist=", detail: "Filter by artist"),
        TUIParameter(name: "album=", detail: "Filter by album"),
        TUIParameter(name: "count", detail: "Return song count"),
        TUIParameter(name: "limit=", detail: "Maximum rows, or all"),
        TUIParameter(name: "format=json", detail: "JSON output"),
        TUIParameter(name: "format=tsv", detail: "TSV output"),
        TUIParameter(name: "musicDatabase=", detail: "Path to Music SQLite cache")
    ]
}

private protocol TUICompletable {
    var name: String { get }
    var detail: String { get }
}

private struct TUICommand: TUICompletable {
    var name: String
    var detail: String
    var children: [TUICommand]
    var parameters: [TUIParameter]

    init(name: String, detail: String, children: [TUICommand] = [], parameters: [TUIParameter] = []) {
        self.name = name
        self.detail = detail
        self.children = children
        self.parameters = parameters
    }
}

private struct TUIParameter: TUICompletable {
    var name: String
    var detail: String
}
