import Foundation

public struct MarkdownDocument: Equatable, Sendable {
    public var frontmatter: [String: String]
    public var body: String

    public init(frontmatter: [String: String] = [:], body: String) {
        self.frontmatter = frontmatter
        self.body = body
    }

    public static func read(from url: URL) throws -> MarkdownDocument {
        let text = try String(contentsOf: url, encoding: .utf8)
        return parse(text)
    }

    public func write(to url: URL) throws {
        try serialized().write(to: url, atomically: true, encoding: .utf8)
    }

    public static func parse(_ text: String) -> MarkdownDocument {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        guard normalized.hasPrefix("---\n") else {
            return MarkdownDocument(body: normalized)
        }

        let bodyStart = normalized.index(normalized.startIndex, offsetBy: 4)
        guard let closeRange = normalized.range(of: "\n---\n", range: bodyStart..<normalized.endIndex) else {
            return MarkdownDocument(body: normalized)
        }

        let frontmatterText = String(normalized[bodyStart..<closeRange.lowerBound])
        let body = String(normalized[closeRange.upperBound...])
        return MarkdownDocument(frontmatter: parseFrontmatter(frontmatterText), body: body)
    }

    public func serialized() -> String {
        guard !frontmatter.isEmpty else {
            return body
        }

        let lines = frontmatter.keys.sorted().map { key in
            "\(key): \(Self.yamlQuoted(frontmatter[key] ?? ""))"
        }

        return "---\n" + lines.joined(separator: "\n") + "\n---\n" + body
    }

    public subscript(key: String) -> String? {
        get { frontmatter[key] }
        set { frontmatter[key] = newValue }
    }

    private static func parseFrontmatter(_ text: String) -> [String: String] {
        var result: [String: String] = [:]

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), let colon = line.firstIndex(of: ":") else {
                continue
            }

            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            let rawValue = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            result[key] = unquote(rawValue)
        }

        return result
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2 else {
            return value
        }

        if value.hasPrefix("\""), value.hasSuffix("\"") {
            let data = Data(value.utf8)
            if let decoded = try? JSONDecoder().decode(String.self, from: data) {
                return decoded
            }
        }

        if value.hasPrefix("'"), value.hasSuffix("'") {
            return String(value.dropFirst().dropLast())
        }

        return value
    }

    private static func yamlQuoted(_ value: String) -> String {
        let data = (try? JSONEncoder().encode(value)) ?? Data("\"\"".utf8)
        return String(data: data, encoding: .utf8) ?? "\"\""
    }
}
