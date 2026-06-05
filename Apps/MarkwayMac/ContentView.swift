import MarkwayCore
import SwiftUI

struct ContentView: View {
    @State private var vaultPath = ""
    @State private var status = "Idle"

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
            }

            Text(status)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 260)
    }

    private func scan() {
        let path = vaultPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            status = "Choose a vault path."
            return
        }

        do {
            let engine = MarkwaySyncEngine(journal: NoopJournalBackend())
            let summary = try engine.scanVault(at: URL(fileURLWithPath: path))
            status = """
            markdown files: \(summary.markdownFiles)
            linked journal entries: \(summary.linkedJournalEntries)
            unlinked markdown files: \(summary.unlinkedMarkdownFiles)
            """
        } catch {
            status = String(describing: error)
        }
    }
}

private struct NoopJournalBackend: JournalBackend {
    func add(title: String, bodyFile: URL) throws -> String { "" }
    func update(id: String, title: String, bodyFile: URL) throws {}
    func get(id: String) throws -> JournalEntryText { JournalEntryText(id: id, title: "", body: "") }
    func runRaw(_ arguments: [String]) throws -> String { "" }
}
