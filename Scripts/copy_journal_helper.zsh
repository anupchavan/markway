#!/bin/zsh
set -euo pipefail

repo="${0:A:h:h}"
helper_script="$repo/Vendor/AppleJournalCRDT/tools/journal_text.zsh"
helper_build_dir="$repo/Vendor/AppleJournalCRDT/.build"
helper_prebuilt_dir="$repo/Vendor/AppleJournalCRDT/prebuilt"
swift_config="debug"

if [[ "${CONFIGURATION:l}" == "release" ]]; then
  swift_config="release"
fi

helper_arch="${ARCHS:-}"
helper_arch="${helper_arch%% *}"
if [[ -z "$helper_arch" || "$helper_arch" == "undefined_arch" ]]; then
  helper_arch="$(uname -m)"
fi
helper_binary="$helper_build_dir/journal_text"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"

if [[ "${MARKWAY_USE_PREBUILT_JOURNAL_HELPER:-}" == "1" ]]; then
  prebuilt_helper="$helper_prebuilt_dir/journal_text-$helper_arch"
  if [[ ! -x "$prebuilt_helper" ]]; then
    print -u2 "Missing prebuilt Journal helper for architecture: $helper_arch"
    print -u2 "Expected: $prebuilt_helper"
    exit 1
  fi
  helper_binary="$prebuilt_helper"
elif [[ -d "$sdk_path/System/Library/PrivateFrameworks/JournalShared.framework" && -d "$sdk_path/System/Library/PrivateFrameworks/Coherence.framework" ]]; then
  JOURNAL_TEXT_ARCH="$helper_arch" JOURNAL_TEXT_ALLOW_MISSING_CONVERTER=1 JOURNAL_TEXT_BUILD_ONLY=1 "$helper_script" >/dev/null
else
  prebuilt_helper="$helper_prebuilt_dir/journal_text-$helper_arch"
  if [[ ! -x "$prebuilt_helper" ]]; then
    print -u2 "Journal helper cannot be built because this Xcode SDK does not include JournalShared.framework."
    print -u2 "Missing prebuilt helper for architecture: $helper_arch"
    print -u2 "Expected: $prebuilt_helper"
    exit 1
  fi
  helper_binary="$prebuilt_helper"
fi

swift build --package-path "$repo" -c "$swift_config" --product markway >/dev/null

if [[ -z "${TARGET_BUILD_DIR:-}" || -z "${CONTENTS_FOLDER_PATH:-}" ]]; then
  print -u2 "TARGET_BUILD_DIR and CONTENTS_FOLDER_PATH are required"
  exit 1
fi

helpers_dir="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers"
mkdir -p "$helpers_dir"

cp -f "$helper_binary" "$helpers_dir/journal_text"
cp -f "$repo/.build/$swift_config/markway" "$helpers_dir/markway"
chmod +x "$helpers_dir/journal_text" "$helpers_dir/markway"

if [[ "${MARKWAY_BUNDLE_JOURNAL_CONVERTER:-}" == "1" && -f "$helper_build_dir/JournalShareExtension_as_bundle" ]]; then
  cp -f "$helper_build_dir/JournalShareExtension_as_bundle" "$helpers_dir/JournalShareExtension_as_bundle"
  chmod +x "$helpers_dir/JournalShareExtension_as_bundle"
fi

if [[ "${CODE_SIGNING_ALLOWED:-}" != "NO" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]]; then
  if [[ -f "$helpers_dir/JournalShareExtension_as_bundle" ]]; then
    codesign --force --options runtime --timestamp --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$helpers_dir/JournalShareExtension_as_bundle"
  fi
  codesign --force --options runtime --timestamp --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$helpers_dir/journal_text"
  codesign --force --options runtime --timestamp --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$helpers_dir/markway"
fi
