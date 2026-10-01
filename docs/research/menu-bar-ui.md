# Menu bar UI for a multi-utility app

Research date: 2026-10-01. Scope: how HandyBar's `NSStatusItem` + `NSPopover` UI
should be organized so Alarm, Auto Click, Cleanup, and later utilities stay fast to
use. Sources are Apple HIG, Apple developer docs, Apple support guides, WWDC, and
third-party apps' own docs or source code.

**Summary.** Apple's guidance is to show a menu, not a popover, from a menu bar extra
unless the feature is too complex for a menu. Editing alarms by typing is too complex
for a menu, so a popover is justified, but the HIG limits a popover to "a few related
tasks", forbids one popover opening another, and says to save work when it closes.
Control Center shows the pattern that fits: a compact grid of modules, each showing
its state and one direct action, with an item that expands in place for more options.
Multi-module apps such as Stats and Ice keep quick actions in the menu bar UI and put
per-feature configuration in a separate Settings window with one pane per module.
Recommendation: make the popover a **dashboard of feature modules**. Each module
shows its status and one primary action, and expands in place into a single detail
level (for example, the Alarm list with inline editing and a "type a time + Return"
quick-add field). Move infrequent options to a **Settings window with one pane per
feature**, and put Settings and Quit in a right-click menu on the status item.

## Findings

### 1. Menu bar extras (menu vs popover vs window, size, keyboard)

1.1 HIG: "Display a menu — not a popover — when people click your menu bar extra.
Unless the app functionality you want to expose is too complex for a menu, avoid
presenting it in a popover." The menu bar is 24 pt tall; use a template symbol so the
system can tint it. https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#Menu-bar-extras

1.2 HIG: the system may hide menu bar extras, and apps should not rely on their
presence or position. https://developer.apple.com/design/human-interface-guidelines/the-menu-bar#Menu-bar-extras

1.3 SwiftUI `MenuBarExtra` offers a menu style or a window style. Apple describes the
window style as "a popover-like window" for "more complex or data rich menu bar
extras", laid out like a normal window rather than a menu.
https://developer.apple.com/documentation/swiftui/menubarextra ·
https://developer.apple.com/documentation/swiftui/menubarextrastyle/window ·
WWDC22 "Bring multiple windows to your SwiftUI app" https://developer.apple.com/videos/play/wwdc2022/10061/

1.4 HIG Settings: put general, infrequently changed settings in a Settings window,
and keep task-specific options in the task itself. The macOS Settings window has a
non-customizable toolbar of panes, restores the last pane, has its minimize and zoom
buttons dimmed, and opens with Command-Comma.
https://developer.apple.com/design/human-interface-guidelines/settings

1.5 Keyboard: Control-F8 moves keyboard focus to the status menus in the menu bar.
https://support.apple.com/en-us/102650

1.6 The HIG gives no numeric width or height for menu bar popovers (see 2.1).
Specific pixel targets are therefore UNCONFIRMED by Apple.

### 2. Popovers on macOS

2.1 HIG: use a popover for "a small amount of information or functionality … a few
related tasks". Make it "only big enough to display its contents". When it switches
between condensed and expanded views, animate the size change so it doesn't look like
a new popover. https://developer.apple.com/design/human-interface-guidelines/popovers

2.2 HIG: "Never show a cascade or hierarchy of popovers", and nothing other than an
alert should appear on top of a popover. https://developer.apple.com/design/human-interface-guidelines/popovers

2.3 HIG: "Always save work when automatically closing a nonmodal popover … Discard
people's work only when they click … an explicit Cancel button." Include a Close,
Cancel, or Done button only when it adds clarity.
https://developer.apple.com/design/human-interface-guidelines/popovers

2.4 HIG: don't use a popover to show a warning, because people can miss it or close it
by accident; use an alert. https://developer.apple.com/design/human-interface-guidelines/popovers

2.5 HIG macOS: consider letting people detach a popover into a panel, and keep the
detached panel looking like the popover. AppKit supports this through
`NSPopoverDelegate.detachableWindow(for:)`. A `.transient` popover closes when the user
interacts outside it.
https://developer.apple.com/design/human-interface-guidelines/popovers#macOS ·
https://developer.apple.com/documentation/appkit/nspopoverdelegate/detachablewindow(for:) ·
https://developer.apple.com/documentation/appkit/nspopover/behavior-swift.enum/transient

