# Xcode verification (macOS-only)

Everything in this repo has been developed and reviewed in a Linux LXC with no Xcode/macOS
available. `MuPiBoxCore` is genuinely verified there (GitHub Actions' "Core CI" runs `swift test`
in the official `swift:latest` Linux container on every push). The SwiftUI app target
(`Sources/App`) is **not** part of that build — `Package.swift` only builds/tests the
`MuPiBoxCore` library, since the app target needs the iOS SDK. This is the one remaining
verification path that requires an actual Mac, and this document is meant to make that as short
and mechanical as possible.

## Prerequisites

- A Mac with Xcode installed (a recent version supporting iOS 17 SDK, matching this project's
  `IPHONEOS_DEPLOYMENT_TARGET`).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.

## Steps

```bash
git pull
xcodegen generate
```

This regenerates `MuPiBoxControl.xcodeproj` from `project.yml` (the `.xcodeproj` itself is not
committed). Equivalently, `./scripts/bootstrap-macos.sh` runs this plus the Linux-portable core
tests plus an initial Simulator build in one step.

Then, in Xcode:

1. Open `MuPiBoxControl.xcodeproj`.
2. Select the **MuPiBoxControl** scheme (the only scheme this project defines — see
   `project.yml`'s `targets.MuPiBoxControl`; there is no separate test scheme, since
   `MuPiBoxCoreTests` already runs on Linux).
3. Choose any iOS 17+ Simulator destination (e.g. iPhone 15).
4. **Build** (⌘B). This is the actual open question this environment can't answer: does the
   SwiftUI/`AppModel`/`LanDNSGuard` layer compile at all under a real iOS SDK.
5. **Test** (⌘U) to re-run `MuPiBoxCoreTests` from inside Xcode — should match the Linux CI result
   (all tests passing) exactly, since it's the same package.
6. **Run** (⌘R) the app in the Simulator and check, in order:
   - **App icon**: Home Screen, Settings, Spotlight, and App Switcher should all show the MuPiBox
     Control mark (see `docs/app-icon.md`) — not a blank/default icon, and not a
     missing-asset placeholder.
   - **Dark/Light mode**: toggle the Simulator's appearance (Settings > Developer, or
     Xcode's Environment Overrides) and confirm the dashboard remains legible and uses sensible
     contrast in both — the app has no manual light/dark branching, so this is really checking
     that SwiftUI's automatic semantic-color adaptation looks right, not that some `if dark {}`
     branch works.
   - **Network permission**: on first launch/connection attempt, iOS should prompt for local
     network access (`NSLocalNetworkUsageDescription` in Info.plist); confirm the prompt text
     reads sensibly and that denying/re-granting it behaves reasonably (add-box should fail
     clearly if denied, not hang).
   - **Add a real MuPiBox**: either a physical box on the same LAN, or
     `python3 tools/mock_mupibox_server.py --port 8090` run on the same machine/network reachable
     from the Simulator, and confirm: add-box validates + health-probes before saving, box
     editing (`AddBoxView(editing:)`) pre-fills and updates in place, player/Spotify/volume/TTS/
     battery/Wi-Fi/Bluetooth all behave as described in `../PRODUCT-PARITY.md`.

## CLI build (optional)

`./scripts/bootstrap-macos.sh` already does exactly this — `xcodegen generate`, `swift test`, then
a Simulator build — in one step. Its build line, verbatim:

```bash
xcodebuild -project MuPiBoxControl.xcodeproj -scheme MuPiBoxControl -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

`-project`/`-scheme` match the actual names XcodeGen produces from `project.yml` (`name:
MuPiBoxControl` at the top, target name `MuPiBoxControl`) — if the project is ever renamed, update
both `project.yml` and this script together, not just one of them.

## What's already verified without a Mac, so you don't need to re-check it here

- All of `Sources/MuPiBoxCore`: models, `MuPiBoxAPIClient` (including the `HostResolver`
  extension point), `LocalEndpointValidator` (including the now-public `isLanHost`),
  `PlaybackSourceSelector`, `VolumeScaling`, `BluetoothErrorPresentation` — 28 tests, all green in
  CI as of the commit that added this document.
- `Contents.json`/`Info.plist`/`project.yml` for the app icon are validated as well-formed
  JSON/plist/YAML with the expected keys present (see `docs/app-icon.md`) — but not confirmed to
  actually satisfy Xcode's asset-catalog compiler, which is exactly what step 4/6 above checks.

## What can only be confirmed here, not assumed

- That `Sources/App` actually compiles against a real iOS SDK (SwiftUI, Observation, Network
  APIs used by `LanDNSGuard`'s `Darwin` import).
- That `LanDNSGuard`'s POSIX `getaddrinfo`/`getnameinfo` usage behaves correctly at runtime (the
  logic was written carefully but has never executed).
- Runtime behavior of anything stateful/async in `AppModel` (offline handling, Bluetooth
  loading/auth-error states, TTS loading/slow-response handling) — these are documented and
  manually reasoned through in `PRODUCT-PARITY.md`, but "reasoned through" is not "observed
  running."
