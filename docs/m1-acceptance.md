# M1 acceptance criteria

M1 is complete when the iOS app reaches functional parity with the first Android control milestone.

## Required

- App launches on the supported iOS deployment target.
- User can add a MuPiBox by hostname/private IP and port.
- Multiple boxes can be saved and selected.
- Selection survives app restart.
- App clearly shows online/offline state.
- Local player status can be read.
- Local previous, play/pause, next and volume work.
- Spotify status can be read when available.
- Spotify previous, play/pause, next and volume work.
- Compact battery state is shown from `/api/system`.
- Compact Wi-Fi state is shown from `/api/system`.
- Bluetooth scan is available only from a deliberate user action.
- User can type arbitrary TTS text and send it to `/api/speak`.
- Manual connection still works if Bonjour finds nothing.
- Core tests pass in Linux.
- iOS Simulator build passes on a Mac/Xcode.
- App contains the required Local Network/Bonjour privacy declarations.
- No MuPiBox-NG server source was changed to make the app work.

## Parity review

Before calling M1 done, compare the two apps side by side and confirm:

- same sections/order,
- same feature names,
- same source-selection behavior for local vs Spotify,
- same Bluetooth on-demand behavior,
- comparable loading/error/empty states,
- no platform-only feature without an explicit reason.
