# Auto Click behavior

Research date: 2026-10-05. Scope: the open questions in issue #3 (click position,
interval, buttons, stop conditions, start/stop shortcut), plus the permissions
Auto Click needs, whether the permission survives updates, safe ways to stop, and
an engine seam that matches `HandyBarAlarm`. Constraints already fixed by
`docs/permissions-and-data.md` and issue #3: start only on the user's command, show
a visible running state, give a reliable stop control usable outside the panel,
need Accessibility, and leave input and screen recording out of scope.

Sources are macOS SDK headers (Xcode 26 SDK), Apple developer documentation and
technotes, and the source of two open-source projects: othyn/macos-auto-clicker,
the most-starred Swift auto clicker for the Mac, and sindresorhus/KeyboardShortcuts,
the hotkey library it uses. Bracketed numbers refer to the Sources list at the end.

**Summary.** Posting clicks needs one permission, which macOS checks as "event
synthesizing access" [1][10] and the user grants in Accessibility [5]. A global
start/stop shortcut can be built on `RegisterEventHotKey` [6]. KeyboardShortcuts
does this, and its maintainer says it causes no permission dialogs and works
sandboxed [7]. So Input Monitoring is not needed. Once Accessibility is granted,
HandyBar can also watch key presses and mouse movement in other apps [4]. That
makes "press Esc to stop" and "stop when the mouse moves" possible without a
second permission. The grant is tied to the app's designated requirement. Local
ad-hoc builds get a cdhash requirement that changes on every build, so the grant
is lost each time [8][13]. Release builds signed with the self-signed certificate
should keep it, but this can't be verified until the first release exists. The
peer app clicks at the cursor on a repeating `Timer`, offers left, right, and
middle clicks, stops after N repeats or when the mouse moves, and defaults to
⌥⌘S / ⌥⌘X [11]. It has no double click and never sets the click-count field, which
is what makes a double click register [2].

## Permissions

| Need | API | Permission | Source |
| --- | --- | --- | --- |
| Post mouse clicks | `CGEvent.post(tap:)` | Event synthesizing access, granted in Accessibility | [1][3][5][10] |
| Check without prompting | `CGPreflightPostEventAccess()` (macOS 10.15+) | none | [1] |
| Ask for it | `CGRequestPostEventAccess()` or `AXIsProcessTrustedWithOptions` with prompt | shows the system prompt | [1][5] |
| Global start/stop shortcut | `RegisterEventHotKey` (Carbon) | none | [6][7] |
| See key presses in other apps (Esc to stop) | `NSEvent.addGlobalMonitorForEvents` with key masks | Accessibility (already held) | [4] |
| See mouse moves in other apps | `NSEvent.addGlobalMonitorForEvents([.mouseMoved])` | not limited by the documentation | [4][11] |
| Listen to all events (event tap) | `CGPreflightListenEventAccess` | Input Monitoring; avoid | [1][10] |

- `CGEvent.h` declares separate checks for posting events and for listening to
  them, both macOS 10.15+ [1]. Apple's PPPC profile reference also lists them as
  two separate services, `PostEvent` and `ListenEvent` [10]. Auto Click needs
  only `PostEvent`.
- The documentation for `addGlobalMonitorForEvents` says key events can be
  monitored only if the app is trusted for accessibility. The monitor cannot
  change or block the event, and it doesn't fire for events sent to HandyBar
  itself [4]. Esc pressed while HandyBar's own window is key needs a local
  monitor or a key equivalent instead.
- `RegisterEventHotKey` registers a system-wide hot key. Its header names no
  permission [6]. KeyboardShortcuts calls it (`HotKey.swift`, line 271), and its
  README answers "Does this package cause any permission dialogs?" with "No" [7].
  Apple doesn't document that Carbon hot keys are permission-free, so this rests
  on a widely used peer rather than an Apple guarantee.
- Granted permissions can be revoked while Auto Click runs. The engine should
  treat "can no longer post" as a stop reason, checked with
  `CGPreflightPostEventAccess()` before each click.

## Does the permission survive updates?

- TCC remembers a grant against the app's designated requirement (DR). TN3127
  calls the DR the code's way of saying "If you see me again, here's how you tell
  it's really me" [8]. If the requirement changes, macOS treats the app as new.
