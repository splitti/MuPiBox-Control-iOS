# MuPiBox-NG API snapshot for mobile clients

This is a **read-only snapshot** for the native Android/iOS companion apps.

Verified source:

```text
repository: splitti/MuPiBox-NG
branch:     rebuild/go-foundation
commit:     a709e64a17db51ab848a5d5a6c6f6ccb923020e5
```

Default mobile-app assumption: local HTTP on port `8090`. Do not modify the server from this repository and do not invent missing endpoints.

## M1 endpoints

### Health

`GET /api/health`

```json
{"status":"ok","version":"..."}
```

Use for reachability/compatibility checks.

### Local player status

`GET /api/status`

Relevant fields:

```json
{
  "state": "playing",
  "backend": "mpv",
  "folder_id": "...",
  "folder": "...",
  "cover": "...",
  "queue": [],
  "index": 0,
  "position": 12.3,
  "duration": 125.0,
  "volume": 30,
  "max_volume": 70,
  "error": "..."
}
```

### Local player commands

`POST /api/command`, `Content-Type: application/json`

```json
{"action":"pause"}
```

Supported core actions include:

- `play`
- `pause`
- `toggle`
- `previous`
- `next`
- `stop`
- `seek` with numeric `value` in seconds
- `volume` with numeric `value`
- `volume_delta` with numeric `value`
- `folder` with `folder_id`
- `resume` with `folder_id` + `item_index`

Response is the updated local player status.

### System status

`GET /api/system`

```json
{
  "online": true,
  "wifi": {
    "connected": true,
    "interface": "wlan0",
    "signal_dbm": -52,
    "quality_percent": 74
  },
  "battery": {
    "available": true,
    "percent": 83,
    "charging": false
  }
}
```

For M1 this is the stable mobile source for compact battery/Wi-Fi state. Richer MuPiHAT diagnostics should be added only when a verified server endpoint exists.

### Spotify status

`GET /api/spotify/status`

```json
{
  "connected": true,
  "playing": true,
  "paused": false,
  "buffering": false,
  "volume": 32768,
  "volume_steps": 65535,
  "track": {
    "name": "Track",
    "artists": ["Artist"],
    "album": "Album",
    "cover": "https://...",
    "position_ms": 12000,
    "duration_ms": 180000
  }
}
```

### Spotify commands

`POST /api/spotify/command`

```json
{"action":"pause"}
```

Actions:

- `pause`
- `resume` / `play`
- `previous`
- `next`
- `seek` with integer `value`
- `volume` with integer `value`

### Speak / TTS

`POST /api/speak`

```json
{
  "source_type": "app",
  "source_ref": "manual",
  "text": "Hallo von MuPiBox Control"
}
```

A cache miss may require real synthesis and therefore takes materially longer than normal control calls. Mobile clients should allow roughly 20–25 seconds before timing out. The server pauses active local/Spotify audio before speech.

### Wi-Fi

Read/control endpoints already present for later configuration work:

- `GET /api/connectivity/wifi/adapters`
- `GET /api/connectivity/wifi`
- `POST /api/connectivity/wifi/connect`
- `PUT /api/connectivity/wifi/preferences`

Do not expose configuration writes in M1 without the matching UX/safety design.

### Bluetooth

`GET /api/connectivity/bluetooth`

This is a **scan**, not a cheap passive status request, and Bluetooth must be enabled on the box. Call it only when the user opens/refreshes the Bluetooth view.

`POST /api/connectivity/bluetooth/command`

Body:

```json
{"action":"...","address":"..."}
```

Pair/connect/disconnect/remove behavior belongs to a later parity milestone unless explicitly requested.

## Admin/configuration APIs

The server already contains admin auth/session and settings endpoints. Mobile configuration should be designed as a later shared Android/iOS feature and use the actual authentication/session model rather than bypassing it.

Relevant examples include:

- `GET /api/admin/auth`
- `POST /api/admin/login`
- `POST /api/admin/logout`
- `GET /api/admin/settings`
- `PUT /api/admin/settings`
- TTS/admin endpoints under `/api/admin/tts/...`

## Discovery

The mobile apps reserve the Bonjour/mDNS type:

```text
_mupibox._tcp.
```

At the time this app scaffold was created, manual hostname/IP setup remained the reliable path. Do not require discovery until MuPiBox-NG actually advertises the service.
