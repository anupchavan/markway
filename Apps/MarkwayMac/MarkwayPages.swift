import SwiftUI

struct GeneralPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var vaultPath: String
    let status: String
    let detail: String
    let statusSymbolName: String
    let statusIsError: Bool
    let journalAccess: JournalAccessState
    let isConfiguring: Bool
    var chooseVault: () -> Void
    var configureVault: () -> Void
    var openFullDiskAccess: () -> Void
    var refreshJournalAccess: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                MarkwayHeader(
                    title: "General",
                    subtitle: "Connect your vault and keep the background bridge ready."
                )
                vaultPanel
                if journalAccess.denialMessage != nil {
                    journalAccessPanel
                } else {
                    statusPanel
                }
            }
            .padding(34)
            .frame(maxWidth: 760, alignment: .leading)
        }
    }

    private var vaultPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Markdown vault", systemImage: "externaldrive.connected.to.line.below")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("Choose an Obsidian vault", text: $vaultPath)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .onSubmit(configureVault)

                Button(action: chooseVault) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(MarkwayTheme.accent(colorScheme))
                .background(.regularMaterial, in: Circle())
                .help("Choose vault")
            }
        }
        .padding(22)
        .glassPanel()
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                if isConfiguring {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: statusSymbolName)
                        .foregroundStyle(statusIsError ? .orange : MarkwayTheme.accent(colorScheme))
                }
                Text(status)
                    .font(.callout)
            }

            if !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var journalAccessPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.orange)
                Text("Apple Journal access is needed.")
                    .font(.callout)
            }

            if let message = journalAccess.denialMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button("Open Full Disk Access", action: openFullDiskAccess)
                    .buttonStyle(.borderedProminent)
                Button("Check Again", action: refreshJournalAccess)
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct JournalPage: View {
    let logText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarkwayHeader(title: "Journal", subtitle: "Background bridge logs for Apple Journal sync.")

            ScrollView {
                Text(logText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassPanel()
        }
        .padding(34)
    }
}

struct MusicPage: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MarkwayHeader(title: "Music", subtitle: "Apple Music integrations are coming soon.")

            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(MarkwayTheme.accent(colorScheme))
                Text("Coming soon")
                    .font(.title2.weight(.semibold))
                Text("This space will hold Apple Music library tools and Journal music attachment controls.")
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 520, alignment: .leading)
            .glassPanel()

            Spacer()
        }
        .padding(34)
    }
}

struct MarkwayHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
