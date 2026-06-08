import Foundation

enum CommandLineToolInstallResult: Equatable {
    case installed(URL)
    case skipped(String)
}

enum CommandLineToolInstaller {
    static func installBundledCLI(bundleURL: URL = Bundle.main.bundleURL) -> CommandLineToolInstallResult {
        let helperURL = bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("markway")

        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            return .skipped("Bundled markway helper was not found.")
        }

        var blockedLaunchers: [String] = []
        for binDirectory in writableBinDirectories() {
            do {
                try FileManager.default.createDirectory(at: binDirectory, withIntermediateDirectories: true)
                let launcherURL = binDirectory.appendingPathComponent("markway")
                guard canReplaceLauncher(at: launcherURL) else {
                    blockedLaunchers.append(launcherURL.path)
                    continue
                }
                if isSymbolicLink(launcherURL) {
                    try FileManager.default.removeItem(at: launcherURL)
                }
                try launcherScript(bundleURL: bundleURL).write(to: launcherURL, atomically: true, encoding: .utf8)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcherURL.path)
                return .installed(launcherURL)
            } catch {
                blockedLaunchers.append("\(binDirectory.path): \(error.localizedDescription)")
            }
        }

        return .skipped(blockedLaunchers.isEmpty ? "No writable command directory was found." : blockedLaunchers.joined(separator: "; "))
    }

    private static func writableBinDirectories() -> [URL] {
        let fileManager = FileManager.default
        let candidates = [
            URL(fileURLWithPath: "/opt/homebrew/bin", isDirectory: true),
            URL(fileURLWithPath: "/usr/local/bin", isDirectory: true)
        ]

        var writable = candidates.filter { url in
            fileManager.fileExists(atPath: url.path) && fileManager.isWritableFile(atPath: url.path)
        }

        let localBin = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".local", isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
        if fileManager.fileExists(atPath: localBin.path) {
            if fileManager.isWritableFile(atPath: localBin.path) {
                writable.append(localBin)
            }
        } else if fileManager.isWritableFile(atPath: fileManager.homeDirectoryForCurrentUser.path) {
            writable.append(localBin)
        }
        return writable
    }

    private static func canReplaceLauncher(at url: URL) -> Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            return true
        }

        if isSymbolicLink(url) {
            guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path) else {
                return false
            }
            return destination.contains("Markway.app/Contents/Helpers/markway")
                || destination.contains("/markway/.build/")
        }

        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return false
        }
        return contents.contains("MARKWAY_APP_CLI_LAUNCHER")
    }

    private static func launcherScript(bundleURL: URL) -> String {
        var candidates: [String] = []
        if !bundleURL.path.hasPrefix("/Volumes/"),
           bundleURL.path.contains("/Applications/") {
            candidates.append(bundleURL.appendingPathComponent("Contents/Helpers/markway").path)
        }
        candidates.append(#""$HOME/Applications/Markway.app/Contents/Helpers/markway""#)
        candidates.append("/Applications/Markway.app/Contents/Helpers/markway")

        let staticCandidates = candidates
            .map { value in
                value.hasPrefix(#""$HOME"#) ? "  \(value)" : "  \(zshQuoted(value))"
            }
            .joined(separator: "\n")

        return """
        #!/bin/zsh
        # MARKWAY_APP_CLI_LAUNCHER
        set -euo pipefail

        candidates=(
        \(staticCandidates)
        )

        if (( $+commands[mdfind] )); then
          while IFS= read -r app; do
            candidates+=("$app/Contents/Helpers/markway")
          done < <(/usr/bin/mdfind "kMDItemCFBundleIdentifier == 'com.anupchavan.markway'" 2>/dev/null)
        fi

        for candidate in "${candidates[@]}"; do
          if [[ -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
            exec "$candidate" "$@"
          fi
        done

        print -u2 "markway CLI not found. Install Markway.app in Applications, then reopen it."
        exit 127
        """
    }

    private static func zshQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
    }
}