2.6 HIG Pickers: "Avoid switching views to show a picker"; show it in context next to
the field being edited. https://developer.apple.com/design/human-interface-guidelines/pickers

### 3. Control Center as a model

3.1 Control Center gives "quick access" to settings. Its items work in three ways:
drag a slider, click an icon to turn a feature on or off, or click the item (or its
arrow) to show more options inside Control Center. Examples are Focus showing its list
and Screen Mirroring showing target displays.
https://support.apple.com/guide/mac-help/use-control-center-mchl50f94f8f/mac

3.2 People can add, remove, rearrange, and resize Control Center items, and can copy a
frequently used item to the menu bar as its own extra.
https://support.apple.com/guide/mac-help/use-control-center-mchl50f94f8f/mac

3.3 Implication for HandyBar: each item exposes its state and one direct action at the
top level, and depth is one in-place expansion rather than page navigation. Exact
module sizes and grid metrics are UNCONFIRMED; Apple does not publish them.

### 4. Multi-tool menu bar apps

4.1 **Stats (exelban/stats, open source).** Each module (CPU, memory, disk, network,
and so on) has its own menu bar item and popup. The popup header shows the module
title, a button that opens Activity Monitor, and a button with the tooltip "Open
module" that opens that module's pane in Settings. The fixed popup content width is
`Popup.width = 264`. https://github.com/exelban/stats/blob/master/Kit/module/popup.swift ·
https://github.com/exelban/stats/blob/master/Kit/constants.swift

The Settings window uses a sidebar split view with "Dashboard" and then one entry per
module. App actions such as Pause, Settings, Report a bug, and Close application sit
at the bottom of the sidebar. https://github.com/exelban/stats/blob/master/Stats/Views/Settings.swift

An optional "Combined modules" mode puts all modules in one menu bar item with one
popup. https://github.com/exelban/stats/blob/master/Stats/Views/CombinedView.swift

4.2 **Ice (jordanbaird/Ice, open source).** A left click performs the primary action
(show or hide menu bar sections). A right click opens an `NSMenu` with "Ice Settings…",
"Search Menu Bar Items", per-section Show/Hide items, "Check for Updates…", and
"Quit Ice". https://github.com/jordanbaird/Ice/blob/main/Ice/MenuBar/ControlItem/ControlItem.swift

Settings is a separate window with panes: General, Menu Bar Layout, Menu Bar
Appearance, Hotkeys, Advanced, About. Global hotkeys get their own pane.
https://github.com/jordanbaird/Ice/blob/main/Ice/Main/Navigation/NavigationIdentifiers/SettingsNavigationIdentifier.swift

4.3 **Raycast.** It is keyboard-first: a global hotkey opens Root Search, any command
can have an alias or a global hotkey, and Settings is a separate window with tabs
(General, Shortcuts, Extensions, and others) plus a per-command "Configure Command"
action. https://manual.raycast.com/command-aliases-and-hotkeys.md ·
https://manual.raycast.com/settings.md

Its menu bar commands are menus made of Items, Sections, and Submenus. Raycast loads a
command only while its menu is open and unloads it afterward, and its docs warn that
submenus "add complexity … use them sparingly".
https://developers.raycast.com/api-reference/menu-bar-commands

4.4 **iStat Menus.** Each item shows a compact readout in the menu bar and a detailed
menu on click. "Combined mode" merges several items into one menu bar item, and the
user chooses what appears in the menu bar and what appears in the menu.
https://bjango.com/mac/istatmenus/

4.5 **One Switch.** It markets "All your powerful switches in one place" with
one-click toggles such as Hide Desktop Icons, Dark Mode, and Keep Awake.
https://fireball.studio/oneswitch

Its exact layout (for example, a grid of toggle tiles) is not described in text on
the official page, so that detail is UNCONFIRMED.

4.6 Common pattern across these apps: the click target shows state plus quick actions;
per-feature configuration and hotkeys live in a Settings window with one pane per
feature or area; app-level items (Settings…, Quit) sit in a menu or footer, not in a
feature page.

### 5. Fast time entry and alarm editing

5.1 HIG macOS date pickers come in two styles. Textual suits limited space "and you
expect people to make specific date and time selections". Graphical suits browsing a
calendar or a clock-face look.
https://developer.apple.com/design/human-interface-guidelines/pickers#macOS

