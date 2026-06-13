import Foundation

public enum MarkwayVaultPath {
    public static func url(from rawPath: String) -> URL? {
        let path = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL
    }

    public static func isDirectory(_ url: URL, fileManager: FileManager = .default) -> Bool {
        var isDirectory = ObjCBool(false)
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    public static func isObsidianVault(_ url: URL, fileManager: FileManager = .default) -> Bool {
        isDirectory(url, fileManager: fileManager)
            && isDirectory(url.appendingPathComponent(".obsidian", isDirectory: true), fileManager: fileManager)
    }
}
