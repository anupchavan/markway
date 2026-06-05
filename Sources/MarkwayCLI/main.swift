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
            Journal.self,
            Sync.self
        ]
    )
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
            JournalGet.self,
            JournalPush.self,
            JournalPull.self,
            JournalRaw.self
        ]
    )
}

struct JournalGet: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "get", abstract: "Retrieve a Journal entry.")

    @Argument(help: "Apple Journal entry UUID.")
    var id: String

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let tool = try resolveJournalTool(journalTool)
        print(try tool.runRaw(["get", id]), terminator: "")
    }
}

struct JournalPush: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "push",
        abstract: "Create or update a Journal entry from a Markdown file."
    )

    @Argument(help: "Markdown file to push.")
    var file: String

    @Option(help: "Entry title. Defaults to frontmatter title or the file name.")
    var title: String?

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    @Flag(help: "Do not write Markway frontmatter back to the Markdown file.")
    var noWriteFrontmatter = false

    func run() throws {
        let tool = try resolveJournalTool(journalTool)
        let engine = MarkwaySyncEngine(journal: tool)
        let id = try engine.pushMarkdownFile(
            URL(fileURLWithPath: file),
            title: title,
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

    @Argument(help: "Apple Journal entry UUID.")
    var id: String

    @Option(name: .shortAndLong, help: "Markdown file to write.")
    var out: String

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let tool = try resolveJournalTool(journalTool)
        let engine = MarkwaySyncEngine(journal: tool)
        try engine.pullJournalEntry(id: id, to: URL(fileURLWithPath: out))
        print(out)
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

    @Option(help: "Vault or Markdown folder path.")
    var vault: String

    @Option(help: "Path to journal_text.zsh.")
    var journalTool: String?

    func run() throws {
        let vaultURL = URL(fileURLWithPath: vault).standardizedFileURL
        let config = MarkwayConfig(vaultPath: vaultURL.path, journalToolPath: journalTool)
        let configURL = MarkwayConfig.configURL(forVault: vaultURL)
        try config.write(to: configURL)
        print(configURL.path)
    }
}

struct SyncOnce: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "once", abstract: "Scan a vault and print the planned Journal actions.")

    @Option(help: "Vault or Markdown folder path.")
    var vault: String

    func run() throws {
        let engine = MarkwaySyncEngine(journal: NoopJournalBackend())
        let summary = try engine.scanVault(at: URL(fileURLWithPath: vault))
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
}

struct NoopJournalBackend: JournalBackend {
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
