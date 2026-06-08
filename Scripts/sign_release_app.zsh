#!/bin/zsh
set -euo pipefail

app_path=""
identity=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      app_path="${2:-}"
      shift 2
      ;;
    --identity)
      identity="${2:-}"
      shift 2
      ;;
    -h|--help)
      print "Usage: sign_release_app.zsh --app /path/to/Markway.app --identity 'Developer ID Application: ...'"
      exit 0
      ;;
    *)
      print -u2 "Unknown argument: $1"
      exit 2
      ;;
  esac
done

if [[ -z "$app_path" || -z "$identity" ]]; then
  print -u2 "Usage: sign_release_app.zsh --app /path/to/Markway.app --identity 'Developer ID Application: ...'"
  exit 2
fi

if [[ ! -d "$app_path" ]]; then
  print -u2 "App bundle not found: $app_path"
  exit 1
fi

sign_existing() {
  local target="$1"
  shift
  if [[ -e "$target" ]]; then
    codesign --force --options runtime --timestamp --sign "$identity" "$@" "$target"
  fi
}

sparkle="$app_path/Contents/Frameworks/Sparkle.framework"
sparkle_version="$sparkle/Versions/B"

if [[ -d "$sparkle_version" ]]; then
  sign_existing "$sparkle_version/XPCServices/Downloader.xpc" --preserve-metadata=identifier,entitlements
  sign_existing "$sparkle_version/XPCServices/Installer.xpc" --preserve-metadata=identifier,entitlements
  sign_existing "$sparkle_version/Updater.app" --preserve-metadata=identifier,entitlements
  sign_existing "$sparkle_version/Autoupdate" --preserve-metadata=identifier,entitlements
  sign_existing "$sparkle" --preserve-metadata=identifier,entitlements
fi

helpers_dir="$app_path/Contents/Helpers"
if [[ -d "$helpers_dir" ]]; then
  for helper in "$helpers_dir"/*(.N); do
    sign_existing "$helper"
  done
fi

codesign --force --options runtime --timestamp --sign "$identity" "$app_path"

entitlements_file="$(mktemp)"
trap 'rm -f "$entitlements_file"' EXIT
codesign -d --entitlements :- "$app_path" >"$entitlements_file" 2>/dev/null || true
if grep -q "com.apple.security.get-task-allow" "$entitlements_file"; then
  print -u2 "Release app still has com.apple.security.get-task-allow entitlement"
  exit 1
fi

codesign --verify --deep --strict --verbose=4 "$app_path"
