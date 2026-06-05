#!/bin/zsh
set -euo pipefail

repo="${0:A:h:h}"

swift test --package-path "$repo"
swift run --package-path "$repo" markway doctor
xcodegen generate --spec "$repo/project.yml"
xcodebuild -project "$repo/Markway.xcodeproj" -scheme Markway -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
