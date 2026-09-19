# iOS app icon

## Source

Derived from the canonical suite-wide brand mark: `../../branding/mupibox-control-mark.svg` (see
that directory's `README.md` for the full brand asset set and usage rules). The logo itself was
**not redesigned** for iOS — same "M" + two note-heads concept, same colors, same geometry as the
already-shipped Android adaptive icon.

## What's here

`Sources/App/Resources/Assets.xcassets/AppIcon.appiconset/`:

- `Contents.json` — the modern **single-size** App Icon format (iOS 15+/Xcode 14+): one
  1024x1024 image; Xcode generates every other required size (Home Screen, Settings, Spotlight,
  Notification, App Store, for both iPhone and iPad) from it at build time. This project's
  deployment target is iOS 17, so single-size is the correct, simplest choice — there is no need
  to hand-maintain the older full size set (20/29/40/60/76/83.5/1024pt at 1x/2x/3x).
- `AppIcon-1024.png` — 1024x1024, no alpha channel (iOS app icons must be fully opaque; the source
  SVG already has a solid background, and the regeneration script strips any alpha channel
  defensively anyway).

Wiring:

- `project.yml`: `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` tells Xcode which icon set in the
  asset catalog is the app icon.
- `Sources/App/Resources/Info.plist`: `CFBundleIconName` = `AppIcon` — required because this
  project uses a manually maintained Info.plist (`GENERATE_INFOPLIST_FILE: NO`); Xcode's
  auto-generated Info.plist would normally add this key itself.

## Regenerating

```bash
./scripts/generate-app-icon.sh
```

Re-renders `AppIcon-1024.png` from `../branding/mupibox-control-mark.svg` (via `rsvg-convert`,
flattened to RGB with no alpha via Pillow), then reminds you to re-run `xcodegen generate` (or
`./scripts/bootstrap-macos.sh`) so Xcode picks up the change. Run this instead of hand-editing the
PNG whenever the canonical mark changes.

## Verification status

**Not verified with Xcode.** This was prepared and reasoned through in a Linux LXC with no
Xcode/macOS available: the PNG was checked for correct dimensions, RGB mode (no alpha), and file
format (`file`/Pillow), and the `Contents.json`/`Info.plist`/`project.yml` wiring was written to
match Apple's documented single-size App Icon format as closely as this environment allows to
verify. It has **not** been confirmed to actually build, generate the derived sizes correctly, or
render properly in Xcode/the Simulator/on a device. Do the following on a Mac before trusting it:

1. `brew install xcodegen && ./scripts/bootstrap-macos.sh` (or `xcodegen generate` directly).
2. Open the generated `.xcodeproj` in Xcode and confirm `AppIcon` shows the mark correctly in
   Assets.xcassets, with no missing-size warnings.
3. Build to the Simulator and check the hierarchy: Home Screen icon, Settings, Spotlight search
   result, and the App Switcher — all should show the icon, not a blank/default icon.
