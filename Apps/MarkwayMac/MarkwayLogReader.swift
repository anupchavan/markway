import Foundation

struct MarkwayLogReader {
    static var logsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("Markway", isDirectory: true)
    }

    static func journalLogTail(maxLines: Int = 160) -> String {
        let paths = [
            logsDirectory.appendingPathComponent("agent.log"),
            logsDirectory.appendingPathComponent("agent.err")
        ]

        let blocks = paths.map { url in
            let body = tail(url: url, maxLines: maxLines / paths.count)
            guard !body.isEmpty else {
                return "\(url.lastPathComponent)\nNo log entries yet."
            }
            return "\(url.lastPathComponent)\n\(body)"
        }
        return blocks.joined(separator: "\n\n")
    }

    private static func tail(url: URL, maxLines: Int) -> String {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            return ""
        }

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.suffix(maxLines).joined(separator: "\n")
    }
}
