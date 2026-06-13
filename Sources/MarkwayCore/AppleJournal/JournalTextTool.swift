import AppKit
import Foundation

public enum JournalTextToolError: Error, CustomStringConvertible, Sendable {
    case notFound
    case failed(status: Int32, stdout: String, stderr: String)
    case invalidOutput(String)
    case ambiguousSelector(String, [JournalEntrySummary])
    case selectorNotFound(String)

    public var description: String {
        switch self {
        case .notFound:
            return "journal_text.zsh was not found. Set MARKWAY_JOURNAL_TEXT_TOOL or pass --journal-tool."
        case .failed(let status, let stdout, let stderr):
            if isJournalPermissionFailure(stdout + "\n" + stderr) {
                return """
                Apple Journal access was denied by macOS privacy controls.
                Grant Full Disk Access to Markway.app, then fully quit and reopen Markway.app.
                If you launched Markway from Xcode, run the built app directly or grant Full Disk Access to that launched app.
                """
            }
            let details = stderr.isEmpty ? stdout : stderr
            return "journal_text.zsh failed with status \(status): \(details)"
        case .invalidOutput(let output):
            return "journal_text.zsh returned output Markway could not parse: \(output)"
        case .ambiguousSelector(let selector, let matches):
            let list = matches.prefix(8).map { "\($0.id)  \($0.title)" }.joined(separator: "\n")
            return "entry selector '\(selector)' is ambiguous:\n\(list)"
        case .selectorNotFound(let selector):
            return "no Journal entry matched '\(selector)'"
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

    public func list() throws -> [JournalEntrySummary] {
        try parseListOutput(runRaw(["list"]))
    }

    public func add(title: String, bodyFile: URL) throws -> String {
        try runRaw(["add", "--title", title, "--body", bodyFile.path]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func update(id: String, title: String, bodyFile: URL) throws {
        _ = try runRaw(["update", id, "--title", title, "--body", bodyFile.path])
    }

    public func delete(id: String) throws {
        _ = try runRaw(["delete", id])
    }

    public func deleteAttachment(entryID: String, assetID: String) throws {
        _ = try runRaw(["attachments", "delete", entryID, assetID])
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
        var created = ""
        var updated = ""

        for line in header.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("id: ") {
                parsedID = String(line.dropFirst(4))
            } else if line.hasPrefix("title: ") {
                title = String(line.dropFirst(7))
            } else if line.hasPrefix("created: ") {
                created = String(line.dropFirst(9))
            } else if line.hasPrefix("updated: ") {
                updated = String(line.dropFirst(9))
            }
        }

        return JournalEntryText(id: parsedID, title: title, body: body, created: created, updated: updated)
    }

    public func musicAttachments(id: String) throws -> [JournalMusicAttachment] {
        let output = try runRaw(["attachments", "list", id, "--json"])
        let data = Data(output.utf8)
        do {
            let payload = try JSONDecoder().decode(JournalAttachmentListPayload.self, from: data)
            return payload.attachments.compactMap { attachment in
                guard attachment.assetType == "music",
                      attachment.isFullyRemoved != true,
                      attachment.isUndoablyDeleted != true,
                      let song = attachment.metadata?.song?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !song.isEmpty else {
                    return nil
                }
                return JournalMusicAttachment(
                    id: attachment.id,
                    song: song,
                    artistName: attachment.metadata?.artistName ?? "",
                    mediaId: attachment.metadata?.mediaId ?? "",
                    source: attachment.source ?? "",
                    isHidden: attachment.isHidden ?? false,
                    isSlim: attachment.isSlim ?? false,
                    mediaType: attachment.metadata?.mediaType?.first?.key ?? "",
                    startTime: attachment.metadata?.startTime,
                    createdDate: attachment.createdDate ?? "",
                    suggestionDate: attachment.suggestionDate ?? ""
                )
            }
        } catch {
            throw JournalTextToolError.invalidOutput(output)
        }
    }

    public func photoAttachments(id: String) throws -> [JournalPhotoAttachment] {
        let output = try runRaw(["attachments", "list", id, "--json"])
        do {
            return try Self.parsePhotoAttachments(fromJSON: output)
        } catch {
            throw JournalTextToolError.invalidOutput(output)
        }
    }

    static let visualAssetTypes: Set<String> = ["photo", "video", "livePhoto"]

    static func parsePhotoAttachments(fromJSON output: String) throws -> [JournalPhotoAttachment] {
        let payload = try JSONDecoder().decode(JournalAttachmentListPayload.self, from: Data(output.utf8))
        return payload.attachments.compactMap { attachment in
            guard let assetType = attachment.assetType,
                  Self.visualAssetTypes.contains(assetType),
                  attachment.isFullyRemoved != true,
                  attachment.isUndoablyDeleted != true else {
                return nil
            }
            let files = (attachment.fileAttachments ?? [])
                .sorted { ($0.index ?? 0) < ($1.index ?? 0) }
                .compactMap { file -> JournalAttachmentFile? in
                    guard let fileID = file.id, !fileID.isEmpty else {
                        return nil
                    }
                    return JournalAttachmentFile(
                        id: fileID,
                        name: file.name ?? "",
                        relativePath: file.relativePath ?? "",
                        absolutePath: file.absolutePath ?? "",
                        exists: file.exists ?? false,
                        byteLength: file.byteLength
                    )
                }
            return JournalPhotoAttachment(
                id: attachment.id,
                assetType: assetType,
                source: attachment.source ?? "",
                isHidden: attachment.isHidden ?? false,
                isSlim: attachment.isSlim ?? false,
                assetIdentifier: attachment.metadata?.assetIdentifier ?? "",
                assetDate: attachment.metadata?.date,
                createdDate: attachment.createdDate ?? "",
                suggestionDate: attachment.suggestionDate ?? "",
                files: files
            )
        }
    }

    public func attachments(id: String) throws -> [JournalGenericAttachment] {
        let output = try runRaw(["attachments", "list", id, "--json"])
        do {
            return try Self.parseGenericAttachments(fromJSON: output)
        } catch {
            throw JournalTextToolError.invalidOutput(output)
        }
    }

    static func parseGenericAttachments(fromJSON output: String) throws -> [JournalGenericAttachment] {
        guard
            let root = try JSONSerialization.jsonObject(with: Data(output.utf8)) as? [String: Any],
            let rawAttachments = root["attachments"] as? [[String: Any]]
        else {
            throw JournalTextToolError.invalidOutput(output)
        }

        return rawAttachments.compactMap { raw in
            guard
                let attachmentID = raw["id"] as? String, !attachmentID.isEmpty,
                let assetType = raw["assetType"] as? String, !assetType.isEmpty,
                raw["isFullyRemoved"] as? Bool != true,
                raw["isUndoablyDeleted"] as? Bool != true
            else {
                return nil
            }

            let files = ((raw["fileAttachments"] as? [[String: Any]]) ?? [])
                .sorted { (($0["index"] as? Int) ?? 0) < (($1["index"] as? Int) ?? 0) }
                .compactMap { file -> JournalAttachmentFile? in
                    guard let fileID = file["id"] as? String, !fileID.isEmpty else {
                        return nil
                    }
                    return JournalAttachmentFile(
                        id: fileID,
                        name: file["name"] as? String ?? "",
                        relativePath: file["relativePath"] as? String ?? "",
                        absolutePath: file["absolutePath"] as? String ?? "",
                        exists: file["exists"] as? Bool ?? false,
                        byteLength: file["byteLength"] as? Int
                    )
                }

            let metadata = decodeAttachmentMetadata(raw["metadata"] as? [String: Any] ?? [:], assetType: assetType)
            return JournalGenericAttachment(
                id: attachmentID,
                assetType: assetType,
                source: raw["source"] as? String ?? "",
                isHidden: raw["isHidden"] as? Bool ?? false,
                isSlim: raw["isSlim"] as? Bool ?? false,
                createdDate: raw["createdDate"] as? String ?? "",
                suggestionDate: raw["suggestionDate"] as? String ?? "",
                files: files,
                metadata: JournalJSONValue(jsonObject: metadata) ?? .object([:])
            )
        }
    }

    /// Turns metadata blobs that only make sense to Apple frameworks into
    /// template-friendly values. Everything else passes through untouched.
    static func decodeAttachmentMetadata(_ metadata: [String: Any], assetType: String) -> [String: Any] {
        var result = metadata

        if assetType == "reflection" {
            if let prompt = result["prompt"] as? String, let text = decodeBase64RTF(prompt) {
                result["prompt"] = text
            }
            for key in ["colorLight", "colorDark"] {
                if let archive = result[key] as? String, let hex = decodeBase64ArchivedColor(archive) {
                    result[key] = hex
                }
            }
        }

        if assetType == "multiPinMap" || assetType == "genericMap" {
            // genericMap stores a single visit object; multiPinMap stores an
            // array. The archived MKMapItem blob is large and opaque; drop it.
            if let visits = result["visitsData"] as? [[String: Any]] {
                result["visitsData"] = visits.map { visit -> [String: Any] in
                    var cleaned = visit
                    cleaned.removeValue(forKey: "mapItemData")
                    return cleaned
                }
            } else if var visit = result["visitsData"] as? [String: Any] {
                visit.removeValue(forKey: "mapItemData")
                result["visitsData"] = visit
            }
        }

        return result
    }

    /// `NSAttributedString(rtf:)` comes from an AppKit category. UI-less
    /// binaries like the bridge agent never load AppKit on their own —
    /// category methods reference no linker symbol, so even `import AppKit`
    /// adds no load command — and calling the initializer then raises an
    /// uncatchable ObjC exception that crash-loops the agent. Load the
    /// framework by hand and verify the category arrived before using it.
    private static let rtfDecodingAvailable: Bool = {
        dlopen("/System/Library/Frameworks/AppKit.framework/AppKit", RTLD_LAZY)
        return NSAttributedString.instancesRespond(to: NSSelectorFromString("initWithRTF:documentAttributes:"))
    }()

    static func decodeBase64RTF(_ base64: String) -> String? {
        guard Self.rtfDecodingAvailable, let data = Data(base64Encoded: base64) else {
            return nil
        }
        let attributed = NSAttributedString(rtf: data, documentAttributes: nil)
        return attributed?.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func decodeBase64ArchivedColor(_ base64: String) -> String? {
        guard
            let data = Data(base64Encoded: base64),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let root = plist as? [String: Any],
            let objects = root["$objects"] as? [Any]
        else {
            return nil
        }

        for object in objects {
            guard let dictionary = object as? [String: Any] else {
                continue
            }
            let red = colorComponent(dictionary, doubleKey: "UIRed-Double", fallbackKey: "UIRed")
            let green = colorComponent(dictionary, doubleKey: "UIGreen-Double", fallbackKey: "UIGreen")
            let blue = colorComponent(dictionary, doubleKey: "UIBlue-Double", fallbackKey: "UIBlue")
            if let red, let green, let blue {
                return String(
                    format: "#%02X%02X%02X",
                    Int((red * 255).rounded()),
                    Int((green * 255).rounded()),
                    Int((blue * 255).rounded())
                )
            }
        }
        return nil
    }

    private static func colorComponent(_ dictionary: [String: Any], doubleKey: String, fallbackKey: String) -> Double? {
        let value = (dictionary[doubleKey] as? NSNumber) ?? (dictionary[fallbackKey] as? NSNumber)
        guard let component = value?.doubleValue, component >= 0, component <= 1 else {
            return nil
        }
        return component
    }

    public func resolveEntryID(_ selector: String) throws -> String {
        if selector.range(of: #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"#, options: .regularExpression) != nil {
            return selector.uppercased()
        }

        let needle = selector.lowercased()
        let matches = try list().filter { entry in
            entry.id.lowercased().hasPrefix(needle)
            || entry.title.lowercased() == needle
            || entry.title.lowercased().contains(needle)
        }

        guard let first = matches.first else {
            throw JournalTextToolError.selectorNotFound(selector)
        }

        guard matches.count == 1 else {
            throw JournalTextToolError.ambiguousSelector(selector, matches)
        }

        return first.id
    }

    public func runRaw(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.environment = Self.subprocessEnvironment(for: arguments)

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

    static func sanitizedSubprocessEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        environment.filter { key, _ in
            !isUnsafeSubprocessEnvironmentKey(key)
        }
    }

    static func subprocessEnvironment(
        for arguments: [String],
        base environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        var result = sanitizedSubprocessEnvironment(environment)
        if requiresRichTextConverter(arguments) {
            result["MARKWAY_JOURNAL_RICH_TEXT_REQUIRED"] = "1"
        }
        return result
    }

    private static func requiresRichTextConverter(_ arguments: [String]) -> Bool {
        guard let command = arguments.first else {
            return false
        }
        return command == "add" || command == "update"
    }

    private static func candidateURLs(from start: URL) -> [URL] {
        var candidates: [URL] = []
        for executableURL in currentExecutableURLs() {
            candidates.append(executableURL.deletingLastPathComponent().appendingPathComponent("journal_text"))
            candidates.append(executableURL.deletingLastPathComponent().appendingPathComponent("journal_text.zsh"))
        }
        for directory in ancestorDirectories(from: start) {
            candidates.append(directory.appendingPathComponent("Vendor/AppleJournalCRDT/tools/journal_text.zsh"))
            candidates.append(directory.appendingPathComponent("tools/journal_text.zsh"))
        }
        return candidates
    }

    private static func currentExecutableURLs() -> [URL] {
        var urls: [URL] = []

        if let argument = ProcessInfo.processInfo.arguments.first, !argument.isEmpty {
            urls.append(URL(fileURLWithPath: argument).standardizedFileURL)
        }

        let processPath = ProcessInfo.processInfo.processName
        if !processPath.isEmpty {
            urls.append(URL(fileURLWithPath: processPath).standardizedFileURL)
        }

        return urls
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

    private func parseListOutput(_ output: String) throws -> [JournalEntrySummary] {
        output.split(separator: "\n", omittingEmptySubsequences: true).map { line in
            let parts = line.split(separator: "\t", maxSplits: 4, omittingEmptySubsequences: false)
            let id = parts.indices.contains(0) ? String(parts[0]) : ""
            let status = parts.indices.contains(1) ? String(parts[1]) : ""
            let created = parts.indices.contains(2) ? String(parts[2]) : ""
            let updated = parts.indices.contains(4) ? String(parts[3]) : ""
            let titleIndex = parts.indices.contains(4) ? 4 : 3
            let title = parts.indices.contains(titleIndex) ? String(parts[titleIndex]) : ""
            return JournalEntrySummary(id: id, status: status, created: created, updated: updated, title: title)
        }
    }
}

private struct JournalAttachmentListPayload: Decodable {
    var attachments: [JournalAttachmentPayload]
}

private struct JournalAttachmentPayload: Decodable {
    var id: String
    var assetType: String?
    var source: String?
    var isHidden: Bool?
    var isSlim: Bool?
    var isFullyRemoved: Bool?
    var isUndoablyDeleted: Bool?
    var createdDate: String?
    var suggestionDate: String?
    var metadata: JournalAttachmentMetadataPayload?
    var fileAttachments: [JournalFileAttachmentPayload]?
}

private struct JournalAttachmentMetadataPayload: Decodable {
    var song: String?
    var artistName: String?
    var mediaId: String?
    var mediaType: [String: EmptyPayload]?
    var startTime: Double?
    var assetIdentifier: String?
    var date: Double?
}

private struct JournalFileAttachmentPayload: Decodable {
    var id: String?
    var name: String?
    var index: Int?
    var relativePath: String?
    var absolutePath: String?
    var exists: Bool?
    var byteLength: Int?
}

private struct EmptyPayload: Decodable {}

private func isUnsafeSubprocessEnvironmentKey(_ key: String) -> Bool {
    key.hasPrefix("DYLD_")
    || key.hasPrefix("__XPC_DYLD_")
    || key == "__XCODE_BUILT_PRODUCTS_DIR_PATHS"
    || key == "OS_ACTIVITY_DT_MODE"
}

private func isJournalPermissionFailure(_ text: String) -> Bool {
    text.contains("group.com.apple.moments")
    && (
        text.contains("Sandbox access to file-read-data denied")
        || text.contains("NSSQLiteErrorDomain : 23")
        || text.contains("moments.sqlite")
    )
}
