# Android/iOS parity contract

This document is the product contract between **MuPiBox Control for Android** and **MuPiBox Control for iOS**.

The goal is not pixel-for-pixel emulation of one operating system on the other. The goal is that a user switching phones immediately recognizes the same MuPiBox Control app and can perform the same tasks in the same places.

## Product rules

| Area | Android | iOS | Parity rule |
| --- | --- | --- | --- |
| App role | MuPiBox companion/controller | MuPiBox companion/controller | identical |
| Multi-box | saved box list + selection | saved box list + selection | identical |
| Manual connection | hostname/IP + port | hostname/IP + port | mandatory on both |
| Discovery | `_mupibox._tcp` when server advertises | `_mupibox._tcp` with Bonjour | best-effort enhancement |
| Local playback | previous/play-pause/next/volume | previous/play-pause/next/volume | identical order/semantics |
| Spotify | status + transport + volume | status + transport + volume | identical |
| Battery | compact status | compact status | identical meaning |
| Wi-Fi | compact status | compact status | identical meaning |
| Bluetooth | user opens/scans on demand | user opens/scans on demand | never periodic scan |
| TTS | free text -> box | free text -> box | identical |
| Later configuration | admin/config screens | admin/config screens | feature-gated together |

## Main-screen information hierarchy

Both apps should present the following sequence:

1. selected MuPiBox + online/offline state,
2. current playback/source,
3. transport controls,
4. volume,
5. compact status row: **Battery → Wi-Fi → Bluetooth**,
6. TTS input/action,
7. later: configuration entry points.

Do not add a permanent iOS-only tab or Android-only home section without a parity decision.

## Shared design tokens

Values are conceptual tokens, translated into dp/pt natively:

- page padding: 16
- section spacing: 16
- card corner radius: about 20
- primary transport button: about 68
- secondary transport buttons: about 52
- minimum practical touch target: 44 iOS / 48 Android where native guidance differs

Use each platform's system font and accessibility scaling. Brand assets, terminology, layout density and major hierarchy should remain consistent.

## Allowed native differences

These are expected and do not count as parity failures:

- iOS NavigationStack/sheets vs Android navigation/dialog patterns,
- iOS Local Network permission UX vs Android network permission behavior,
- native typography metrics and safe-area handling,
- native menus, switches, sliders and back gestures,
- App Store vs Play Store release/signing flow.

A platform-specific visual effect must not make one app look like a separate redesign. In particular, do not adopt a dramatic platform-only chrome treatment unless the sibling app receives an equivalent brand-level treatment.

## Behavior parity checklist

For every visible feature:

- user-visible labels mean the same thing,
- disabled/loading/error states have the same intent,
- local-vs-Spotify source selection follows the same rule,
- refresh cadence is comparable,
- commands hit the same MuPiBox endpoint with equivalent payloads,
- unsupported server features degrade gracefully rather than disappearing unpredictably,
- destructive/configuration operations require equivalent confirmation/authentication semantics.

## Versioning

Android and iOS app versions are independent from MuPiBox-NG's version. They do not need identical build numbers, but release notes should state the parity level and any deliberate platform exception.
