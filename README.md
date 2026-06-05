# Markway

Markway is a gateway between Apple services and Markdown.

This repository contains the native macOS engine, the `markway` CLI, and the Mac app. The Obsidian adapter lives separately at:

`~/projects/obsidian-markway/.obsidian/plugins/obsidian-markway`

The current Apple Journal CRDT bridge is vendored from:

`~/projects/markway-journal-crdt`

## CLI

```zsh
swift run markway doctor
swift run markway sync init --vault /path/to/vault
swift run markway sync once --vault /path/to/vault
swift run markway journal push Entry.md --title "Entry title"
swift run markway journal pull ENTRY-UUID --out Entry.md
swift run markway journal raw -- attachments list ENTRY-UUID
```

Shell completions:

```zsh
swift run markway --generate-completion-script zsh > ~/.zfunc/_markway
```

## App

```zsh
xcodegen generate
open Markway.xcodeproj
```

## Tests

```zsh
Scripts/test.zsh
```
