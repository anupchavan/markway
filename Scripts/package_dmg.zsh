#!/bin/zsh
set -euo pipefail

app_path=""
output_path=""
volume_name="Markway"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      app_path="${2:-}"
      shift 2
      ;;
    --out)
      output_path="${2:-}"
      shift 2
      ;;
    --volume-name)
      volume_name="${2:-}"
      shift 2
      ;;
    -h|--help)
      print "Usage: package_dmg.zsh --app /path/to/Markway.app --out Markway.dmg [--volume-name Markway]"
      exit 0
      ;;
    *)
      print -u2 "Unknown argument: $1"
      exit 2
      ;;
  esac
done

if [[ -z "$app_path" || -z "$output_path" ]]; then
  print -u2 "Usage: package_dmg.zsh --app /path/to/Markway.app --out Markway.dmg [--volume-name Markway]"
  exit 2
fi

if [[ ! -d "$app_path" ]]; then
  print -u2 "App bundle not found: $app_path"
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp -R "$app_path" "$tmp_dir/Markway.app"
ln -s /Applications "$tmp_dir/Applications"
mkdir -p "${output_path:h}"

hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$tmp_dir" \
  -ov \
  -format UDZO \
  "$output_path"
