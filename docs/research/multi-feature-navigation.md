# Navigating many features from one menu bar popover

> **Decision:** the maintainer chose a full sidebar in the popover instead of the
> recommendation below; see [ADR 0004](../adr/0004-panel-sidebar.md).

Research date: 2026-10-02. Builds on [menu-bar-ui.md](menu-bar-ui.md); findings
covered there (menu vs popover, Control Center basics, Stats/Ice/Raycast layouts,
Settings window rules) are referenced, not repeated. Scope: how HandyBar's 320 pt
`NSPopover` should let people reach 6–15 utilities over time, and whether a
sidebar is the right answer.

**Summary.** A full sidebar inside the popover is not the better choice. The HIG
says a sidebar "requires a large amount of vertical and horizontal space" and
points to a more compact control when space is limited. The popover page treats
popovers as the compact alternative to sidebars and says to avoid making them too
big. A sidebar plus a 320 pt detail needs a popover about 500–550 pt wide, and none
of the well-known menu bar apps checked here uses one. They put the sidebar in the
**Settings window** instead. Recommendation by feature count: at **3** features,
keep the current card stack, or switch early to a **home list that opens one
feature at a time with a Back button** (iOS-style drill-in; Control Center and
System Settings use the same idea). At **6**, use that drill-in list as the default.
At **10+**, add pinned features, type-to-filter, Command-1…9 shortcuts, and
hide/reorder options in a Settings window with a real sidebar. Runner-up: a narrow
**icon rail**, a vertical icon-only tab bar about 48 pt wide. It keeps every
feature's status visible while one is open, at about 370 pt total width.

## Findings

### Q1. HIG on sidebars

1.1 A sidebar "requires a large amount of vertical and horizontal space. When space
is limited … a more compact control such as a tab bar may provide a better
navigation experience." https://developer.apple.com/design/human-interface-guidelines/sidebars

1.2 Best practices: let people customize sidebar contents and order; group with
disclosure controls when there is a lot of content; "show no more than two levels
of hierarchy"; use familiar SF Symbols; icon colors follow the accent color unless
a fixed color has a clear purpose; let people hide the sidebar but "avoid hiding the
sidebar by default". https://developer.apple.com/design/human-interface-guidelines/sidebars

1.3 macOS specifics are window-centric. Row height and glyph size follow the
sidebar icon size in General settings (small, medium, or large). The sidebar can
auto-collapse when "its container window resizes", and you should avoid critical
items at the bottom because "people often relocate a window" so that its bottom
edge is hidden. https://developer.apple.com/design/human-interface-guidelines/sidebars

