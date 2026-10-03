# Contributing to HandyBar

HandyBar is in early development. Contributions currently focus on clarifying
and building the three features in the [README](README.md): Alarm, Auto Click, and Cleanup.
Discuss scope changes in a GitHub issue before implementing additional features.

## Propose a change

Search [existing issues](https://github.com/maytad/HandyBar/issues) before opening one.
Describe the problem, expected behavior, and a concrete example.
For bugs, include reproduction steps, the macOS and app versions, and the Mole
version when relevant. Remove personal paths, credentials, and sensitive data
from logs or screenshots. Follow [SECURITY.md](SECURITY.md) for vulnerabilities.

## Development and verification

### Prerequisites

- An Apple silicon Mac with macOS 14 or later.
- Xcode 26 or later (CI uses Xcode 26.6). No Apple Developer account, signing
  certificate, or extra tools are needed; local builds are ad-hoc signed.

### Layout

- `HandyBar.xcodeproj`: the app target only. macOS 14, `arm64`, App Sandbox off,
  Hardened Runtime on, no Dock icon. Files added under `App/` join the target
  automatically.
- `App/`: AppKit lifecycle and the menu bar item.
- `Packages/HandyBarKit`: Swift package in Swift 6 language mode.
  `HandyBarAlarm`, `HandyBarAutoClick`, and `HandyBarCleanup` hold feature logic and
  must not import SwiftUI, AppKit, or each other; `HandyBarUI` holds the SwiftUI panels.

### Checks

Run these before opening a pull request; CI runs the same on every pull request.

```sh
xcrun swift-format lint --strict --recursive App Packages
scripts/check-feature-imports.sh
swift test --package-path Packages/HandyBarKit
xcodebuild -project HandyBar.xcodeproj -scheme HandyBar -derivedDataPath build/DerivedData build
```

Fix formatting with `xcrun swift-format format --in-place --recursive App Packages`.
Write tests with Swift Testing. Open `HandyBar.xcodeproj` in Xcode to run the app.

### Packaging and idle baseline

`scripts/build-dmg.sh` builds a Release DMG in `build/`. Without
`HANDYBAR_SIGN_IDENTITY` it signs ad-hoc; macOS then does not keep granted
permissions across updates, so releases are signed with the maintainer's
self-signed certificate in CI.

`scripts/measure-idle.sh` launches the Release build with the panel closed and
reports memory footprint, CPU, and idle wakeups. Run it when a change can affect
idle behavior and compare against the baseline on the same kind of Mac. Idle
work must not use polling or always-running timers.

| Build | Mac | Footprint | CPU | Idle wakeups |
| --- | --- | --- | --- | --- |
| Walking skeleton, Release | Apple silicon, macOS 27.0 | 16 MB | 0.0% | 1 (10 s sample) |
| Alarm, 5 Alarms set, Release | Apple silicon, macOS 27.0 | 15 MB | 0.0% | 0 (10–20 s samples) |

### Releases

Versions follow SemVer, starting at `v0.1.0`. Pushing a `vX.Y.Z` tag runs the
release workflow, which builds the DMG, signs it with the certificate from the
`HANDYBAR_SIGNING_CERT_P12_BASE64` and `HANDYBAR_SIGNING_CERT_PASSWORD` repository
secrets, and creates a draft GitHub Release for the maintainer to publish.

For documentation changes, check relative links, keep proposed behavior distinct
from implemented behavior, and check the diff for accidental changes.
For future code changes, run the documented checks and report which passed,
failed, or could not run. Keep changes focused and add meaningful regression
coverage for behavior changes when a test setup exists.

## Submit a pull request

Use your own GitHub account. Fork the repository when you do not have branch
write access, and submit a pull request to `main`.
Link the relevant issue, explain the resulting behavior, and report verification.
Keep unrelated refactors out of the change. Add images only when they help explain
a visual change.

Credentials, signing certificates, provisioning files, and private local settings
belong outside the repository. RTK and a particular AI assistant are optional;
contributors can use standard development tools.

By submitting a contribution, you agree to license your contribution under the
project's [MIT License](LICENSE). Identify third-party code and its license before
adding it. The initial integration calls a separately installed Mole CLI; changes
that redistribute or incorporate Mole need a licensing review first.
