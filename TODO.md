# Markway TODO

## CLI and TUI

- Build a real terminal UI with command autocomplete, history, reverse search, and fuzzy pickers.
- Add interactive entry and attachment selection so UUIDs are rarely typed manually.
- Support Obsidian-style `key=value` parameters consistently across every command.
- Add machine-readable output formats such as `format=json`, `format=tsv`, and `--copy`.

## Sync Engine

- Add a durable local state database for file paths, Journal IDs, content hashes, and sync revisions.
- Implement conflict detection before automatic writes.
- Route Obsidian-open file edits through the plugin and background file edits through the native engine.

## Apple Journal

- Move the vendored Journal CRDT bridge behind a proper library boundary.
- Add selectors for attachment commands.
- Continue decoding unsupported attachment types such as moods, workouts, audio, drawings, podcasts, and locations.

## Obsidian Plugin

- Replace command-only integration with a narrow event/IPC channel to the native engine.
- Surface sync status per file and vault.
- Add permission diagnostics for Full Disk Access and Journal helper access.