- A local Debug build is ad-hoc signed. `codesign -d -r-` on
  `/tmp/hb-dd/.../HandyBar.app` printed
  `designated => cdhash H"41f3…25eb"`: the requirement pins one exact build, so
  every rebuild needs Accessibility granted again [13]. Contributors should expect
  this when testing Auto Click. `CONTRIBUTING.md` already says so for releases.
- Releases are signed in CI with the maintainer's self-signed identity
  (`release.yml`, `build-dmg.sh` with `HANDYBAR_SIGN_IDENTITY`) [13]. For a
  certificate not issued by Apple, the requirement language can pin
  `certificate leaf` (the signing certificate) and `identifier` [9]. If the
  generated DR has that form, any build signed with the same certificate and
  bundle ID matches. No release has been published yet, so the actual DR could
  not be read. **To verify after the first release:** run
  `codesign -d -r- /Applications/HandyBar.app` on two consecutive releases. Each
  should print `identifier "io.github.maytad.HandyBar" and certificate leaf = H"…"`
  with the same hash, and Auto Click should still work after the update.

## Peer behavior: othyn/macos-auto-clicker

Read at commit `796bd0f` (2025-07-06) [11].

| Question | What it does |
| --- | --- |
| Position | Current cursor position, read on every click (`NSEvent.mouseLocation`, flipped to top-left origin using `NSScreen.screens[0]`). |
| Interval | Integer value plus a unit (ms, s, min, h). Range 1 to 100,000,000. Default 50 ms. Optional random interval between a min and max. Optional start delay with a countdown, default 1 s. |
| Buttons | Left, right, or middle, or a key press with modifiers. Each tick can press several times. No double-click option, and the click-count field is never set. |
| Stop | Stop button, stop shortcut, after N repeats (default 100), or when the mouse moves beyond a threshold of 1 to 1,000 points. It can also start when the mouse moves. |
| Shortcut | Start ⌥⌘S and stop ⌥⌘X by default, both changeable, via KeyboardShortcuts. |
| Timing | `Timer.scheduledTimer` repeating at the interval, with no tolerance set. An activity from `ProcessInfo.beginActivity` is held while clicking, so App Nap doesn't slow the timer [12]. |
| Running state | The menu bar icon turns blue. The menu enables only Start or Stop. Optional notifications on start and finish. |
| Event source | `CGEventSource(stateID: .hidSystemState)` posted to `.cghidEventTap`. |

Things to avoid copying:

- **Mouse-move stop vs a fixed point.** It reads the first mouse-moved event as
  the baseline and stops past the threshold. Its clicks happen at the cursor, so
  they don't move it. If HandyBar clicks at a fixed point, each posted click
  moves the cursor there, and the stop-on-move check would fire on HandyBar's own
  events. Posted events can be tagged with `kCGEventSourceUserData`, and
  `kCGEventSourceUnixProcessID` identifies the sender [2]. Checking these on the
  monitored `NSEvent.cgEvent` can tell HandyBar's events from the user's moves.
- **Double click.** A double click needs two down/up pairs, with
  `kCGMouseEventClickState` set to 1 on the first pair and 2 on the second. The
  header defines 2 as a double click [2]. Without this, apps see two single
  clicks.
- **Very short intervals.** A 1 ms minimum with several presses per tick can
  flood the event stream faster than the user can reach a stop control. A floor
  such as 10 to 50 ms, plus an Esc stop, is safer.

## Fail-safes

All of these come from the APIs above, and none needs a permission beyond
Accessibility:

- **Global shortcut** to start and stop, via `RegisterEventHotKey` [6][7].
- **Esc stops** through a global key monitor, allowed because HandyBar is
  trusted for accessibility [4], plus a local monitor for HandyBar's own windows.
- **Mouse moves by the user** beyond a threshold, ignoring HandyBar's own tagged
  events [2][4].
- **Permission lost:** stop when `CGPreflightPostEventAccess()` turns false [1].
- **Optional hard limits** (N clicks or a duration) so a forgotten run ends.
- **Visible state** in the menu bar item while running, as the peer does, plus a
  Stop control in the panel.
- Stop when the Mac sleeps or the screen locks. This is not researched against a
  source here. `NSWorkspace` sleep and session notifications are the usual route,
  to be confirmed before implementation.

## Timing

- `Timer` and `DispatchSourceTimer` both run on the app's run loop or queue. The
  peer holds a `ProcessInfo.beginActivity` token while clicking, which is how an
  app opts out of App Nap and timer throttling for user-requested work [12].