SwiftUI offers `.field` (an editable field with no stepper), `.stepperField`,
`.graphical`, and `.compact`. AppKit offers `textField`, `textFieldAndStepper`, and
`clockAndCalendar`. https://developer.apple.com/documentation/swiftui/datepickerstyle ·
https://developer.apple.com/documentation/appkit/nsdatepicker/style

5.2 HIG Pickers: consider less minute granularity, such as an interval that divides
60. https://developer.apple.com/design/human-interface-guidelines/pickers

5.3 Clock on Mac: click +, set the time, then choose Repeat ("the days of the week"),
Label, Sound, Snooze, and Snooze Duration, then click Save. Each alarm has an on/off
switch. To delete, hover and click the delete control. When an alarm fires, Clock uses
a notification with Options > Stop.
https://support.apple.com/guide/clock-mac/set-alarms-apdwe31bfcbc/mac

How Clock labels the repeat days in its picker (full names or short names) is not
stated in the guide: UNCONFIRMED.

5.4 Free-text time parsing has no HIG guidance. Foundation's `NSDataDetector` matches
dates in natural-language text, and SwiftUI `onSubmit` runs an action when the user
presses Return in a field.
https://developer.apple.com/documentation/foundation/nsdatadetector ·
https://developer.apple.com/documentation/swiftui/view/onsubmit(of:_:)

That Apple apps parse forms such as "730p" is UNCONFIRMED.

5.5 HIG toggles: in a grouped form, use a mini switch for a single-row setting, and use
checkboxes for multiple related independent options.
https://developer.apple.com/design/human-interface-guidelines/toggles#macOS

### 6. Ringing panel and buttons

6.1 HIG Alerts: write a title that describes the situation, use one- or two-word verb
button titles, put the default button on the trailing side, and support Escape or
Command-Period to cancel. Use the destructive style only for destructive actions that
people "didn't deliberately choose".
https://developer.apple.com/design/human-interface-guidelines/alerts

6.2 HIG Buttons: give the primary role (Return key) to the most likely choice, never
to a destructive action, and use "style — not size" to distinguish the preferred
option among same-size buttons.
https://developer.apple.com/design/human-interface-guidelines/buttons

SwiftUI `.defaultAction` is Return, and `.cancelAction` is Escape.
https://developer.apple.com/documentation/swiftui/keyboardshortcut/defaultaction ·
https://developer.apple.com/documentation/swiftui/keyboardshortcut/cancelaction

6.3 HIG Panels: a panel floats, has a short noun title, prefers simple controls, and
should not offer a minimize button.
https://developer.apple.com/design/human-interface-guidelines/panels

A `.nonactivatingPanel` "does not activate the owning app".
https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel

6.4 Project constraint: the ringing window must not take keyboard focus
(`docs/permissions-and-data.md`). Return and Escape therefore can't reach Stop or
Snooze unless the panel becomes key. This conflicts with 6.1 and 6.2 (see Open
questions).

### 7. Accessibility and keyboard navigation

7.1 HIG: give every key element a descriptive VoiceOver label, use titles and headings
to show hierarchy, describe grouping and order, and announce visible layout changes.
https://developer.apple.com/design/human-interface-guidelines/voiceover

7.2 HIG: support Full Keyboard Access, make the whole UI operable with the keyboard
alone, and don't override system shortcuts.
https://developer.apple.com/design/human-interface-guidelines/accessibility

Tab and Shift-Tab move between controls, and Control-Tab moves between groups of
controls. https://developer.apple.com/design/human-interface-guidelines/keyboards#Standard-keyboard-shortcuts

7.3 HIG custom shortcuts: define them only for the most frequent commands, prefer
Command as the modifier, and avoid Control.
https://developer.apple.com/design/human-interface-guidelines/keyboards#Custom-keyboard-shortcuts

7.4 Whether Escape closes a transient `NSPopover` without extra code is UNCONFIRMED;
verify it in the app.

## Recommendations for HandyBar

### R1. Status item: left click opens the dashboard; right click opens a menu
- A left click opens the popover. A right click or Control-click opens an `NSMenu`
  with Settings…, Open at Login, About HandyBar, and Quit HandyBar (Ice pattern,
  4.2). This keeps app-level items out of feature pages (4.6).
