# HandyBar

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/brand/handybar-icon-white.svg">
  <img src="assets/brand/handybar-icon.svg" alt="HandyBar icon: a rounded H with a floating menu bar" width="160" height="160">
</picture>

A macOS menu bar app that brings three everyday utilities into one place.

## Status

HandyBar is an open-source project in early development. The app runs as a
menu bar item. Alarm works; Auto Click and Cleanup do not yet, and there is no
supported release.

## Platform

- macOS 14 or later on Apple silicon. Intel Macs are not supported.
- Native Swift: AppKit for the menu bar item, SwiftUI for panels
  ([ADR 0001](docs/adr/0001-native-swift-hybrid-appkit-swiftui.md)).
- Distribution as a DMG on GitHub Releases, signed with a stable self-signed
  certificate and **not notarized by Apple**.
- Idle resource use is a primary goal: no polling or always-running timers while idle.

## Install

No release has been published yet. Once one is, download the DMG from
[GitHub Releases](https://github.com/maytad/HandyBar/releases) and drag HandyBar
to Applications. Because the app is not notarized, macOS blocks the first launch:

1. Open HandyBar once and dismiss the warning.
2. Open System Settings > Privacy & Security, find the message about HandyBar,
   and choose **Open Anyway**.

To build from source, follow the checks in [CONTRIBUTING.md](CONTRIBUTING.md),
or run `scripts/build-dmg.sh` to produce a DMG in `build/`.

## Initial scope

| Feature | Purpose |
| --- | --- |
| Alarm | Ring at times of day the user sets, once or on chosen weekdays, while the Mac is awake. |
| Auto Click | Repeat mouse clicks automatically under the user's control. |
| Cleanup | Invoke Mole CLI to clean up disk space. |

These are the only three features in the initial scope. An **Open at login**
setting, off by default, is also in scope because an Alarm rings only while
HandyBar is running. Additional features require an explicit scope decision.

Alarms ring inside HandyBar rather than through system notifications
([ADR 0003](docs/adr/0003-alarms-ring-in-app.md)). An Alarm due while the Mac is
asleep or HandyBar is not running does not ring late; HandyBar marks it as missed.

## Mole integration

Cleanup will invoke [Mole CLI](https://github.com/tw93/Mole) installed separately
by the user. HandyBar will not bundle Mole code or executables in its initial version.
The Terminal launch versus in-app interface is still undecided.
See [permissions and data](docs/permissions-and-data.md) for the planned behavior.

## Decisions still open

- Auto Click: click position, interval, buttons, stop conditions, and start/stop shortcut.
- Cleanup: supported Mole versions and command interface.

Launching Mole in Terminal was suggested during ideation.
It is a proposal, not an accepted implementation decision.

## Project guidance

- [Contributing](CONTRIBUTING.md): propose changes and contribute to the project.
- [Security](SECURITY.md): report security concerns privately.
- [Agent guidance](AGENTS.md): engineering-skill configuration.
- [Domain glossary](CONTEXT.md): project vocabulary.
- [Architecture decisions](docs/adr/): recorded decisions and their reasons.
- [Brand assets](assets/brand/README.md): editable SVG icons and the approved PNG original.

## License

HandyBar's original code and documentation are licensed under the [MIT License](LICENSE).
[Mole is separately licensed under GPL-3.0](https://github.com/tw93/Mole/blob/main/LICENSE);
HandyBar's license does not relicense Mole. Any future redistribution or incorporation
of Mole must account for its license obligations before release.
HandyBar is an independent project and is not affiliated with or endorsed by Mole.
