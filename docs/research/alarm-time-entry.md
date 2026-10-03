# Setting an Alarm's time

> **Decision:** the maintainer chose large hour and minute numbers (chevrons, scroll
> wheel, arrow keys, typed digits) with ±5 and ±15 minute buttons, always 24-hour, plus
> a suggestion list under quick add. Relative times ("in 10 min") and shortcut chips
> were declined.

Research date: 2026-10-02. Builds on [menu-bar-ui.md](menu-bar-ui.md) (R4, R5) and
[multi-feature-navigation.md](multi-feature-navigation.md). It covers only how a user
sets or changes an Alarm's time in the 340 pt detail column (ADR 0004). Speed figures
marked "est." are this document's own action counts, not measured data.

**Summary.** Setting a time is still hard because HandyBar has two input models that
don't share skills. Quick add is a text field with no visible choices: the user must
recall a format, and it has no answer for "in 10 minutes". Editing uses a segmented
`.field` DatePicker that has no stepper, so a mouse can only select a segment. To change
the value, the user still has to type into small hour and minute segments, which sit
under a large time label that can't itself be edited. Every partial edit also autosaves,
switches the Alarm on, and re-sorts the list, so the row can move while the user is
typing (`AlarmEngine.update` calls `sortAlarms()`). Research and platform guidance agree
on a combination: keep typing, because it is the fastest input
on a Mac, but put visible choices next to it, add relative nudges for small changes, and
offer a click-only absolute picker. The recommended design reuses the quick add parser for
an editable time field in the editor. It adds suggestions while the user types, nudge
buttons (−15, −5, +5, +15 min), arrow-key nudging, and a popover grid of hour and minute
buttons for mouse users. A time change commits on Return or when focus leaves the field,
not on each keystroke.

## Findings

### Q1. Problems with segmented time fields and with free-text-only entry

1.1 SwiftUI `.field` "displays the components in an editable field"; `.stepperField`
adds a stepper that "can increment/decrement the selected component". Without the
stepper, a pointer can select a segment but not change it.
https://developer.apple.com/documentation/swiftui/fielddatepickerstyle ·
https://developer.apple.com/documentation/swiftui/stepperfielddatepickerstyle

