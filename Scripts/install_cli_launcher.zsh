#!/bin/zsh
set -euo pipefail

repo="${0:A:h:h}"
bin_dir="${MARKWAY_BIN_DIR:-$HOME/.local/bin}"
launcher="$bin_dir/markway"
explicit_app="${1:-}"

quote_zsh() {
  local value="$1"
  print -r -- "'${value//\'/\'\\\'\'}'"
}

current_cli_candidates=()
if [[ -n "$explicit_app" ]]; then
  current_cli_candidates+=("$explicit_app/Contents/Helpers/markway")
fi
current_cli_candidates+=(
  "$HOME/Applications/Markway.app/Contents/Helpers/markway"
  "/Applications/Markway.app/Contents/Helpers/markway"
  "$repo/.build/debug/markway"
  "$repo/.build/release/markway"
)

preferred_cli=""
for candidate in "${current_cli_candidates[@]}"; do
  if [[ -x "$candidate" ]]; then
    preferred_cli="$candidate"
    break
  fi
done

mkdir -p "$bin_dir"
tmp="$(mktemp "$bin_dir/markway.XXXXXX")"

{
  print '#!/bin/zsh'
  print 'set -euo pipefail'
  print
  print 'candidates=('
  if [[ -n "$preferred_cli" ]]; then
    print "  $(quote_zsh "$preferred_cli")"
  fi
  print '  "$HOME/Applications/Markway.app/Contents/Helpers/markway"'
  print '  "/Applications/Markway.app/Contents/Helpers/markway"'
  print "  $(quote_zsh "$repo/.build/debug/markway")"
  print "  $(quote_zsh "$repo/.build/release/markway")"
  print ')'
  print
  print 'if (( $+commands[mdfind] )); then'
  print '  while IFS= read -r app; do'
  print '    candidates+=("$app/Contents/Helpers/markway")'
  print '  done < <(/usr/bin/mdfind "kMDItemCFBundleIdentifier == '\''com.anupchavan.markway'\''" 2>/dev/null)'
  print 'fi'
  print
  print 'for candidate in "${candidates[@]}"; do'
  print '  if [[ -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then'
  print '    exec "$candidate" "$@"'
  print '  fi'
  print 'done'
  print
  print 'print -u2 "markway CLI not found. Open Markway.app and click Install CLI, or install standalone markway."'
  print 'exit 127'
} > "$tmp"

chmod 755 "$tmp"
mv -f "$tmp" "$launcher"

print -- "$launcher"