- macOS doesn't promise exact timing for app timers. A schedule based on target
  times (next = start + n × interval) keeps the average rate right even if single
  ticks are late, and an engine that takes `now` as input can be tested that way.
  This is a design suggestion, not a sourced claim.

## Proposed engine seam

Match `HandyBarAlarm`: a pure `AutoClickEngine` in `HandyBarAutoClick` with no
AppKit or CoreGraphics posting, driven by events, and with the I/O in the app
target.

- **Settings (value type):** target (cursor or a fixed point), interval, button
  (left or right), click kind (single or double), stop rule (manual, after N
  clicks, after a duration).
- **Events in:** `start(now)`, `tick(now)`, `stop`, `userMovedMouse`,
  `postAccessLost`.
- **State out:** idle, or running with the clicks done and the next due time; and
  the last stop reason (user, limit reached, mouse moved, access lost).
- **Effects out:** the clicks due at this tick (button, kind, target), which the
  app passes to a `ClickPoster` protocol. The real poster uses `CGEvent`, and
  tests use a fake.
- The app owns the timer, the hot key, the monitors, and the activity token.
  Unit tests cover interval math, limits, stop reasons, and that ticks after stop
  do nothing.

## Open questions for the maintainer (issue #3)

1. **Position:** cursor only, a fixed point the user picks, or several points?
2. **Interval:** the allowed range, its unit, whether random intervals are
   included, and a start delay.
3. **Buttons:** left only, or right and double click too?
4. **Stop conditions:** which of manual, N clicks, duration, mouse moved, and Esc
   to include, and which are on by default.
5. **Shortcut:** the default key combination, whether start and stop share one
   key, and whether the user can change it.
6. **Permission flow:** when to ask for Accessibility (on first start, or when the
   Auto Click pane opens), and what the pane shows while it is missing.

## Sources

1. `CoreGraphics.framework/Headers/CGEvent.h`, macOS SDK (Xcode 26), lines 398–408:
   `CGPreflightListenEventAccess`, `CGRequestListenEventAccess`,
   `CGPreflightPostEventAccess`, `CGRequestPostEventAccess`.
2. `CoreGraphics.framework/Headers/CGEventTypes.h`, macOS SDK:
   `kCGMouseEventClickState` (line 148), `kCGEventSourceUnixProcessID` (352),
   `kCGEventSourceUserData` (356).
3. Apple, [`CGEvent.post(tap:)`](https://developer.apple.com/documentation/coregraphics/cgevent/post(tap:)).
4. Apple, [`NSEvent.addGlobalMonitorForEvents(matching:handler:)`](https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents(matching:handler:)).
5. Apple, [`AXIsProcessTrustedWithOptions(_:)`](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions).
6. `HIToolbox.framework/Headers/CarbonEvents.h`, macOS SDK, line 15484:
   `RegisterEventHotKey`.
7. sindresorhus/KeyboardShortcuts, [readme](https://github.com/sindresorhus/KeyboardShortcuts#readme)
   and [`HotKey.swift`](https://github.com/sindresorhus/KeyboardShortcuts/blob/772133d9dbe800fdac0473226822994c5c162c58/Sources/KeyboardShortcuts/HotKey.swift),
   commit `772133d` (2026-09-11).
8. Apple, [TN3127: Inside Code Signing: Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).
9. Apple, [Code Signing Requirement Language](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/RequirementLang/RequirementLang.html).
10. Apple, [PrivacyPreferencesPolicyControl.Services](https://developer.apple.com/documentation/devicemanagement/privacypreferencespolicycontrol/services-data.dictionary)
    (`PostEvent`, `ListenEvent`, `Accessibility`).
11. othyn/macos-auto-clicker, commit [`796bd0f`](https://github.com/othyn/macos-auto-clicker/tree/796bd0f3d4c9bd4c56aa647d18f28e42f139b3c3):
    `Observable Objects/AutoClickSimulator.swift`, `Constants/FieldConstants.swift`,
    `Constants/KeyboardShortcuts.swift`, `Models/FormState.swift`.
12. Apple, [`ProcessInfo.beginActivity(options:reason:)`](https://developer.apple.com/documentation/foundation/processinfo/beginactivity(options:reason:)).
13. HandyBar: `codesign -d -r-` on a local Debug build (2026-10-05);
    `.github/workflows/release.yml`; `scripts/build-dmg.sh`; `CONTRIBUTING.md`.
