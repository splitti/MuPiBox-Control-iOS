#!/usr/bin/env bash
set -euo pipefail

# Regenerates the iOS AppIcon asset from the canonical suite-wide brand mark.
#
# Uses the modern "single size" App Icon format (iOS 15+/Xcode 14+): one
# 1024x1024, alpha-free PNG; Xcode generates every other required size from
# it at build time. This project's deployment target is iOS 17, so this is
# the correct, simplest approach rather than hand-maintaining a full legacy
# size set.
#
# Requires: rsvg-convert (librsvg2-bin on Debian/Ubuntu, `brew install librsvg`
# on macOS) and Python 3 with Pillow (`pip install pillow`) to strip any
# alpha channel - iOS app icons must be fully opaque.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_SVG="$ROOT/../branding/mupibox-control-mark.svg"
APPICONSET="$ROOT/Sources/App/Resources/Assets.xcassets/AppIcon.appiconset"
OUTPUT_PNG="$APPICONSET/AppIcon-1024.png"

if [[ ! -f "$SOURCE_SVG" ]]; then
  echo "Canonical brand mark not found at $SOURCE_SVG" >&2
  echo "This script expects the shared MuPiBox Control Suite workspace layout" >&2
  echo "(ios/ next to branding/)." >&2
  exit 1
fi

command -v rsvg-convert >/dev/null 2>&1 || {
  echo "rsvg-convert not found. Install librsvg2-bin (Debian/Ubuntu) or 'brew install librsvg' (macOS)." >&2
  exit 1
}

mkdir -p "$APPICONSET"
tmp_png="$(mktemp).png"
rsvg-convert -w 1024 -h 1024 "$SOURCE_SVG" -o "$tmp_png"

python3 - "$tmp_png" "$OUTPUT_PNG" <<'PY'
import sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
# iOS app icons must have no alpha channel.
Image.open(src).convert("RGB").save(dst)
PY

rm -f "$tmp_png"
echo "Wrote $OUTPUT_PNG"
echo "Re-run 'xcodegen generate' (or ./scripts/bootstrap-macos.sh) on macOS to pick it up."