1.4 Width and item count: the HIG gives no number for either (UNCONFIRMED as a
standard). `NSSplitViewItem(sidebarWithViewController:)` uses "the standard minimum
and maximum sidebar size" and `preferredThicknessFraction` 0.15, plus
collapse-on-resize and full-screen overlay behaviors, all of which are window
behaviors. https://developer.apple.com/documentation/appkit/nssplitviewitem/init(sidebarwithviewcontroller:)
Real values: Ice's Settings sidebar is 190, 210, or 230 pt depending on sidebar icon
size (https://github.com/jordanbaird/Ice/blob/main/Ice/Settings/SettingsView.swift).
Stats' Settings sidebar is 180 pt inside a 720×480 window
(https://github.com/exelban/stats/blob/master/Stats/Views/Settings.swift).

1.5 Sidebars are built from `NSSplitViewController` with the sidebar behavior, and
they integrate with the window's full-height title bar and toolbar (WWDC20 "Adopt
the new look of macOS"). A popover has no title bar or toolbar, so that integration
does not apply. The HIG does not explicitly say whether a sidebar inside a popover
is allowed: UNCONFIRMED. https://developer.apple.com/videos/play/wwdc2020/10104/

### Q2. Popover size, moving to a window, split views in a popover

2.1 HIG: "Views like sidebars and panels take up a lot of space. If you need content
only temporarily, displaying it in a popover can help streamline your interface."
Also: "Avoid making a popover too big", and animate size changes so it doesn't look
like a new popover. https://developer.apple.com/design/human-interface-guidelines/popovers

2.2 Content belongs in a window when people need it to persist or to work
alongside other apps. The HIG suggests letting a popover detach into a panel for
that case (see menu-bar-ui.md 2.5). It defines an auxiliary window as one that
"presents a specific task" and "doesn't allow navigation to other app areas".
https://developer.apple.com/design/human-interface-guidelines/windows

2.3 Apple docs don't forbid split views in a popover, but `NavigationSplitView` is
described as "typically … the root view in a Scene". Column widths are only
preferences: "SwiftUI may use a different width for your column."
https://developer.apple.com/documentation/swiftui/navigationsplitview ·
https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(_:)
I found no Apple engineer forum post about `NavigationSplitView` inside `NSPopover`
(UNCONFIRMED). Community reports, which are not primary sources, describe sizing
problems with MenuBarExtra's window style. HandyBar doesn't use that style:
https://stackoverflow.com/questions/77487268 · https://github.com/ingo-eichhorst/Irrlicht/issues/189

2.4 Width math (estimate): a 180–230 pt sidebar (1.4) plus a divider plus the
current 320 pt detail comes to about 500–550 pt. An icon rail of about 48 pt plus
320 pt comes to about 370 pt. Stats' popup is 264 pt
(https://github.com/exelban/stats/blob/master/Kit/constants.swift).

2.5 Height: the menu bar is 24 pt tall
(https://developer.apple.com/design/human-interface-guidelines/the-menu-bar).
A 13-inch MacBook Air has a 2560×1664 panel (https://support.apple.com/en-us/118551).
Its default "looks like" 1470×956 workspace comes from non-Apple sources
(UNCONFIRMED). That leaves roughly 900 pt of usable height in the worst common case.
At today's card size of about 64 pt including spacing, 10 cards need about 640 pt;
compact 40 pt rows need about 400 pt.

2.6 HandyBar already hosts SwiftUI with `sizingOptions = .preferredContentSize`
(macOS 13+), and `NSPopover.contentSize` changes animate while the popover is shown
(`App/StatusItemController.swift`).
https://developer.apple.com/documentation/swiftui/nshostingcontroller/sizingoptions ·
https://developer.apple.com/documentation/appkit/nspopover/contentsize

### Q3–Q4. Alternatives, with real examples

**a. Sidebar inside the popover.** None of the apps checked does this: Stats,
iStat Menus, Bartender, Ice, SwiftBar, Maccy, or Raycast. A GitHub code search for
`NavigationSplitView` together with `MenuBarExtra` mostly found Settings windows
(UNCONFIRMED that no notable app does it). Stats' "Combined modules" popup is a
vertical `NSStackView` of every module's compact portal at 264 pt, not a sidebar
(https://github.com/exelban/stats/blob/master/Stats/Views/CombinedView.swift).
iStat Menus Combined lets the user choose which items appear in the menu bar and
which in one dropdown (https://bjango.com/help/istatmenus7/combined/).
Bartender Groups combine several items into one item that gives access to all of
them (https://www.macbartender.com/Bartender5/).

**b. Icon tab bar or segmented control.** HIG tab views: "Avoid providing more
than six tabs"; past that, use a pop-up menu
(https://developer.apple.com/design/human-interface-guidelines/tab-views).
Segmented controls: "no more than about five to seven segments in a wide
interface"; use tooltips; don't mix text and icons in one control
(https://developer.apple.com/design/human-interface-guidelines/segmented-controls).
Spotlight switches modes with Command-1, Command-2, and Command-3
(https://support.apple.com/en-ca/guide/mac-help/mchl4d69efd3/mac). This option is
capped at about 6 features. An icon rail is the vertical version of the same thing
and fits about 10 icons in the same height.

**c. Home list that drills into one feature.** System Settings: "Click an option
in the sidebar. (You may need to scroll down.)"
(https://support.apple.com/guide/mac-help/change-system-settings-mh15217/mac).
Control Center: "Click an item (or its arrow) to show more options", for example
Focus showing its list
(https://support.apple.com/guide/mac-help/use-control-center-mchl50f94f8f/mac).
Apple's docs don't say whether that detail replaces the grid or expands in place
(UNCONFIRMED). SwiftUI `NavigationStack` provides Back, but in HandyBar a plain
`selected: FeatureID?` state is simpler and keeps size animation under control
(https://developer.apple.com/documentation/swiftui/navigationstack). Escape can map
to Back with `onExitCommand` (macOS 10.15+)
(https://developer.apple.com/documentation/swiftui/view/onexitcommand(perform:)).

**d. Search or command palette first.** Raycast pins Favorites "above all other
results when the search bar is empty", with aliases and hotkeys per command
(https://manual.raycast.com/search-bar ·
https://manual.raycast.com/command-aliases-and-hotkeys). Maccy's menu bar list is
"keyboard-first": type to filter, Return to select, Command-n to pick an item
(https://github.com/p0deje/Maccy). HIG search fields: start searching as people
type, and use placeholder text to show what can be searched
(https://developer.apple.com/design/human-interface-guidelines/search-fields).
`onKeyPress` (macOS 14+) can start filtering on the first keystroke
(https://developer.apple.com/documentation/swiftui/view/onkeypress(_:action:)).

**e. Popover for quick actions, plus a window with a sidebar.** Stats and Ice both
do this (menu-bar-ui.md 4.1–4.2). Ice's Settings window is a `NavigationSplitView`
with a minimum size of 825×500
(https://github.com/jordanbaird/Ice/blob/main/Ice/Settings/SettingsWindow.swift).
The HIG Settings page describes a toolbar of panes; with many panes, a sidebar like
System Settings' is the real-world pattern
(https://developer.apple.com/design/human-interface-guidelines/settings).

**f. Customization: pins, hiding, separate menu bar items.** The HIG says to let
people customize sidebar items (1.2). Control Center supports adding, removing,
rearranging, and resizing items, plus "Copy to Menu Bar" (Control Center guide
above). iStat Menus and Bartender let the user choose where each item appears (see
a). SwiftBar shows one menu bar item per plugin, and its maintainer says a
toolbar-like set of 6 controls would need 6 plugins and calls the result "ugly"
(https://github.com/swiftbar/SwiftBar/discussions/417). The HIG says to "let people
— not your app — decide" what goes in the menu bar, and the system may hide extras
(https://developer.apple.com/design/human-interface-guidelines/the-menu-bar).

### Q5. Apple's own multi-function surfaces

- **Control Center:** a grid where each item shows its state and one action, with
  more options one level down. Users can customize it and copy items to the menu
  bar. Lesson: status plus one action at the top level, one level of depth, and
  user-controlled membership.
- **System Settings:** a scrolling sidebar in a resizable window, holding dozens of
  panes. Lesson: a sidebar is Apple's choice for *many areas in a window*, not in a
  transient surface.
- **Notification Center widgets:** widgets are "glanceable", should "deep link to
  details", and should "avoid creating app-like layouts"
  (https://developer.apple.com/design/human-interface-guidelines/widgets). Clicking
  a widget opens the related app
  (https://support.apple.com/guide/mac-help/get-notifications-mchl2fb1258f/mac).
  Lesson: home rows should be glanceable status that links into the full feature.
- **Spotlight:** typing comes first, Command-1/2/3 switch modes, quick keys run
  actions, and Escape returns to search
  (https://support.apple.com/en-am/guide/mac-help/mchl4953dfeb/mac). Lesson: at 10+
  features, type-to-filter and number shortcuts cost little and help a lot.

## Comparison

"Clicks" counts clicks after the popover is open. "Restore" means the popover
reopens on the last feature used.

| Option | Comfortable count | Clicks to a feature | Keyboard | Other features' status while in one | Popover size | Complexity |
| --- | --- | --- | --- | --- | --- | --- |
| Current accordion | 3–4 | 1 | Tab, Return | Collapsed cards only, pushed down | 320 × grows | Exists |
| Full sidebar in popover | 8–15 | 1 | ↑↓, ⌘1–9 | Yes (sidebar badges) | ~520 × 400+ | Med–high |
| Icon rail (vertical tabs) | 6–10 | 1 | ⌘1–9, ↑↓ | Yes (dots on icons) | ~370 | Medium |
| Top icon tab bar | ≤5–6 | 1 | ⌘1–n | Dots on icons | 320 | Low |
| Home list → drill-in | 10–15 | 1, or 0 with restore | ↑↓ Return, Esc, ⌘1–9 | Home only; strip in detail | 320 | Low–med |
| Search-first + pins | 15+ | 0–1, or type 2–3 keys | Excellent | Results only | 320 | Medium |
| Popover + sidebar window | Unlimited | Window: 2+ | ⌘, then sidebar | In popover | Any | Low–med |
| Per-feature status items | Any | 0 (own icon) | Global hotkeys | In menu bar | Per item | High |

## Recommendation for HandyBar

**R1. Home list that drills into one feature (recommended).** Keep the 320 pt
width. The home view lists one compact row per feature, with icon, name,
glanceable status, and an optional inline primary action (Start/Stop). Clicking a
row replaces the home view with that feature's full view and a "‹ All" back button,
animating the height change (2.1). Reopening the popover restores the last
feature. Escape goes back to home, and a second Escape closes the popover. A small
strip in the detail header shows any *other* feature that is running or alerting,
for example "● Auto Click": click it to stop or switch. Only the selected
feature's view is built, which keeps idle cost low (ADR 0001).

```
 Home                                   Feature (after clicking Alarm)
+------------------------------- [gear]+   +-- < All   Alarm ---- (*) Auto Click [stop]+
| [ Filter features...      ]  (10+ only)|  | [ Add alarm, e.g. 7:30            ]       |
| PINNED                                 |  |  07:30  Standup   Weekdays        (on)    |
| [alarm] Alarm       Next 07:30 Mon   > |  |  09:00  Alarm     Once            (off)   |
| [click] Auto Click  (*) Running [Stop]>|  |  ...                                      |
| [clean] Cleanup     Ready            > |  |                                           |
| ALL FEATURES  (shown at 10+)           |  +-------------------------------------------+
| [....]  Feature 4   status           > |
+----------------------------------------+
```

**Popover (task, temporary):** status rows, one primary action per row, the feature
view (Alarm list, quick add), the running-state strip, and the gear menu (Settings…,
Quit). **Settings window (management, persistent):** a sidebar with General
first, then one pane per feature; show/hide and reorder features; pins; global
hotkeys; Mole path; Open at login. Use a real `NavigationSplitView` or
`NSSplitViewController` here, where the HIG's sidebar guidance applies (1.2–1.4).
Cleanup's preview and confirmation stay in their own window (menu-bar-ui.md R8).

**How it grows.**
- **3 features:** the current accordion is acceptable. Switching to drill-in now
  avoids a redesign later and fixes the case where the expanded Alarm list pushes
  the other cards down.
- **6 features:** drill-in plus ⌘1–9 shortcuts on rows (shown in tooltips), and a
  Settings pane to hide features.
- **10+ features:** a Pinned section plus All features, type-to-filter on the
  first keystroke (`onKeyPress`), and user reordering. Optionally offer "Show in menu
  bar" for one feature, off by default (f).

**R2. Icon rail (runner-up).** A vertical icon-only tab strip about 48 pt wide,
next to a 320 pt detail, about 370 pt total. Every feature's state stays visible as
a dot or badge while another feature is open, and switching takes one click or
⌘1–9. Costs: icons alone are less discoverable, so it needs tooltips and VoiceOver
labels. It also needs custom focus handling (↑↓ in the rail) and becomes cramped
past about 10 icons without scrolling. Pick this if seeing Auto Click's state while
editing Alarm matters more than width.

```
+------+---------------------------------+
|[alm]*| Alarm                   [gear]  |
|[clk]o| [ Add alarm, e.g. 7:30      ]   |
|[cln] |  07:30  Standup  Weekdays  (on) |
|[...] |  ...                            |
|      |                                 |
+------+---------------------------------+
  * = selected   o = running
```

**Other alternatives and trade-offs**
- **Full sidebar in a wider popover (~520 pt), or only in a detached panel:** a
  familiar Mac look with labeled items and room to scale, but it goes against "avoid
  making a popover too big" (2.1) and the HIG's own advice for limited space (1.1).
  It also loses the window behaviors sidebars rely on (1.3–1.5). Reasonable only as
  a detached-panel mode (menu-bar-ui.md 2.5).
- **Top icon tab bar:** the simplest to build, but it hits the six-tab ceiling
  (b) and needs redesigning once more features arrive.
- **Search-first:** the best keyboard speed at 15+ features (Raycast, Spotlight),
  but a blank text field makes a poor first impression for 3–6 features. Use it
  as the 10+ add-on in R1 instead.

## Open questions for the maintainer

1. Switch from the accordion to drill-in now, or only when the 4th feature lands?
2. Is "see other features' status while inside one" a must? If yes, prefer R2 or
   R1's status strip; if no, R1 is enough.
3. Should the popover reopen on the last feature or always on home?
4. Is a popover wider than 320 pt acceptable (about 370 pt for R2)?
5. Which features may show an inline primary action on the home row without
   opening the feature (Start/Stop yes; Cleanup never, per R8)?
6. Should users be able to hide or pin features, and put one feature in its own
   menu bar item?
7. Settings window layout: a sidebar from day one, or a toolbar of panes until
   there are about 6 features?
8. Should global hotkeys open a specific feature's view?
