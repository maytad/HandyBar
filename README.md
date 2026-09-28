# HandyBar

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/brand/handybar-icon-white.svg">
  <img src="assets/brand/handybar-icon.svg" alt="HandyBar icon: a rounded H with a floating menu bar" width="160" height="160">
</picture>

A macOS menu bar app that brings three everyday utilities into one place.

## Status

HandyBar is an open-source project. It is currently in the
planning stage: there is no runnable app, installer, or supported release yet.
Installation and build instructions will be added with the first implementation.

## Planned platform

These decisions are accepted but not yet implemented.

- macOS 14 or later on Apple silicon. Intel Macs are not supported.
- Native Swift: AppKit for the menu bar item, SwiftUI for panels
  ([ADR 0001](docs/adr/0001-native-swift-hybrid-appkit-swiftui.md)).
- Distribution as a DMG on GitHub Releases, signed with a stable self-signed
  certificate and **not notarized by Apple**. On first launch, macOS blocks the
  app; allow it in System Settings > Privacy & Security > Open Anyway.
- Idle resource use is a primary goal: no polling or always-running timers while idle.

## Initial scope

| Feature | Purpose |
| --- | --- |
| Alarm | Let the user set a time for an alert. |
| Auto Click | Repeat mouse clicks automatically under the user's control. |
| Cleanup | Invoke Mole CLI to clean up disk space. |

These are the only three features in the initial scope.
Additional features require an explicit scope decision.

## Mole integration

Cleanup will invoke [Mole CLI](https://github.com/tw93/Mole) installed separately
by the user. HandyBar will not bundle Mole code or executables in its initial version.
The Terminal launch versus in-app interface is still undecided.
See [permissions and data](docs/permissions-and-data.md) for the planned behavior.

## Decisions still open

- Alarm: notification with sound or a repeating alarm that rings until stopped; behavior during sleep.
- Auto Click: click position, interval, buttons, stop conditions, and start/stop shortcut.
- Cleanup: supported Mole versions and command interface.
- Launch at login: whether it belongs in the initial scope.

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
