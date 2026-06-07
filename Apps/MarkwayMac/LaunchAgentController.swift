import Darwin
import Foundation
import MarkwayCore

struct LaunchAgentController {
    private let bundleURL: URL
    private let label = "com.anupchavan.markway.agent"

    init(bundleURL: URL) {
        self.bundleURL = bundleURL
    }

    func installAndLoad(vaultURL: URL) throws {
        guard FileManager.default.isExecutableFile(atPath: markwayCLIURL.path) else {
            throw ValidationError("Bundled Markway CLI not found. Rebuild Markway.app.")
        }
        guard FileManager.default.isExecutableFile(atPath: journalHelperURL.path) else {
            throw ValidationError("Bundled Journal helper not found. Rebuild Markway.app.")
        }

        try FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)
        try propertyList(vaultURL: vaultURL).write(to: plistURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: plistURL.path)

        let domain = "gui/\(getuid())"
        _ = try? runLaunchctl(["bootout", domain, plistURL.path])
        try runLaunchctl(["bootstrap", domain, plistURL.path])
        try runLaunchctl(["enable", "\(domain)/\(label)"])
        _ = try? runLaunchctl(["kickstart", "-k", "\(domain)/\(label)"])
    }

    private var markwayCLIURL: URL {
        bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Helpers")
            .appendingPathComponent("markway")
    }

    private var journalHelperURL: URL {
        bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Helpers")
            .appendingPathComponent("journal_text")
    }

    private var plistURL: URL {
        launchAgentsURL.appendingPathComponent("\(label).plist")
    }

    private var launchAgentsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
    }

    private var logsURL: URL {
        MarkwayLogReader.logsDirectory
    }

    private func propertyList(vaultURL: URL) throws -> Data {
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [
                markwayCLIURL.path,
                "agent",
                "run",
                "--vault",
                vaultURL.path,
                "--journal-tool",
                journalHelperURL.path
            ],
            "RunAtLoad": true,
            "KeepAlive": true,
            "StandardOutPath": logsURL.appendingPathComponent("agent.log").path,
            "StandardErrorPath": logsURL.appendingPathComponent("agent.err").path,
            "EnvironmentVariables": [
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"
            ]
        ]
        return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }

    @discardableResult
    private func runLaunchctl(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let stdoutText = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderrText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            let details = stderrText.isEmpty ? stdoutText : stderrText
            throw ValidationError("launchctl \(arguments.joined(separator: " ")) failed: \(details)")
        }
        return stdoutText
    }
}

struct ValidationError: Error, CustomStringConvertible {
    var description: String

    init(_ description: String) {
        self.description = description
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

extension FileManager {
    func directoryExists(at url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
