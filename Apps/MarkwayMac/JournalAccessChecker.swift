import AppKit
import Foundation

enum JournalAccessState: Equatable {
    case checking
    case granted
    case denied(String)

    var isGranted: Bool {
        if case .granted = self {
            return true
        }
        return false
    }

    var denialMessage: String? {
        if case .denied(let message) = self {
            return message
        }
        return nil
    }
}

enum JournalAccessChecker {
    static func check() -> JournalAccessState {
        let fileManager = FileManager.default
        let libraryURL = journalLibraryURL
        let databaseURL = libraryURL.appendingPathComponent("moments.sqlite")

        var isDirectory = ObjCBool(false)
        if !fileManager.fileExists(atPath: libraryURL.path, isDirectory: &isDirectory) {
            return .denied("Apple Journal's local store was not found. Open Journal once, then check again.")
        }

        do {
            if fileManager.fileExists(atPath: databaseURL.path) {
                let handle = try FileHandle(forReadingFrom: databaseURL)
                try handle.close()
            } else {
                _ = try fileManager.contentsOfDirectory(
                    at: libraryURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
            }
            return .granted
        } catch {
            return .denied("Markway needs Full Disk Access to read Apple Journal.")
        }
    }

    static func openFullDiskAccessSettings() {
        _ = check()

        let settingsURLs = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        ]

        for value in settingsURLs {
            guard let url = URL(string: value) else {
                continue
            }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private static var journalLibraryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Group Containers", isDirectory: true)
            .appendingPathComponent("group.com.apple.moments", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
    }
}
