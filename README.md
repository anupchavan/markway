# Markway

Markway is a gateway between Apple services and Markdown.

The project starts with Apple Journal and Obsidian: entries can be pushed from Markdown into Journal, pulled back into Markdown, and kept in sync through a small local bridge. The longer-term direction is broader than Obsidian or Journal: Markway is meant to help Apple services work with local, portable files.

## What This Repo Contains

This is the native macOS side of Markway:

- `Markway.app`, a SwiftUI macOS app for setup, background sync, logs, and updates.
- `markway`, a Swift command-line tool with Journal and Apple Music commands.
- `MarkwayCore`, the shared Swift sync engine used by the app and CLI.
- A bundled Apple Journal helper from `Vendor/AppleJournalCRDT/tools`.
- GitHub Actions release automation for Apple Silicon and Intel DMGs.

The Obsidian plugin lives in a separate repository:

```text
~/projects/obsidian-markway/.obsidian/plugins/obsidian-markway
```

The Apple Journal helper is developed separately at:

```text
~/projects/markway-journal-crdt
```

## Current Status

Markway is beta software. Apple Journal does not provide a public API, so the Journal support uses a reverse-engineered local store format and private system frameworks. Keep backups of your Journal data and Markdown vault while testing.

Currently supported:

- Create, read, update, and delete text Journal entries.
- Preserve common Markdown structure where Journal itself keeps enough information.
- Sync Journal entries with Markdown files through the Obsidian plugin.
- Run a private local file bridge between Obsidian and Markway.app.
- List/read selected Apple Music library data from local Music databases.
- Build signed/notarized release DMGs through GitHub Actions.

In progress:

- Richer Journal attachments: photos, videos, workouts, locations, moods, drawings, and recordings.
- Apple Music attachment editing from Markdown.
- More Apple services.

## Requirements

- macOS 14 or later.
- Xcode with command line tools.
- XcodeGen for app project generation.
- Apple Journal installed and available on the Mac.
- Full Disk Access for `Markway.app` when using Journal sync.
- Obsidian for the plugin workflow.

Install XcodeGen:

```zsh
brew install xcodegen
```

## Build The App

```zsh
cd ~/projects/markway
xcodegen generate
open Markway.xcodeproj
```

Build and run the `Markway` scheme from Xcode.

On first setup:

1. Open Markway.app.
2. Choose your Obsidian vault.
3. Grant Full Disk Access to Markway.app in System Settings.
4. Reopen Markway.app if macOS asks you to quit it.

Markway installs a user LaunchAgent for background bridge processing:

```text
~/Library/LaunchAgents/com.anupchavan.markway.agent.plist
```

Bridge logs are written to:

```text
~/Library/Logs/Markway/agent.log
~/Library/Logs/Markway/agent.err
```

## CLI

From the repo:

```zsh
swift run markway
```

Or build/install the launcher:

```zsh
Scripts/install_cli_launcher.zsh
```

Useful commands:

```zsh
markway journal:entries
markway journal:entry path="Journal/Today.md"
markway journal:read path="Journal/Today.md"
markway journal:push file="Journal/Today.md"
markway journal:pull id=ENTRY_ID out="Journal/Entry.md"

markway music:songs limit=20
markway music:song title="Sahiba"
markway music:albums artist="A. R. Rahman"
markway music:album album="Rockstar"
markway music:search query="Sahiba"
```

Broad Music list commands show 20 rows by default; use `limit=all` when you explicitly want exhaustive output.

Run `markway` with no arguments for the TUI-style prompt.

## Architecture

The Obsidian plugin does not receive Full Disk Access. Instead:

1. The plugin writes private JSON requests into `~/Library/Application Support/Markway/Bridge/<vault-hash>`.
2. Markway.app or its LaunchAgent reads those requests.
3. The native Markway helper performs Apple Journal operations with the app's permissions.
4. Responses and private events flow back through the same local bridge.

This avoids granting Obsidian or arbitrary Obsidian plugins broad access to Apple service stores.

## Development

Run the Swift test suite:

```zsh
swift test
```

Run the app target build:

```zsh
xcodebuild -scheme Markway -configuration Debug -destination 'platform=macOS' build
```

Regenerate the Xcode project after changing `project.yml`:

```zsh
xcodegen generate
```

## Release

The release workflow is in:

```text
.github/workflows/release.yml
```

It builds two draft DMG artifacts:

- `Markway-vX.Y.Z-arm64.dmg`
- `Markway-vX.Y.Z-x86_64.dmg`

Release details and required GitHub secrets are documented in:

```text
Docs/RELEASE.md
```

Short version:

```zsh
git tag v0.1.0
git push origin v0.1.0
```

For public distribution, configure Developer ID signing and notarization secrets before publishing the draft release.

## What To Commit

Commit:

- `Apps`
- `Docs`
- `Scripts`
- `Sources`
- `Tests`
- `Vendor/AppleJournalCRDT/tools`
- `.github`
- `.gitignore`
- `Package.swift`
- `Package.resolved`
- `project.yml`
- `README.md`
- `TODO.md`

Do not commit generated output:

- `.build`
- `build`
- `dist`
- `DerivedData`
- `xcuserdata`
- `Vendor/AppleJournalCRDT/.build`

## Disclaimer

Markway is not affiliated with Apple or Obsidian. Apple Journal support relies on private implementation details that may change in future macOS releases.
