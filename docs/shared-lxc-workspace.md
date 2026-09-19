# Shared Android/iOS Claude workspace

## Recommendation

Use one parent directory in the existing development LXC, but keep Android and iOS as independent Git repositories:

```text
/opt/mupibox-control-suite/
├── android/
└── ios/
```

This is preferable to putting both applications into one Git repository because:

- Kotlin/Gradle and Swift/Xcode have different build/release lifecycles,
- Play Store and App Store metadata/signing remain independent,
- Claude can still inspect both siblings from the parent directory,
- commits/branches cannot accidentally mix platforms,
- parity docs can be compared explicitly.

MuPiBox-NG stays outside this tree and read-only for app development:

```text
/opt/mupibox-ng
```

## Suggested migration

If Android is already checked out as `/opt/mupibox-control`:

```bash
mkdir -p /opt/mupibox-control-suite
mv /opt/mupibox-control /opt/mupibox-control-suite/android
git clone https://github.com/splitti/MuPiBox-Control-iOS.git /opt/mupibox-control-suite/ios
```

If Android is not yet cloned there:

```bash
mkdir -p /opt/mupibox-control-suite
git clone https://github.com/splitti/MuPiBox-Control-Android.git /opt/mupibox-control-suite/android
git clone https://github.com/splitti/MuPiBox-Control-iOS.git /opt/mupibox-control-suite/ios
```

Then:

```bash
cd /opt/mupibox-control-suite/ios
./scripts/bootstrap-lxc.sh
./scripts/check-core.sh
```

For a cross-platform Claude session:

```bash
cd /opt/mupibox-control-suite
claude
```

Claude can compare `android/` and `ios/`, but platform changes should be committed from the appropriate child repository.

## What Linux can and cannot do for iOS

The LXC is useful for:

- Swift package/core development,
- Codable/API models,
- REST client work,
- mock server/tests,
- documentation,
- Android/iOS parity review.

It cannot replace macOS/Xcode for:

- compiling SwiftUI/UIKit/Network.framework app targets,
- iOS Simulator,
- signing/provisioning,
- archive/TestFlight/App Store builds.

Use a Mac (local or CI runner) for those stages.
