#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null; then
  echo "git fehlt" >&2
  exit 1
fi
if ! command -v python3 >/dev/null; then
  echo "python3 fehlt" >&2
  exit 1
fi

cat <<'MSG'
MuPiBox Control iOS LXC-Basis ist bereit.

Im Linux-LXC möglich:
- Quellcode/Doku bearbeiten
- Mock-Server ausführen
- MuPiBoxCore mit `swift test` testen, falls ein Swift-Toolchain installiert ist

Nicht im Linux-LXC möglich:
- iOS Simulator
- Xcode/iOS-App kompilieren
- Code Signing / TestFlight / App Store Upload

Empfohlenes gemeinsames Workspace-Layout:
  /opt/mupibox-control-suite/android
  /opt/mupibox-control-suite/ios

MuPiBox-NG gehört NICHT in diesen Workspace und bleibt unverändert.
MSG

if command -v swift >/dev/null; then
  echo "Swift: $(swift --version | head -n1)"
  swift test
else
  echo "Hinweis: Swift ist nicht installiert; Core-Tests werden übersprungen."
fi
