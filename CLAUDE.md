# Claude Code instructions — MuPiBox Control iOS

## Mission

Build the native iOS companion app for MuPiBox-NG. It is the sibling of `MuPiBox-Control-Android`, not an independent redesign.

## Non-negotiable rules

1. **Never modify MuPiBox-NG from this project.** Treat `/opt/mupibox-ng` and the GitHub server repository as read-only reference material unless the user explicitly starts a separate server-development task.
2. Android and iOS should have the **same functional scope, terminology, screen hierarchy and visual rhythm**. Read `docs/cross-platform-parity.md` before UI work.
3. Do not invent MuPiBox endpoints. Read `docs/mupibox-api-current.md` and verify against the server repository read-only if necessary.
4. Manual hostname/private-IP connection must always work. Bonjour is an enhancement, not the only onboarding path.
5. Bluetooth scanning is user-triggered/on-demand. Do not poll `/api/connectivity/bluetooth` in the periodic status loop.
6. Keep the platform-neutral HTTP/models layer in `Sources/MuPiBoxCore` Linux-compilable. Do not import SwiftUI, UIKit or Network.framework there.
7. Keep secrets and signing material out of Git. Never commit Apple certificates, provisioning profiles, API keys or developer credentials.
8. Prefer dependency-free Apple frameworks unless a third-party package provides clear value.

## Current architecture

```text
Sources/
├── MuPiBoxCore/           # Linux-testable REST client + Codable models
└── App/
    ├── AppModel.swift     # @MainActor app state/orchestration
    ├── Services/          # Apple-platform services, e.g. Bonjour
    └── Views/             # SwiftUI
```

`Package.swift` builds/tests `MuPiBoxCore` on Linux. `project.yml` generates the native iOS Xcode project with XcodeGen.

## M1 feature order

Implement and keep stable in this order:

1. device persistence + manual host/IP setup,
2. connection health + periodic refresh,
3. local playback controls,
4. Spotify status/control,
5. battery and Wi-Fi status,
6. manual TTS,
7. Bluetooth on-demand view,
8. Bonjour discovery and merge with manual devices,
9. polish/accessibility/parity tests.

Do not pull future admin/configuration work into M1 unless the user explicitly asks for it.

## API source of truth

The scaffold snapshot was verified against:

```text
splitti/MuPiBox-NG
branch: rebuild/go-foundation
commit: a709e64a17db51ab848a5d5a6c6f6ccb923020e5
```

Important endpoints are documented in `docs/mupibox-api-current.md`.

## Cross-platform working mode

If the LXC uses the recommended shared workspace, start Claude from:

```text
/opt/mupibox-control-suite
```

with:

```text
android/  # Android repo

ios/      # this repo
```

Use the Android repo as a behavior/UI reference. Do not copy Kotlin architecture mechanically into Swift; preserve product behavior while using idiomatic SwiftUI/Concurrency.

Before completing a feature, check:

- same user-visible name on Android/iOS,
- same capability and empty/error states,
- same status refresh semantics,
- same control order,
- same API endpoint/body,
- same fallback behavior when a server feature is unavailable.

## Commands

Linux/LXC core verification:

```bash
swift test
./scripts/check-core.sh
```

Mock server:

```bash
python3 tools/mock_mupibox_server.py --port 8090
```

macOS/Xcode:

```bash
brew install xcodegen
./scripts/bootstrap-macos.sh
```

## Definition of done for a change

- Core tests pass on Linux if core code changed.
- iOS Simulator build passes on macOS if app/UI code changed.
- No server files changed.
- `docs/cross-platform-parity.md` is updated when visible behavior changes.
- API docs are updated only from verified server behavior.
- New UI has useful accessibility labels and works with Dynamic Type where practical.
