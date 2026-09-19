# MuPiBox Control for iOS

Native iPhone/iPad companion app for MuPiBox-NG, designed as the iOS sibling of **MuPiBox Control for Android**.

**Status:** initial scaffold / `0.1.0-dev`

The central product rule is cross-platform parity: Android and iOS should expose the same MuPiBox features, use the same terminology and keep the same information hierarchy. Platform-native controls are welcome where they improve usability, but they must not silently create a different product.

## M1 scope

The first milestone mirrors the Android control app:

- save and select one or more MuPiBox devices,
- always support manual local hostname/private-IP setup (default port `8090`),
- prepare Bonjour discovery for `_mupibox._tcp.`,
- show connection, battery and Wi-Fi state,
- open Bluetooth status/scanning only on demand,
- control local playback: previous, play/pause, next and volume,
- control Spotify Connect playback through the MuPiBox API,
- send arbitrary TTS text to the selected box,
- keep the architecture ready for later MuPiBox configuration/admin functions.

See [`docs/cross-platform-parity.md`](docs/cross-platform-parity.md) for the UI/function contract shared with Android.

## Repository boundary

This repository is the **iOS client only**. **Do not modify MuPiBox-NG from this repository or while implementing app features.** MuPiBox-NG is read-only reference material for its HTTP API.

The API snapshot used for this scaffold was verified against `splitti/MuPiBox-NG`, branch `rebuild/go-foundation`, commit `a709e64a17db51ab848a5d5a6c6f6ccb923020e5`. See [`docs/mupibox-api-current.md`](docs/mupibox-api-current.md).

## Stack

- Swift / SwiftUI
- Swift Concurrency (`async`/`await`)
- Observation (`@Observable`)
- `URLSession` for the MuPiBox REST API
- Network.framework (`NWBrowser`) for Bonjour preparation
- Swift Package Manager for the platform-independent API core
- XcodeGen for a reproducible Xcode project
- iOS 17+ deployment target for the first release

The `MuPiBoxCore` package intentionally compiles and tests on Linux. The SwiftUI target requires macOS/Xcode.

## Shared Claude workspace on the existing LXC

Recommended layout:

```text
/opt/mupibox-control-suite/
├── android/   -> splitti/MuPiBox-Control-Android
└── ios/       -> splitti/MuPiBox-Control-iOS
```

Keep the server checkout separate:

```text
/opt/mupibox-ng
```

This gives Claude one parent directory for comparing Android/iOS behavior without mixing Git histories or toolchains. See [`docs/shared-lxc-workspace.md`](docs/shared-lxc-workspace.md).

On Linux/LXC:

```bash
./scripts/bootstrap-lxc.sh
./scripts/check-core.sh
```

Or directly:

```bash
swift test
```

## macOS / Xcode

A Mac with Xcode is required for the real iOS target, Simulator, signing and App Store builds.

```bash
brew install xcodegen
./scripts/bootstrap-macos.sh
```

That generates `MuPiBoxControl.xcodeproj` from `project.yml`, runs core tests and performs a Simulator build.

## Local-network permissions

The project is prepared for iOS Local Network privacy:

- `NSLocalNetworkUsageDescription`
- `NSBonjourServices` containing `_mupibox._tcp`
- `NSAllowsLocalNetworking`

Manual host/IP entry remains mandatory even after Bonjour discovery is implemented.

## Development without a physical MuPiBox

Run the mock server:

```bash
python3 tools/mock_mupibox_server.py --port 8090
```

Then add the development machine/LXC's LAN address as a MuPiBox.

## Claude Code

Start with [`CLAUDE.md`](CLAUDE.md). It contains the permanent repository rules, parity requirements and the development sequence so Claude does not need to rediscover the project on each session.

Useful docs:

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/cross-platform-parity.md`](docs/cross-platform-parity.md)
- [`docs/mupibox-api-current.md`](docs/mupibox-api-current.md)
- [`docs/m1-acceptance.md`](docs/m1-acceptance.md)
- [`docs/roadmap.md`](docs/roadmap.md)
- [`docs/ios-build.md`](docs/ios-build.md)
- [`docs/app-icon.md`](docs/app-icon.md)
- [`docs/xcode-verification.md`](docs/xcode-verification.md)
