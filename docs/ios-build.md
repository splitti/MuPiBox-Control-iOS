# iOS build notes

## Linux / LXC

The shared core is intentionally buildable without Apple SDKs:

```bash
swift --version
swift test
```

The current development LXC can therefore be used by Claude for API/client/model work even though it cannot build the SwiftUI application.

## macOS

Requirements:

- a current Xcode installation,
- Xcode command line tools selected,
- XcodeGen.

Generate and validate:

```bash
xcodegen generate
swift test
xcodebuild \
  -project MuPiBoxControl.xcodeproj \
  -scheme MuPiBoxControl \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

`./scripts/bootstrap-macos.sh` wraps these steps.

## Signing

The repository deliberately does not contain a Team ID, certificates or provisioning profiles. Configure signing locally/Xcode/CI after the app identifier and Apple Developer account are finalized.

The provisional bundle identifier in `project.yml` is:

```text
de.mupibox.control.ios
```

Change it before App Store submission if another identifier is selected.