- The icon reflects state: the Missed Alarm dot already does; add a ringing state and
  an Auto Click running state, as required by `docs/permissions-and-data.md`. The
  VoiceOver label should include that state (7.1).
- Alternatives:
  - (a) A gear in the popover footer instead of a right-click menu: more
    discoverable, but it adds chrome.
  - (b) Both a gear and a right-click menu: Stats puts Settings in the popup header
    (4.1).

### R2. Popover = dashboard of feature modules, one expansion level
- Use a vertical stack of module cards. Each card has an SF Symbol, the feature name,
  a one-line status, and one primary quick action (3.1, 3.3, 4.6):
  - Alarm — status "Next 07:30 Mon · 3 on", or "Missed 07:30" when one was missed;
    action: quick-add field (R4).
  - Auto Click — status "Stopped" or "Running"; action: Start/Stop.
  - Cleanup — status "Ready", or "Mole not installed"; action: "Preview…".
- Clicking a card expands it in place as an accordion with only one card expanded.
  Animate the popover's height change (2.1). There is no second navigation level; edit
  rows inline (R5). Don't cascade popovers (2.2).
- Width: grow from 260 to roughly 320–340 pt so the time, label, repeat summary, and
  switch fit on one row. Stats uses 264 pt plus margins (4.1). The HIG sets no number
  (1.6), so this is a judgment call, UNCONFIRMED as a standard.
- New utilities add one card and one Settings pane. That keeps the structure scalable.
  Past about six cards, allow hiding or reordering cards in Settings (Control Center
  customization, 3.2).
- Alternatives:
  - (a) Tabs or a segmented control at the top: one feature per view, but other
    features' status is hidden and it scales poorly past about five.
  - (b) A sidebar with detail in a wide popover: scales well, but conflicts with
    "avoid making a popover too big" (2.1).
  - (c) A separate status item per feature (Stats and iStat default, 4.1 and 4.4):
    zero navigation, but it uses menu bar space the system may hide (1.2) and needs
    more lifecycle code. This could be added later as an option, like Control Center's
    "Add to Menu Bar" (3.2).

### R3. Settings window for infrequent and per-feature configuration
- Use an `NSWindow` hosting SwiftUI, with toolbar panes General (Open at login),
  Alarm (sound, snooze length), Auto Click (global start/stop shortcut, click
  options), and Cleanup (Mole path or version). Restore the last pane, dim minimize
  and zoom, and support Command-Comma while a HandyBar window is key (1.4, 4.1, 4.2).
- The window is created on open and released on close, which keeps idle cost low
  (ADR 0001). The SwiftUI `Settings` scene assumes the SwiftUI App lifecycle and isn't
  needed here.
- Alternative: keep everything in the popover. That is fewer windows, but it
  contradicts the HIG split between task-specific and general settings (1.4).

### R4. Alarm quick add: type a time, press Return
- At the top of the Alarm card, use a text field with the placeholder "Add alarm, e.g.
  7:30". Pressing Return (`onSubmit`, 5.4) creates an enabled one-time alarm, clears
  the field, and keeps focus there so the user can add more.
- Show a live parse preview under the field, such as "Rings today at 07:30" or
  "tomorrow". On an unparseable entry, show an inline hint, not an alert (2.4, 6.1).
- Parse with a small deterministic parser, unit-tested in `HandyBarAlarm`. Accept `7`,
  `730`, `7:30`, `7.30`, `19:30`, `7:30p`, and `7:30 pm`, and honor the locale's
  12- or 24-hour setting.
- Alternatives:
  - (a) A `.field`-style DatePicker without the stepper (5.1): locale-correct and
    native, but the user must move between segments, so it isn't one-shot typing.
  - (b) `NSDataDetector` (5.4): accepts natural phrases, but its results are less
    predictable and harder to test.
  - (c) The custom parser for quick add, plus a `.field` DatePicker in the inline
    editor. This is the recommended combination.

### R5. Alarm list with inline editing
- Each row shows a large time, the label (or "Alarm"), a repeat summary ("Once",
  "Every day", "Weekdays", "Mon, Wed, Fri"), and a trailing mini switch (5.5).
- Clicking a row expands it in place with a `.field` time picker (no stepper, 5.1),
  label, repeat days, and Delete. Changes save automatically, and closing the popover
  never loses edits (2.3). Drop Save and Cancel, or keep only Done (2.3).
