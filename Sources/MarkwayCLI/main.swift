import ArgumentParser
import Foundation
import MarkwayCore

@main
struct Markway: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "markway",
        abstract: "A gateway between Apple services and Markdown.",
        version: "0.1.0",
        subcommands: [
            Doctor.self,
            JournalList.self,
            JournalGet.self,
            JournalPush.self,
            JournalPull.self,
            ScanVault.self,
            Journal.self,
            Sync.self
        ]
    )

    func run() throws {
        try MarkwayTUI().run()
    }
}

struct Doctor: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check local Markway dependencies."
    )

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let tool = try resolveJournalTool(journalTool)
        print("journal tool: \(tool.executableURL.path)")
        print("completion: markway --generate-completion-script zsh")
    }
}

struct Journal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journal",
        abstract: "Work with Apple Journal entries.",
        subcommands: [
            JournalList.self,
            JournalGet.self,
            JournalPush.self,
            JournalPull.self,
            JournalRaw.self
        ]
    )
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
        let parameters = CommandParameters(arguments)
        guard let file = parameters.value("file") ?? parameters.value("path") ?? parameters.firstPositional else {
            throw ValidationError("push requires a markdown file, for example file=Entry.md")
        }
        let tool = try resolveJournalTool(journalTool)
        let engine = MarkwaySyncEngine(journal: tool)
        let id = try engine.pushMarkdownFile(
            URL(fileURLWithPath: file),
            title: title ?? parameters.value("title"),
            writeMetadata: !noWriteFrontmatter
        )
        print(id)
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
        let parameters = CommandParameters(arguments)
        guard let selector = parameters.value("id") ?? parameters.firstPositional else {
            throw ValidationError("pull requires an entry selector, for example id=Flexoki")
        }
        guard let outputPath = out ?? parameters.value("out") ?? parameters.value("path") else {
            throw ValidationError("pull requires an output markdown file, for example out=Entry.md")
        }
        let tool = try resolveJournalTool(journalTool)
        let id = try tool.resolveEntryID(selector)
        let engine = MarkwaySyncEngine(journal: tool)
        try engine.pullJournalEntry(id: id, to: URL(fileURLWithPath: outputPath))
        print(outputPath)
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

struct ScanVault: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "scan", abstract: "Scan a vault and print the planned Journal actions.")

    @Argument(help: "Optional key=value parameters. Accepts vault=/path/to/vault.")
    var arguments: [String] = []

    @Option(help: "Vault or Markdown folder path.")
    var vault: String?

    func run() throws {
        let parameters = CommandParameters(arguments)
        guard let vaultPath = vault ?? parameters.value("vault") ?? parameters.firstPositional else {
            throw ValidationError("scan requires vault=/path/to/vault")
        }
        try printVaultScan(vaultPath: vaultPath)
    }
}

struct NoopJournalBackend: JournalBackend {
    func list() throws -> [JournalEntrySummary] { [] }
    func add(title: String, bodyFile: URL) throws -> String { "" }
    func update(id: String, title: String, bodyFile: URL) throws {}
    func get(id: String) throws -> JournalEntryText { JournalEntryText(id: id, title: "", body: "") }
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

struct MarkwayTUI {
    private let executablePath = CommandLine.arguments[0]

    func run() throws {
        printBanner()
        printCommandList()

        while true {
            print("\u{001B}[38;5;135m>\u{001B}[0m ", terminator: "")
            guard let line = readLine() else {
                print()
                return
            }

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                printCommandList()
                continue
            }

            if ["q", "quit", "exit"].contains(trimmed.lowercased()) {
                return
            }

            if trimmed == "help" || trimmed == "?" {
                printCommandList()
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
            args = ["doctor"] + rest
        case "list", "entries":
            args = ["journal", "list"] + rest
        case "get", "read":
            args = ["journal", "get"] + rest
        case "push":
            args = ["journal", "push"] + rest
        case "pull":
            args = ["journal", "pull"] + rest
        case "scan":
            args = ["scan"] + rest
        case "init":
            args = ["sync", "init"] + rest
        case "raw":
            args = ["journal", "raw"] + rest
        case "journal", "sync":
            args = tokens
        default:
            print("unknown command: \(command)")
            printCommandList()
            return
        }

        try runProcess(arguments: args)
    }

    private func runProcess(arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
    }

    private func printBanner() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        print("""
        \u{001B}[1m\u{001B}[38;5;135m
        Markway 0.1.0
        \u{001B}[0m
        \u{001B}[1mA gateway between Apple services and Markdown\u{001B}[0m
        \u{001B}[2mType help for commands, quit to exit. Key=value parameters work here too.\u{001B}[0m

        """)
    }

    private func printCommandList() {
        print("""
          \u{001B}[38;5;102mdoctor\u{001B}[0m       Check local dependencies
          \u{001B}[38;5;102mlist\u{001B}[0m         List Journal entries, optionally query=...
          \u{001B}[38;5;102mget\u{001B}[0m          Read an entry by UUID prefix or title
          \u{001B}[38;5;102mpush\u{001B}[0m         Push file=Entry.md title="Title" to Journal
          \u{001B}[38;5;102mpull\u{001B}[0m         Pull id=Entry out=Entry.md from Journal
          \u{001B}[38;5;102mscan\u{001B}[0m         Scan vault=/path/to/vault
          \u{001B}[38;5;102mraw\u{001B}[0m          Pass arguments to journal_text.zsh
        """)
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
}
