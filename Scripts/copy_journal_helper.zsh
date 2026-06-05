#!/bin/zsh
set -euo pipefail

repo="${0:A:h:h}"
helper_script="$repo/Vendor/AppleJournalCRDT/tools/journal_text.zsh"
helper_build_dir="$repo/Vendor/AppleJournalCRDT/.build"

JOURNAL_TEXT_BUILD_ONLY=1 "$helper_script" >/dev/null

if [[ -z "${TARGET_BUILD_DIR:-}" || -z "${CONTENTS_FOLDER_PATH:-}" ]]; then
  print -u2 "TARGET_BUILD_DIR and CONTENTS_FOLDER_PATH are required"
  exit 1
fi

helpers_dir="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers"
mkdir -p "$helpers_dir"

cp -f "$helper_build_dir/journal_text" "$helpers_dir/journal_text"
cp -f "$helper_build_dir/JournalShareExtension_as_bundle" "$helpers_dir/JournalShareExtension_as_bundle"
chmod +x "$helpers_dir/journal_text" "$helpers_dir/JournalShareExtension_as_bundle"
