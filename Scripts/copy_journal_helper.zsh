#!/bin/zsh
set -euo pipefail

repo="${0:A:h:h}"
helper_script="$repo/Vendor/AppleJournalCRDT/tools/journal_text.zsh"
helper_build_dir="$repo/Vendor/AppleJournalCRDT/.build"
swift_config="debug"

if [[ "${CONFIGURATION:l}" == "release" ]]; then
  swift_config="release"
fi

JOURNAL_TEXT_ALLOW_MISSING_CONVERTER=1 JOURNAL_TEXT_BUILD_ONLY=1 "$helper_script" >/dev/null
swift build --package-path "$repo" -c "$swift_config" --product markway >/dev/null

if [[ -z "${TARGET_BUILD_DIR:-}" || -z "${CONTENTS_FOLDER_PATH:-}" ]]; then
  print -u2 "TARGET_BUILD_DIR and CONTENTS_FOLDER_PATH are required"
  exit 1
fi

helpers_dir="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers"
mkdir -p "$helpers_dir"

cp -f "$helper_build_dir/journal_text" "$helpers_dir/journal_text"
cp -f "$repo/.build/$swift_config/markway" "$helpers_dir/markway"
chmod +x "$helpers_dir/journal_text" "$helpers_dir/markway"

if [[ -f "$helper_build_dir/JournalShareExtension_as_bundle" ]]; then
  cp -f "$helper_build_dir/JournalShareExtension_as_bundle" "$helpers_dir/JournalShareExtension_as_bundle"
  chmod +x "$helpers_dir/JournalShareExtension_as_bundle"
fi

if [[ "${CODE_SIGNING_ALLOWED:-}" != "NO" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]]; then
  if [[ -f "$helpers_dir/JournalShareExtension_as_bundle" ]]; then
    codesign --force --timestamp=none --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$helpers_dir/JournalShareExtension_as_bundle"
  fi
  codesign --force --timestamp=none --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$helpers_dir/journal_text"
  codesign --force --timestamp=none --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$helpers_dir/markway"
fi