- Delete works without a confirmation alert, because it is a deliberate common action
  (6.1). Whether to offer Undo is an open question.
- Alternative: keep explicit Save and Cancel, as Clock does (5.3). That is safer for
  accidental edits, but slower, and edits are lost when the transient popover closes
  unless they are autosaved anyway (2.3).

### R6. Repeat-day presentation
- Use a pop-up with Never, Every Day, Weekdays, Weekends, and Custom… When Custom is
  chosen, show seven checkboxes or toggle chips labeled with the locale's short
  weekday names (Mon, Tue …), ordered from the locale's first weekday. Clock uses a
  "Repeat" field (5.3), and the HIG prefers checkboxes for related independent options
  (5.5). Keep full day names as VoiceOver labels (7.1).
- Alternatives:
  - (a) Chips only, with three-letter names: one click per day, but wider (fits about
    320 pt).
  - (b) A pull-down menu of seven checkmarked days: compact, but each day costs one
    menu open.
  - (c) The current single-letter buttons: smallest, but ambiguous (S/S, T/T); not
    recommended.

### R7. Ringing panel
- Keep it a floating, non-activating panel (ADR 0003, 6.3). Give it a title ("Alarm"),
  a large time, and the label as the main text. If several alarms ring at once, list
  them all.
- Use two equal-size buttons. Stop is primary or prominent on the trailing side;
  Snooze 5 min is secondary. Neither is destructive-styled, because stopping is
  deliberate and destroys no data (6.1, 6.2).
- Also reflect ringing in the Alarm card ("Ringing — Stop") and in the status icon, so
  the user can stop the alarm from the popover with the keyboard if the panel can't
  take focus (6.4, R1).
- Alternatives:
  - (a) Keep the panel in the top-right corner, like a notification: unobtrusive, but
    easy to miss.
  - (b) A larger centered panel: hard to miss, but more intrusive.
  - (c) Let the panel become key only when the user clicks it (for example with
    `becomesKeyOnlyIfNeeded`), after which Return/Escape work (6.2). Needs the
    maintainer's decision under the focus rule (6.4).

### R8. Auto Click and Cleanup in the same structure
- Auto Click: the card shows Start/Stop and its running state. The global shortcut is
  set in the Settings pane and shown on the card as a hint (7.3,
  `docs/permissions-and-data.md`).
- Cleanup: "Preview…" opens a separate window for Mole's dry-run list and the delete
  confirmation. Don't put it in the popover, because a warning or confirmation in a
  popover is easy to dismiss (2.4, 6.1).

### R9. Native look and accessibility checklist
- Use SF Symbols, system materials and fonts, `controlSize(.small)` or `.regular`
  consistently, and grouped `Form` styling in Settings.
- Give each card a header (7.1) and make it one accessibility group with name and
  status. Make the Tab order run top to bottom (7.2), and announce card
  expansion (7.1).
- Return submits quick add or the focused default; Escape collapses an expanded card,
  then closes the popover (verify 7.4).
- Test with Full Keyboard Access, Control-F8 (1.5), VoiceOver, and Accessibility
  Inspector (7.2).

## Open questions for the maintainer

1. Accept the HIG deviation (a popover rather than a menu, 1.1) on the grounds that
   typing and editing alarms is "too complex for a menu"? Or use a hybrid: an
   `NSMenu` with custom views for status and quick actions, and windows for editing?
2. Should the dashboard be a vertical card stack (recommended) or a Control
   Center-style grid of tiles? How wide may the popover grow?
3. Should the popover be detachable into a panel (2.5)?
4. Autosave alarm edits and drop Save/Cancel (R5)? Offer Undo after Delete?
5. Quick-add rules: does "7" mean 07:00 or the next 7 o'clock (07:00 or 19:00)? Is a
   quick-added alarm always one-time? Can a label be typed in the same field (for
   example "7:30 standup")?
6. Ringing panel: may it become key after the user clicks it, so Return and Escape
   work? Where should it appear, and how large? Should snooze length be configurable,
   given that Clock makes it configurable (5.3)?
7. Should a feature ever get its own optional status item (R2 alternative c), or will
   HandyBar always have one icon?
8. Should Auto Click's running state be its own icon change, a timer badge, or both?
9. Should the look target macOS 14 materials only, or also adopt newer system styling
   where available?