1.2 Segment focus: NSDatePicker moves to the next segment when a separator key is
typed (Apple engineers matched this in WebKit's date inputs). Up and Down arrows change
a segment. https://trac.webkit.org/changeset/267281/webkit. Tab moves between internal
segments, and developers report it getting stuck there instead of moving to the next control.
https://stackoverflow.com/questions/55041475/nsdatepicker-nextkeyview. Developers also
report arrow-key glitches in textual NSDatePicker.
https://stackoverflow.com/questions/21269043/nsdatepicker-misbehaving-with-arrow-keys.
Whether one typed digit such as "7" auto-advances to minutes, and how the AM/PM
segment accepts "a" or "p", is not documented: UNCONFIRMED.

1.3 Granularity: HIG suggests a coarser minute interval that divides 60 (for example 15).
https://developer.apple.com/design/human-interface-guidelines/pickers. UIKit exposes
`minuteInterval` (https://developer.apple.com/documentation/uikit/uidatepicker/minuteinterval).
NSDatePicker's documented API has no minute interval, so the macOS field steps by 1
minute. https://developer.apple.com/documentation/appkit/nsdatepicker

1.4 Steppers are hard to hit when small and stacked (Fitts' law). They only suit small
changes from a default, so pair them with a text field and arrow keys.
https://www.nngroup.com/articles/input-steppers/. The HIG agrees: pair a stepper with a
field for large changes, and support Shift-click for 10× steps.
https://developer.apple.com/design/human-interface-guidelines/steppers

1.5 Free text: typing is often the most efficient input, and NN/g recommends allowing it
even when other methods exist. Split per-part dropdowns add clicks.
https://www.nngroup.com/articles/date-input/. A study of date entry found that a single
field with a format hint was fastest and most satisfying, while dropdowns gave fewer
format errors (dates, not times).
https://onlinelibrary.wiley.com/doi/10.1155/2011/202701

1.6 Free text has no affordance. HIG: "offer choices instead of requiring text entry"
and prefill defaults. Placeholder text disappears when the user types, so add a label.
https://developer.apple.com/design/human-interface-guidelines/entering-data ·
https://developer.apple.com/design/human-interface-guidelines/text-fields. On macOS, the
HIG says to use a combo box (text plus a list of choices) when text input needs choices.
https://developer.apple.com/design/human-interface-guidelines/combo-boxes. NN/g
heuristics: recognition rather than recall, plus accelerators for experts.
https://www.nngroup.com/articles/ten-usability-heuristics/

1.7 Locale: formats differ by region ("10/11"), so parsers must honor regional
settings. https://www.nngroup.com/articles/date-input/ ·
https://www.dueapp.com/support/osx/natural-date-input.html. Todoist's Time field rejects
`1300` without a colon, so tolerant parsing isn't universal.
https://www.todoist.com/help/articles/introduction-to-dates-and-time-q7VobO

### Q2. What Apple does

2.1 Clock on Mac: click +, "set the time", then set Repeat, Label, Sound, Snooze, and
click Save. To edit, click the Alarm, adjust it, and click Save.
https://support.apple.com/guide/clock-mac/set-alarms-apdwe31bfcbc/mac. Apple doesn't say
which control is used. AppleInsider says "click on the hour or minute", type the value,
and select AM or PM.
https://appleinsider.com/inside/macos-ventura/tips/how-to-use-the-clock-app-in-macos-ventura.
Another secondary source says scroll wheels, so the exact control is UNCONFIRMED.
Inspect Clock on the maintainer's Mac to settle it.

2.2 iPhone Clock: Apple's guide only says "Set the time".
https://support.apple.com/guide/iphone/set-an-alarm-iph2909d3a74/ios. The HIG says
wheels also accept keyboard entry.
https://developer.apple.com/design/human-interface-guidelines/pickers. Long-pressing
the wheel shows a numeric keypad (secondary, iPhone only).
https://appleinsider.com/articles/21/10/11/how-to-set-an-alarm-on-ios-15-without-scrolling-the-wheel.
SwiftUI `.wheel` isn't available on macOS.
https://developer.apple.com/documentation/swiftui/wheeldatepickerstyle

2.3 Apple Watch: tap AM or PM, tap the hours or minutes, turn the Digital Crown to
adjust, then tap the checkmark. The user selects a component, then adjusts it relatively.
https://support.apple.com/guide/watch/alarms-apd27ce65478/watchos

2.4 HIG macOS: textual date pickers suit "limited space" and "specific date and time
selections". Graphical pickers suit browsing a calendar or "the look of a clock face".
Show pickers in context, below the field or in a popover.
https://developer.apple.com/design/human-interface-guidelines/pickers. Support Full
Keyboard Access. https://developer.apple.com/design/human-interface-guidelines/keyboards

### Q3. Alternatives with evidence

3.1 Dial (Material): "often used for setting an alarm". M3 also says that when space is
constrained, use the input picker instead of a dense dial. It requires an input mode,
separate hour and minute inputs, and AM/PM only on 12-hour clocks.
https://m3.material.io/components/time-pickers/guidelines ·
https://m3.material.io/components/time-pickers/accessibility ·
https://github.com/material-components/material-components-android/blob/master/docs/components/TimePicker.md.
AppKit's graphical style shows a clock face.
https://developer.apple.com/documentation/swiftui/graphicaldatepickerstyle

3.2 Wheels: scrolling pickers are slow when there are many values.
https://www.nngroup.com/articles/date-input/. NN/g also advises against spinning
pickers for wide ranges.
https://media.nngroup.com/media/reports/free/Tablet_Website_and_Application_UX.pdf

3.3 Hour and minute grids or fixed steps: Windows TimePicker `MinuteIncrement="15"` shows
only 00/15/30/45. https://learn.microsoft.com/en-us/windows/apps/design/controls/time-picker.
Design systems recommend a select list, not a time picker, for fixed intervals or
standard durations. https://design.sis.gov.uk/components/inputs/time-input/ ·
https://www.sap.com/design-system/fiori-design-web/v1-136/ui-elements/time-picker/usage

3.4 Presets: Due shows "12 fully customizable buttons" (for example, the next noon or
10 PM) and lets users add or subtract time. It says that "scrolling through the time
picker … is just plain slow". https://www.dueapp.com/. Users can set defaults such as
9am, 12pm, +30 min, and +1 h. https://jshirk.com/blog/due/ (secondary)

3.5 Natural language: Due accepts "4pm", "16:00", and "in 20 mins", follows regional
formats, and selects the detected time on the first Return so the user can check it.
https://www.dueapp.com/support/osx/setting-a-reminder.html. Todoist accepts "6pm" (today,
or tomorrow if passed), "in 2 hours", and "in the evening".
https://www.todoist.com/help/articles/introduction-to-dates-and-time-q7VobO. Things
accepts "2p" and "17d". https://culturedcode.com/things/support/articles/9780167/.
Fantastical previews live and adds on Return.
https://flexibits.com/fantastical/help/adding-events-and-tasks. Notion's `@remind 7pm`
creates a tag that the user clicks to adjust.
https://www.notion.com/help/reminders

3.6 Big digits with nudges: Microsoft's redesigned Windows Clock app lets users type
into large digits, with spin buttons above and below that repeat when held (community
description in Microsoft's WinUI repo).
https://github.com/microsoft/microsoft-ui-xaml/issues/3817. Microsoft's support page
doesn't describe the control: UNCONFIRMED.
https://support.microsoft.com/en-us/windows/apps/how-to-use-alarms-and-timers-in-the-clock-app-in-windows

3.7 Typeahead list: Google Calendar's time fields accept typing and also show a
dropdown of preset times. https://webapps.stackexchange.com/questions/86929. The 15-
or 30-minute step isn't in Google's help: UNCONFIRMED.
https://support.google.com/calendar/answer/72143. Raycast, Linear, and Alarmy weren't
verified from official docs: UNCONFIRMED.

3.8 macOS 14 building blocks: `onKeyPress` (macOS 14),
https://developer.apple.com/documentation/swiftui/view/onkeypress(_:action:);
`accessibilityAdjustableAction`,
https://developer.apple.com/documentation/swiftui/view/accessibilityadjustableaction(_:).
Scroll-wheel input needs AppKit `scrollWheel(with:)` in an `NSViewRepresentable`
(`onScrollPhaseChange` requires macOS 15).
https://developer.apple.com/documentation/appkit/nsresponder/scrollwheel(with:) ·
https://developer.apple.com/documentation/swiftui/view/onscrollphasechange(_:)

### Q4–Q5. Fit and relative times

4.1 Each option is rated in the table below. Accessibility: standard text fields and
buttons work with VoiceOver and Full Keyboard Access for free. Custom digits, grids, or
dials need explicit labels, adjustable actions, and focus handling (3.8, 2.4). M3 says
dials need a text-entry alternative (3.1).

5.1 Relative entry is common in reminder apps (Due, Todoist, Things; 3.5). In HandyBar,
"in 25 min" could still create an ordinary one-time Alarm at now + 25 min, and the
preview would say "Rings today at 19:25". **Domain flag (not decided here):** CONTEXT.md
defines an Alarm as a time of day and says to avoid "Timer, countdown". Users who type
"in 25 min" may expect a countdown that tracks sleep or survives clock changes. A
relative Alarm with repeat days would also make little sense. If relative input is
accepted, the glossary should say that relative entry is only a way to type a time of
day.

## Comparison

Est. actions: K = keystrokes (Return included), C = clicks. A11y = VoiceOver and Full
Keyboard Access effort.

| Option | Set 7:30 | In 10 min | Shift +15 | Mouse only | Errors | Discover | 340 pt | A11y | Build |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Segmented `.field` (now) | ~6 K | math | ~4 K | no | med | low | yes | native | done |
| `.stepperField` | ~6 K | math | 15 C | slow | med | med | yes | native | 1 line |
| Parser field + suggestions | 4–5 K | 5 K* | ~4 K | no | low | med | yes | native | low |
| Nudge buttons ±5/±15 | n/a | n/a | 1 C | yes | low | high | yes | easy | low |
| Preset chips | 1 C if listed | 1 C* | n/a | yes | low | high | 1 row | easy | low |
| Hour + minute grid | 2–3 C | n/a | 1–2 C | yes | low | high | popover | medium | medium |
| Big digits + chevrons + scroll | ~4 K or C | n/a | 3 C | yes | low | med | yes | medium | med-high |
| Dial / clock face | 2 drags | n/a | drag | yes | med | med | tight | poor | high |
| Natural language (full) | 4–5 K | 9 K* | n/a | no | med | low | yes | native | high |

\* Only if relative input is accepted (5.1).

## Recommendation for HandyBar

### Quick add: parser field with a suggestion list (macOS combo box pattern, 1.6)

```
+-- 340 pt -------------------------------------+
| [ 7:3|                               ] [ + ]  |
|   > 07:30  Today                    Return   |
|     19:30  Today                             |
|  Rings today at 07:30                         |
|-----------------------------------------------|
| (empty field) Recent: [07:30] [12:00] [22:15] |
|               Soon*: [+10 min] [+30 min] [+1h]|
+-----------------------------------------------+
* only if relative input is approved (5.1)
```

- Keep `TimeEntry` grammar and the live preview. As the user types, show up to 4
  readings below the field: both AM and PM when the digits are ambiguous, or the next
  quarter-hour slots after a bare hour ("7" → 07:00, 07:15, 07:30, 07:45).
- Keyboard: Down/Up arrows move through suggestions, Return adds the highlighted one (the
  first by default, so today's behavior is unchanged), Esc closes the list, and the label
  after the time is kept.
- Mouse: click a suggestion. When the field is empty, show chips for the 3 most recently
  used times and, only if relative input is approved, +10 min, +30 min, and +1 h. Each
  chip creates an enabled one-time Alarm and offers the existing Undo.
- Errors: keep the inline hint, and add the closest valid reading ("25:00 → did you mean
  23:00?") instead of only showing red text.

### Editing an Alarm: one editable time with nudges and a picker popover

```
+-- 340 pt -------------------------------------+
| 07:30                                  (on)  |
| Standup · Weekdays                            |
| +-------------------------------------------+ |
| | Time  [ 07:30            ] [clock]         | |
| |       [-15] [-5]  [+5] [+15]   min         | |
| | Label [ Standup                    ]       | |
| | Repeat [Weekdays v]                        | |
| |                          [Delete Alarm]    | |
| +-------------------------------------------+ |
+-----------------------------------------------+

[clock] popover (about 260 pt wide, 24-hour; 12-hour shows 1-12 + AM/PM):
+-----------------------------+
|  00  01  02  03  04  05     |
|  06 [07] 08  09  10  11     |
|  12  13  14  15  16  17     |
|  18  19  20  21  22  23     |
|  ------------------------   |
|  :00 :05 :10 :15 :20 :25    |
| [:30]:35 :40 :45 :50 :55    |
+-----------------------------+
```

- Replace the DatePicker with a text field that uses the same parser as quick add, so
  there's one skill to learn. It is prefilled with the time and selects all on focus.
  Typing "745" or "7:45p" then Return or Tab commits. Esc reverts. While the text is
  invalid, show the quick add hint and keep the old time.
- Commit on Return or when focus leaves the field, not on each keystroke. That fixes the
  row jumping when the list re-sorts and stops partial times from turning the Alarm on.
- Clicking the large time in the row expands the editor and focuses the time field,
  so one click lands on the thing the user wanted to change.
- Keyboard in the field: Up and Down nudge ±5 min, Shift+Up and Shift+Down nudge ±1 h
  (HIG Shift for larger steps, 1.4), and Tab goes to Label. Nudge buttons are normal
  buttons, so Full Keyboard Access reaches them.
- Mouse: nudge buttons commit right away, are at least 28 pt wide, and are spaced
  horizontally (1.4). [clock] opens a popover. Click an hour, then a minute; the minute
  click commits and closes the popover. The selected hour and minute are highlighted,
  and arrow keys move inside the grid.
- VoiceOver: label the field "Alarm time", add an adjustable action that steps ±5 min,
  and label buttons "15 minutes earlier" and so on. Label grid buttons with the spoken
  time.
- Build: low to medium. The field and nudges use SwiftUI `TextField`, `onKeyPress`, and
  `popover`. The grid is a `Grid` of buttons. Test that a SwiftUI popover opens correctly
  from inside the panel `NSPopover`: UNCONFIRMED.

### Alternatives

- **Minimal: switch to `.stepperField`.** It is a one-line change and gives mouse users
  a way to change the value. The stepper is still tiny, steps by 1 minute (1.3, 1.4), and
  keeps the segmented-field problems and the two input models.
- **Big-digit control (Windows Clock style, 3.6).** Hour and minute are separate large
  digits in the row itself. They show chevrons above and below on hover, accept typing,
  and change when the user scrolls over them (watch-crown analogue, 2.3). It feels most
  like an alarm clock and fits 340 pt, but it is a custom control with focus,
  VoiceOver, and scroll-wheel work (3.8). It also doesn't reuse the quick add parser.
- **Presets-first (Due style, 3.4).** Show a grid of 6–12 user-set times plus relative
  offsets. It is the fastest way to repeat common times by mouse, but it needs settings
  for presets and still needs a typed fallback for times not in the grid.

## Open questions for the maintainer

1. Should HandyBar accept relative input ("in 25 min", "+10m") that creates a time-of-day
   Alarm? If so, should CONTEXT.md say so (5.1)?
2. Which nudge steps should HandyBar use: ±5 and ±15 min, ±1 and ±10 min, or ±15 min and
   ±1 h? Should the arrow keys use the same steps?
3. Should time edits commit on Return or blur, while label and repeat keep autosaving?
   Or should the editor keep the row in place until it closes?
4. Should the empty quick add field show recent times? Or should the user pick favorite
   times, which would need Settings?
5. Should the hour grid follow the system 12- or 24-hour setting, or always be 24-hour?
6. Can someone inspect Clock on this Mac to confirm which time control Apple uses (2.1)?
