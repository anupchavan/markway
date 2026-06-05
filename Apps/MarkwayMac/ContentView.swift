import MarkwayCore
import AppKit
import SwiftUI

struct ContentView: View {
    @State private var vaultPath = UserDefaults.standard.string(forKey: "vaultPath") ?? ""
    @State private var bridgeStatus = "Bridge stopped."
    @State private var message = "Idle"
    @State private var bridgeTimer: Timer?
    @State private var isProcessingBridge = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Markway")
                .font(.largeTitle.bold())

            HStack {
                TextField("Markdown vault", text: $vaultPath)
                    .textFieldStyle(.roundedBorder)
                Button("Scan") {
                    scan()
                }
                .keyboardShortcut(.defaultAction)
                Button(bridgeTimer == nil ? "Start bridge" : "Stop bridge") {
                    toggleBridge()
                }
            }

            HStack {
                Button("Check Journal Access") {
                    checkJournalAccess()
                }

                Button("Open Full Disk Access") {
                    openFullDiskAccessSettings()
                }

                Button("Reveal Markway.app") {
                    revealMarkwayApp()
                }

                Button("Reveal Journal helper") {
                    revealJournalHelper()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(bridgeStatus)
                Text(message)
            }
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 260)
        .onDisappear {
            bridgeTimer?.invalidate()
            bridgeTimer = nil
        }
    }

    private func scan() {
        guard let vaultURL else {
            message = "Choose a vault path."
            return
        }
        UserDefaults.standard.set(vaultURL.path, forKey: "vaultPath")

        do {
            let engine = MarkwaySyncEngine(journal: NoopJournalBackend())
            let summary = try engine.scanVault(at: vaultURL)
            message = """
            markdown files: \(summary.markdownFiles)
            linked journal entries: \(summary.linkedJournalEntries)
            unlinked markdown files: \(summary.unlinkedMarkdownFiles)
            """
        } catch {
            message = String(describing: error)
        }
    }

    private func toggleBridge() {
        if let timer = bridgeTimer {
            timer.invalidate()
            bridgeTimer = nil
            bridgeStatus = "Bridge stopped."
            return
        }

        guard let vaultURL else {
            message = "Choose a vault path."
            return
        }

        UserDefaults.standard.set(vaultURL.path, forKey: "vaultPath")
        processBridge(vaultURL: vaultURL)
        bridgeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                processBridge(vaultURL: vaultURL)
            }
        }
        bridgeStatus = "Bridge started: \(vaultURL.appendingPathComponent(".markway").path)"
    }

    private func processBridge(vaultURL: URL) {
        guard !isProcessingBridge else {
            return
        }

        isProcessingBridge = true
        defer { isProcessingBridge = false }

        do {
            guard let journal = journalTool() else {
                message = "Bundled Journal helper not found. Rebuild Markway.app."
                return
            }

            let bridge = MarkwayFileBridge(vaultURL: vaultURL, journal: journal)
            let responses = try bridge.processPendingRequests()
            if responses.isEmpty {
                bridgeStatus = "Bridge running: \(vaultURL.appendingPathComponent(".markway").path)"
            } else {
                let successes = responses.filter(\.ok).count
                message = "Processed \(responses.count) request(s), \(successes) ok."
            }
        } catch {
            message = String(describing: error)
        }
    }

    private func checkJournalAccess() {
        do {
            guard let journal = journalTool() else {
                message = "Bundled Journal helper not found. Rebuild Markway.app."
                return
            }

            _ = try journal.runRaw(["sync-status"])
            message = "Journal access OK."
        } catch {
            message = String(describing: error)
        }
    }

    private func openFullDiskAccessSettings() {
        let settingsURLs = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
        ]

        for urlString in settingsURLs {
            guard let url = URL(string: urlString) else {
                continue
            }

            if NSWorkspace.shared.open(url) {
                message = "Opened Full Disk Access. Enable Markway.app, then fully quit and reopen Markway.app."
                return
            }
        }

        message = "Could not open Full Disk Access. Open System Settings > Privacy & Security > Full Disk Access."
    }

    private func revealMarkwayApp() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
        message = "Revealed Markway.app. In Full Disk Access, use + and select this app if it is not listed."
    }

    private func revealJournalHelper() {
        let helperURL = journalHelperURL
        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            message = "Bundled Journal helper not found. Rebuild Markway.app."
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([helperURL])
        message = "Revealed journal_text. If Journal access still fails after enabling Markway.app, add this helper to Full Disk Access too."
    }

    private var vaultURL: URL? {
        let path = vaultPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    private func journalTool() -> JournalTextTool? {
        let bundledHelper = journalHelperURL

        if FileManager.default.isExecutableFile(atPath: bundledHelper.path) {
            return JournalTextTool(executableURL: bundledHelper)
        }

        return nil
    }

    private var journalHelperURL: URL {
        Bundle.main.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Helpers")
            .appendingPathComponent("journal_text")
    }
}

private struct NoopJournalBackend: JournalBackend {
    func list() throws -> [JournalEntrySummary] { [] }
    func add(title: String, bodyFile: URL) throws -> String { "" }
    func update(id: String, title: String, bodyFile: URL) throws {}
    func get(id: String) throws -> JournalEntryText { JournalEntryText(id: id, title: "", body: "") }
    func runRaw(_ arguments: [String]) throws -> String { "" }
}
