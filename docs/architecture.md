# iOS architecture

## Goals

- Native SwiftUI app with native accessibility and navigation.
- Same visible feature set and hierarchy as Android.
- API/core code testable in the Linux development LXC.
- Minimal dependencies and a small surface for Claude to reason about.
- Easy later expansion into MuPiBox admin/configuration.

## Layers

### `MuPiBoxCore`

Platform-independent Swift package containing:

- `Codable` models for the verified MuPiBox API,
- `BoxEndpoint`,
- actor-based `MuPiBoxAPIClient`,
- no SwiftUI/UIKit/Network.framework imports.

This layer is tested with `swift test` in Linux and can also be imported by the Xcode app target.

### App model

`AppModel` is `@MainActor` + `@Observable` and owns:

- saved boxes and selection,
- periodic status refresh,
- current local player/system/Spotify state,
- command orchestration,
- user-facing errors/loading state.

M1 refresh cadence matches the Android control screen: player/Spotify state refreshes at ~1 s
while the dashboard is active, system/battery/Wi-Fi/health status at ~5 s. Bluetooth is excluded
because its endpoint triggers a scan.

Local/Spotify source arbitration and LAN-only endpoint validation live in `MuPiBoxCore`
(`PlaybackSourceSelector`, `LocalEndpointValidator`) so the same rule is Linux-testable and shared
by every view, mirroring the Android `PlaybackSourceSelector`/`LocalEndpointValidator`.

### SwiftUI views

The dashboard follows the shared Android/iOS information hierarchy. Small platform-native differences are allowed while maintaining common spacing, cards, icon roles and control ordering.

### Platform services

- `BonjourDiscovery` uses Network.framework and stays outside `MuPiBoxCore` so Linux tests remain
  clean. Currently unwired (not started anywhere) - reserved for when MuPiBox-NG actually
  advertises `_mupibox._tcp.`.
- `LanDNSGuard` resolves a box's host via POSIX `getaddrinfo`/`getnameinfo` and validates every
  resolved address is itself LAN-shaped (via `LocalEndpointValidator.isLanHost`) before
  `MuPiBoxAPIClient` connects to it - the same defense Android's OkHttp `Dns`-based `LanOnlyDns`
  provides, needed here too since `LocalEndpointValidator` only validates the host string's shape
  at add/edit time, not what a live DNS resolution actually returns. Lives in the App target (not
  Core) for the same Linux-portability reason as `BonjourDiscovery`.

## Persistence

M1 uses `UserDefaults` for the small non-secret device list/selection. If later admin credentials/tokens are stored, they must move to Keychain rather than UserDefaults.

## Networking

M1 targets MuPiBox on the local LAN, normally plain HTTP. The app's Info.plist allows local networking without globally disabling App Transport Security. Local Network privacy and Bonjour service declarations are included.

Every manually entered box passes `LocalEndpointValidator` (RFC1918 IPv4, IPv6 ULA/link-local/loopback, `.local`/`.home.arpa`, single-label LAN hostnames) and a `/api/health` probe before it is saved, matching the Android `LocalEndpointValidator`/`BoxRepository.add` guard. A box is never saved from an unreachable or non-LAN host.

## Future configuration architecture

When configuration is added:

- create explicit admin-session state,
- use the server's real `/api/admin/auth` + login/logout model,
- separate read-only status from state-changing operations,
- show restart-required and connection-loss warnings before network changes,
- implement Android/iOS in the same milestone.
