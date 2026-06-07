# Markway TODO

## CLI and TUI

- Keep polishing the terminal UI after the first Obsidian-style pass.
- Add reverse search and fuzzy pickers.
- Add interactive entry and attachment selection so UUIDs are rarely typed manually.
- Support Obsidian-style `key=value` parameters consistently across every command.
- Add machine-readable output formats such as `format=json`, `format=tsv`, and `--copy`.
- Done: root Journal commands now use `journal:*`, synced Journal files resolve through plugin `data.json`, and the TUI supports Obsidian-style suggestion selection plus word deletion.
- Done: root Apple Music commands now use `music:*` for songs, song info, albums, album info, and cached catalog search.

## Sync Engine

- Add a durable local state database for file paths, Journal IDs, content hashes, and sync revisions.
- Implement conflict detection before automatic writes.
- Route Obsidian-open file edits through the plugin and background file edits through the native engine.

## Apple Journal

- Move the vendored Journal CRDT bridge behind a proper library boundary.
- Add selectors for attachment commands.
- Continue decoding unsupported attachment types such as moods, workouts, audio, drawings, podcasts, and locations.

## Apple Music

- Current library prototype uses Music.app automation because `Library.musicdb` is Apple's binary `hfma` format, not SQLite.
- Decode `Library.musicdb` directly or add a cached local index so exhaustive `music:* limit=all` commands do not need slow Music.app automation scans.
- Decide whether Markway should support online MusicKit search in addition to local library reads.

## Obsidian Plugin

- Replace command-only integration with a narrow event/IPC channel to the native engine.
- Surface sync status per file and vault.
- Add permission diagnostics for Full Disk Access and Journal helper access.
