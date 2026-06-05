import Foundation

public enum JournalTextToolError: Error, CustomStringConvertible, Sendable {
    case notFound
    case failed(status: Int32, stdout: String, stderr: String)
    case invalidOutput(String)

    public var description: String {
        switch self {
        case .notFound:
            return "journal_text.zsh was not found. Set MARKWAY_JOURNAL_TEXT_TOOL or pass --journal-tool."
        case .failed(let status, let stdout, let stderr):
            let details = stderr.isEmpty ? stdout : stderr
            return "journal_text.zsh failed with status \(status): \(details)"
        case .invalidOutput(let output):
            return "journal_text.zsh returned output Markway could not parse: \(output)"
        }
    }
}

public struct JournalTextTool: JournalBackend {
    public let executableURL: URL

    public init(executableURL: URL) {
        self.executableURL = executableURL
    }

    public static func discover(from start: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> JournalTextTool? {
        if let explicit = ProcessInfo.processInfo.environment["MARKWAY_JOURNAL_TEXT_TOOL"], !explicit.isEmpty {
            return JournalTextTool(executableURL: URL(fileURLWithPath: explicit))
        }

        for url in candidateURLs(from: start) where FileManager.default.isExecutableFile(atPath: url.path) {
            return JournalTextTool(executableURL: url)
        }

        return nil
    }

    public func add(title: String, bodyFile: URL) throws -> String {
        try runRaw(["add", "--title", title, "--body", bodyFile.path]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func update(id: String, title: String, bodyFile: URL) throws {
        _ = try runRaw(["update", id, "--title", title, "--body", bodyFile.path])
    }

    public func get(id: String) throws -> JournalEntryText {
        let output = try runRaw(["get", id])
        let marker = "\n---\n"
        guard let markerRange = output.range(of: marker) else {
            throw JournalTextToolError.invalidOutput(output)
        }

        let header = output[..<markerRange.lowerBound]
        let body = String(output[markerRange.upperBound...])
        var parsedID = id
        var title = ""

        for line in header.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("id: ") {
                parsedID = String(line.dropFirst(4))
            } else if line.hasPrefix("title: ") {
                title = String(line.dropFirst(7))
            }
        }

        return JournalEntryText(id: parsedID, title: title, body: body)
    }

    public func runRaw(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = executableURL
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
            throw JournalTextToolError.failed(status: process.terminationStatus, stdout: stdoutText, stderr: stderrText)
        }

        return stdoutText
    }

    private static func candidateURLs(from start: URL) -> [URL] {
        var candidates: [URL] = []
        for directory in ancestorDirectories(from: start) {
            candidates.append(directory.appendingPathComponent("Vendor/AppleJournalCRDT/tools/journal_text.zsh"))
            candidates.append(directory.appendingPathComponent("tools/journal_text.zsh"))
        }
        candidates.append(URL(fileURLWithPath: "/Users/anup/projects/markway-journal-crdt/tools/journal_text.zsh"))
        return candidates
    }

    private static func ancestorDirectories(from start: URL) -> [URL] {
        var result: [URL] = []
        var current = start.standardizedFileURL
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: current.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            current.deleteLastPathComponent()
        }

        while true {
            result.append(current)
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                break
            }
            current = parent
        }

        return result
    }
}
