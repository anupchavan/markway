#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
workspace="${script_dir:h}"
repo_root="${workspace:h:h}"
build_dir="$workspace/.build"
binary="${JOURNAL_TEXT_OUTPUT:-$build_dir/journal_text}"
shim_object="$build_dir/crdt_shims.o"
converter_bundle="$build_dir/JournalShareExtension_as_bundle"
converter_source="${JOURNAL_TEXT_CONVERTER_SOURCE:-/System/Applications/Journal.app/Contents/PlugIns/JournalShareExtension.appex/Contents/MacOS/JournalShareExtension}"

mkdir -p "$build_dir"

arch="${JOURNAL_TEXT_ARCH:-$(uname -m)}"
case "$arch" in
  arm64)
    swift_target="arm64-apple-ios17.0-macabi"
    converter_arch="arm64e"
    ;;
  x86_64)
    swift_target="x86_64-apple-ios17.0-macabi"
    converter_arch="x86_64"
    ;;
  *)
    print -u2 "unsupported architecture for Mac Catalyst build: $arch"
    exit 1
    ;;
esac

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"

needs_build=false
needs_converter=false
if [[ ! -f "$converter_bundle" ]]; then
  needs_converter=true
elif [[ "$converter_source" -nt "$converter_bundle" ]]; then
  needs_converter=true
fi

if [[ ! -x "$binary" ]]; then
  needs_build=true
elif [[ "$script_dir/journal_text.swift" -nt "$binary" || "$script_dir/crdt_shims.s" -nt "$binary" || "$converter_bundle" -nt "$binary" ]]; then
  needs_build=true
fi

if [[ "$needs_converter" == true ]]; then
  if [[ -f "$converter_source" ]]; then
    lipo -thin "$converter_arch" "$converter_source" -output "$converter_bundle"
    /usr/bin/perl -e 'open my $fh, "+<", $ARGV[0] or die $!; binmode $fh; seek $fh, 12, 0; print $fh pack("V", 8); close $fh' "$converter_bundle"
    codesign -f -s - "$converter_bundle" >/dev/null
    needs_build=true
  elif [[ "${JOURNAL_TEXT_ALLOW_MISSING_CONVERTER:-}" == "1" ]]; then
    print -u2 "warning: Journal rich-text converter source not found; building journal_text without bundled converter"
  else
    print -u2 "Journal rich-text converter source not found: $converter_source"
    print -u2 "Set JOURNAL_TEXT_ALLOW_MISSING_CONVERTER=1 to build without the optional converter."
    exit 1
  fi
fi

if [[ "$needs_build" == true ]]; then
  xcrun clang -target "$swift_target" -isysroot "$sdk_path" \
    -fdebug-prefix-map="$workspace=Vendor/AppleJournalCRDT" \
    -ffile-prefix-map="$workspace=Vendor/AppleJournalCRDT" \
    -fdebug-prefix-map="$repo_root=." \
    -ffile-prefix-map="$repo_root=." \
    -c "$script_dir/crdt_shims.s" -o "$shim_object"
  xcrun swiftc "$script_dir/journal_text.swift" "$shim_object" \
    -o "$binary" \
    -target "$swift_target" \
    -sdk "$sdk_path" \
    -debug-prefix-map "$workspace=Vendor/AppleJournalCRDT" \
    -file-prefix-map "$workspace=Vendor/AppleJournalCRDT" \
    -debug-prefix-map "$repo_root=." \
    -file-prefix-map "$repo_root=." \
    -F"$sdk_path/System/iOSSupport/System/Library/Frameworks" \
    -F"$sdk_path/System/Library/PrivateFrameworks" \
    -framework UIKit \
    -framework AVFoundation \
    -framework JournalShared \
    -framework Coherence \
    -Xlinker -client_name -Xlinker Journal \
    -Xlinker -undefined -Xlinker dynamic_lookup
fi

if [[ "${JOURNAL_TEXT_BUILD_ONLY:-}" == "1" ]]; then
  print "$binary"
  exit 0
fi

exec "$binary" "$@"
