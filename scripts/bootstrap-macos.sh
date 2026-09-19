#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodebuild >/dev/null; then
  echo "Xcode ist nicht installiert oder xcode-select ist nicht konfiguriert." >&2
  exit 1
fi
if ! command -v xcodegen >/dev/null; then
  echo "XcodeGen fehlt. Installiere es z. B. mit Homebrew: brew install xcodegen" >&2
  exit 1
fi

xcodegen generate
swift test
xcodebuild -project MuPiBoxControl.xcodeproj -scheme MuPiBoxControl -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
