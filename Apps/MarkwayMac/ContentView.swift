import AppKit
import MarkwayCore
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: MarkwaySection? = .general
    @State private var vaultPath = UserDefaults.standard.string(forKey: "vaultPath") ?? ""
    @State private var status = "Choose your Markdown vault to enable background sync."
    @State private var detail = ""
    @State private var logText = MarkwayLogReader.journalLogTail()
    @State private var isConfiguring = false
    @State private var journalAccess: JournalAccessState = .checking

    var body: some View {
        NavigationSplitView {
            MarkwaySidebar(selectedSection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 210)
        } detail: {
            ZStack(alignment: .topLeading) {
                MarkwayTheme.windowBackground(colorScheme)
                    .ignoresSafeArea()
                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .toolbar {
                if activeSection == .journal {
                    ToolbarItem {
                        Button(action: refreshLogs) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 820, minHeight: 520)
        .onChange(of: selectedSection) { _, newValue in
            if newValue == .journal {
                refreshLogs()
            }
        }
        .onAppear {
            installCommandLineTool()
            updateJournalAccessState()
            configureFromCurrentVaultPathIfPresent()
            refreshLogs()
        }
    }

    private var activeSection: MarkwaySection {
        selectedSection ?? .general
    }

    @ViewBuilder
    private var detailView: some View {
        switch activeSection {
        case .general:
            GeneralPage(
                vaultPath: $vaultPath,
                status: status,
                detail: detail,
                statusSymbolName: statusSymbolName,
                statusIsError: statusIsError,
                journalAccess: journalAccess,
                isConfiguring: isConfiguring,
                chooseVault: chooseVault,
                configureVault: configureFromCurrentVaultPath,
                openFullDiskAccess: openFullDiskAccess,
                refreshJournalAccess: refreshJournalAccess
            )
        case .journal:
            JournalPage(logText: logText)
        case .music:
            MusicPage()
        }
    }

    private var statusIsError: Bool {
        if case .denied = journalAccess, vaultURL != nil {
            return true
        }
        return detail.hasPrefix("Error:")
    }

    private var statusSymbolName: String {
        if statusIsError {
            return "exclamationmark.triangle.fill"
        }
        if vaultURL != nil {
            return "checkmark.circle.fill"
        }
        return "circle"
    }

    private var vaultURL: URL? {
        let path = vaultPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL
    }

    private func refreshLogs() {
        logText = MarkwayLogReader.journalLogTail()
    }

    private func configureFromCurrentVaultPathIfPresent() {
        guard vaultURL != nil else {
            return
        }
        configureFromCurrentVaultPath()
    }

    private func configureFromCurrentVaultPath() {
        guard let vaultURL else {
            status = "Choose your Markdown vault to enable background sync."
            detail = ""
            return
        }

        isConfiguring = true
        status = "Configuring background sync..."
        detail = ""

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result {
                let access = JournalAccessChecker.check()
                guard access.isGranted else {
                    throw ValidationError(access.denialMessage ?? "Markway needs Full Disk Access to read Apple Journal.")
                }

                try validateVault(vaultURL)
                UserDefaults.standard.set(vaultURL.path, forKey: "vaultPath")

                let bridge = MarkwayFileBridge(vaultURL: vaultURL, journal: NoopJournalBackend())
                _ = try bridge.prepare()

                let controller = LaunchAgentController(bundleURL: Bundle.main.bundleURL)
                try controller.installAndLoad(vaultURL: vaultURL)
            }

            DispatchQueue.main.async {
                isConfiguring = false
                switch result {
                case .success:
                    journalAccess = .granted
                    vaultPath = vaultURL.path
                    status = "Background sync is ready."
                    detail = ""
                    refreshLogs()
                case .failure(let error):
                    status = "Background sync needs attention."
                    detail = "Error: \(error)"
                    journalAccess = JournalAccessChecker.check()
                }
            }
        }
    }

    private func refreshJournalAccess() {
        let access = updateJournalAccessState()
        if access.isGranted,
           vaultURL != nil,
           status != "Background sync is ready.",
           !isConfiguring {
            configureFromCurrentVaultPath()
        }
    }

    @discardableResult
    private func updateJournalAccessState() -> JournalAccessState {
        let access = JournalAccessChecker.check()
        journalAccess = access
        return access
    }

    private func openFullDiskAccess() {
        JournalAccessChecker.openFullDiskAccessSettings()
        refreshJournalAccess()
    }

    private func installCommandLineTool() {
        DispatchQueue.global(qos: .utility).async {
            _ = CommandLineToolInstaller.installBundledCLI()
        }
    }

    private func chooseVault() {
        let panel = NSOpenPanel()
        panel.title = "Choose Markdown vault"
        panel.prompt = "Choose"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = vaultURL ?? FileManager.default.homeDirectoryForCurrentUser

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        vaultPath = url.standardizedFileURL.path
        configureFromCurrentVaultPath()
    }
}

private func validateVault(_ url: URL) throws {
    var isDirectory = ObjCBool(false)
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
          isDirectory.boolValue else {
        throw CocoaError(.fileNoSuchFile)
    }
    guard FileManager.default.directoryExists(at: url.appendingPathComponent(".obsidian", isDirectory: true)) else {
        throw ValidationError("That folder is not an Obsidian vault.")
    }
}
