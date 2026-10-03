# What to add to Alarm next

Research date: 2026-10-03. Scope: which features HandyBar's Alarm should gain after
issue #9, ranked by value, cost, and fit with ADR 0003 (alarms ring in HandyBar, not
through notifications), `docs/permissions-and-data.md` (Alarm needs no permissions),
and issue #9's Out of Scope list. It builds on [menu-bar-ui.md](menu-bar-ui.md) and
[multi-feature-navigation.md](multi-feature-navigation.md) for where controls live
(sidebar panel, Settings window per feature; ADR 0004), and on
[alarm-time-entry.md](alarm-time-entry.md) for the time editor. Sources are Apple,
Google, and Microsoft help pages, Apple developer docs and macOS SDK headers, and the
first-party sites or App Store listings of macOS alarm apps. Bracketed numbers refer to
the numbered Sources list at the end, which gives each URL. "Not documented" means the source is silent,
not that the feature is missing.

**Summary.** HandyBar's Alarm already matches the core of every clock app checked:
labelled time-of-day alarms, weekday repeats, per-alarm sound, snooze, and an on/off
switch. Its distinctive parts (a ringing window that ignores Focus, the volume boost,
Missed Alarms) go beyond Apple's Mac Clock, which rings through a notification [1]. The
clearest gaps against Apple, Google, and Mac peers are a choice of snooze length [1][4][9][14],
a way to skip or pause a repeating alarm without switching it off [5][7][8], and a
gradual fade-in [9][14][15]. All three are small, need no permissions, and fit the engine
seam. The biggest reliability gap, alarms missed while the Mac sleeps, can't be fixed
without root [17][20], and Alarm Clock Pro's manual shows that even scheduled wakes can
fall back to sleep at the login screen [13]. A cheaper, permission-free option is an
opt-in idle-sleep assertion, which stops idle sleep but not lid-close sleep [18][19].
Recommended next, in order: per-Alarm snooze length, Skip next, fade-in, and an opt-in
"keep the Mac awake" switch. Countdown timers are common [2][9][11][12][14] but should be a
separate feature, not part of Alarm.

## Current baseline

HandyBar column verified against `HandyBarAlarm` (`Alarm`, `AlarmEngine`, `VolumeBoost`),
`AlarmView`, `RingingView`, `AlarmController`, and `RingingPresenter`. "—" = not documented.

| Capability | HandyBar | Mac Clock | iPhone Clock | Android Clock | Windows Clock | Alarm Clock Pro (Mac) | Awaken (Mac) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Repeat | Once or chosen weekdays | Weekdays [1] | Weekdays [4] | Weekdays [8] | — [11] | Daily, weekly, nth weekday, monthly, date, hourly [13] | One-time, repeating, specific date [14] |
| Snooze | Fixed 5 min | Per alarm: on/off + duration [1] | Per alarm: on/off + duration [4] | Global length; default 10 min [8][9] | Snooze button [11] | Per-alarm list of intervals, one per press [13] | Duration and a limit [14] |
| Auto-stop | 15 min, then Missed | — | — | "Silence after" setting [9] | — | — | — |
| Skip / pause | Switch off only | Switch off only [1] | Sleep wake-up: "Change Next Alarm Only" [5] | Pause a repeating alarm for chosen dates [8] | — | Date exclusions requested by users [13] | — |
| Volume | Boost output to 50%, restore | — | Alarm volume slider [4] | Volume slider, gradual increase [9] | — | Audio fader [12] | Volume and brightness fade-in [14] |
| Sounds | 5 synthesized built-ins | Choose a sound [1] | Ringtone, song, vibration [4] | Device sounds, own file, music apps [8] | — | Apple Music, jingles, import, web radio [12] | Apple Music, built-ins, Read Aloud [14] |
| How it rings | Own window above all Spaces | Notification [1] | Rings in Silent and Focus [4] | Needs Clock notifications on [8] | Notification; device must be awake [11] | On-screen alert, media [12] | Full-screen view; system-alert fallback [14] |
| Mac asleep | Missed, never late | — | n/a | n/a | Doesn't ring [11] | Wakes Mac (not App Store build) [13] | "Re-syncs your alarms" on wake [14] |
| Timers / stopwatch | No | Both [2][3] | Timer [4] | Timer settings [9] | Timers [11] | Both [12] | Countdown + sleep timer [14] |
| Actions on ring | No | — | — | Assistant Routine [8] | — | URLs, files, shell, email, speech [12] | — |
| Automation | No | Siri [1] | Siri [4] | Assistant [8] | — | AppleScript [13] | — |

## Findings

### 1. Countdown timers and stopwatch

1.1 Every platform clock separates Timers from Alarms. Mac Clock has Alarms, Stopwatch,
and Timers views; timers run several at once, have presets and recents, keep counting
while the Mac sleeps, and can end by stopping playback [2][3]. Windows ships four preset
timers next to alarms [11]; Android has its own timer sound and fade settings [9].
Alarm Clock Pro and Awaken both bundle timers [12][14].

1.2 Fit: CONTEXT.md says "Avoid: Timer, countdown" for Alarm, issue #9 lists "Countdown
timers" as out of scope, and the README says more features need an explicit scope
decision. A timer is a duration, not a time of day, and Apple says Mac Clock timers
continue through sleep [2], while HandyBar Alarms don't ring late. Those are different
rules. Ringing would be the same: the ringing window, sounds, and volume boost could be
reused, and no permissions are needed.

1.3 Cost: M for a separate sidebar feature with its own engine (deadline = start +
duration, pause/resume, ends late or missed after sleep). Risk: if it's added inside
Alarm, quick add ("in 25 min") blurs the domain, a risk alarm-time-entry.md already
flags (5.1).

### 2. Snooze length, per-alarm snooze, snooze limits

2.1 Apple lets each alarm turn Snooze on or off and pick a duration on Mac, iPhone,
and Watch [1][4][7]. The Watch guide calls turning it off "Don't let yourself snooze" [7].
Android sets one global "Snooze length" (default 10 minutes) and a "Silence after"
time [8][9]. Alarm Clock Pro keeps a per-alarm list of intervals and uses the next one
on each press [13]. Awaken has a duration and a snooze limit [14]; Wake Up Time has a
"customizable alarm snooze time" [15].

2.2 Fit: issue #9 lists "Configurable snooze length or auto-stop duration" as out of
scope, so this needs a scope change. No permissions. The engine already has
`snoozeInterval` as a constant, and `PendingSnooze` holds one `ringsAt` for every
snoozed Alarm. Per-alarm lengths need a rule for a shared Ringing set: the shortest
length, or the first Alarm's. The Ringing window's "Snooze 5 min" label would show the
chosen value.

2.3 Cost: S for per-Alarm length plus "Off" (hides Snooze, Esc does nothing). S+ for a
limit, which needs a per-Alarm snooze count in `Snapshot`. Risk: an Alarm with Snooze
off plus the 15-minute auto-stop is the only way to miss it unattended. That's fine,
but the row should show it.

### 3. Skip next occurrence, pause, holidays

3.1 Apple offers skipping only for sleep-schedule wake-up alarms: "Change Next Alarm
Only" on iPhone [5] and "Skip for Tonight" on Watch [7]. Regular Clock alarms can only
be switched off, which Apple suggests "while you're traveling" [1]. Android can pause a
repeating alarm for chosen calendar dates [8]. Alarm Clock Pro users ask for date
exclusions with ranges and for holiday or weekend exclusion presets [13] (feature
request list, not shipped).

3.2 User value: for a weekday Alarm, switching it off on Friday means remembering to
switch it on for Monday. Skip next removes that step. Fit: it isn't on the out-of-scope
list and needs no permissions. CONTEXT.md says to avoid "Skipped alarm" as a synonym
for Missed Alarm, so the UI should use "Skip next" or "Skip once", and the glossary
should say how it differs from a Missed Alarm.

3.3 Cost: S for Skip next (store the skipped occurrence date; `nextOccurrence` jumps
past it; it clears once that time passes, or on edit). M for a date-range pause (date
picker, plus a rule for when the range ends while the Mac sleeps). Holiday calendars
need Calendar access (a new permission) or bundled data: L.

### 4. Gradual volume increase and per-alarm volume

4.1 Android has "Gradually increase volume" for alarms and timers [9]. Awaken has
"gentle volume and screen-brightness fade-in" with configurable fade durations [14].
Wake Up Time fades volume [15], and Alarm Clock Pro has an audio fader [12]. iPhone has
one alarm volume slider [4]; sleep-schedule alarms set volume per schedule [5][6].

4.2 Fit: HandyBar plays each Alarm with `AVAudioPlayer`, which has
`setVolume(_:fadeDuration:)` (macOS 10.12+) [25]. A fade changes only the player's
volume, so the permissions doc's rule (raise the output device to 50%, then restore)
stays as it is. No permissions, and the engine doesn't change.

4.3 Cost: S. Risk: a fade from silence delays audible ringing. Start at about 20% of
full and reach full within 30 to 60 seconds. Per-alarm volume isn't recommended: with
the 50% boost, a quiet per-alarm level could make the Alarm inaudible.

### 5. Custom sound files, system sounds, Music

5.1 Android accepts device sounds, the user's own files, and songs from YouTube Music,
Pandora, Spotify, or Calm [8]. Apple Clock offers ringtones and songs on iPhone [4] and a
sound list on Mac [1]. Alarm Clock Pro and Awaken use Apple Music, and Alarm Clock Pro
imports files and plays web radio [12][14]. Awaken's release notes mention requesting
permission to find AirPlay speakers on the network [14].

5.2 Fit: issue #9 decided "No system sounds or custom files" and lists "Choosing or
importing sounds" as out of scope. `NSSound` and `AVAudioPlayer` can loop any Core Audio
file [26][27], so files or `/System/Library/Sounds` cost S to M. Music needs a media
permission or network access, which the permissions doc doesn't allow without an update.
Risks: a moved or deleted file needs a fallback to a built-in; a quiet or very short file
weakens the alarm.

### 6. Waking the Mac from sleep, keeping it awake

6.1 `IOPMSchedulePowerEvent` can schedule a wake or power-on, stores the event on disk,
and "Must be called as root" [17]. `pmset schedule` and `pmset repeat` do the same and
must run as root to change settings; `repeat` allows only one power-on and one power-off
pair [20]. Apple's guide uses `sudo pmset repeat wake` [20].

6.2 Alarm Clock Pro wakes the Mac "a few minutes prior" to alarms, but says the feature
isn't in the App Store build "due to Apple's restrictions". It also warns that the Mac
may ask for a password at wake and go back to sleep after 60 seconds, so the ring is
skipped [13]. Wake Up Time asks users to download a separate "sleep helper" [15].
Windows Clock says alarms only show if the device is awake [11].

6.3 Keeping awake doesn't need root: "No special privileges are necessary" for
`IOPMAssertionCreateWithName` [18]. `kIOPMAssertPreventUserIdleSystemSleep` stops idle
sleep, but "the system may still sleep for lid close, Apple menu, low battery, or other
sleep reasons" (SDK `IOPMLib.h` [19]). Users can already prevent automatic sleep on
power adapter in System Settings [41]. Awaken offers "Keep Screen Awake" [14].

6.4 Fit: waking the Mac is out of scope in issue #9, and root means a privileged helper
plus an admin prompt, which conflicts with "Alarm: None" in the permissions doc. An opt-in
idle-sleep assertion fits better: no prompt, no root. It changes power behavior, though,
and the permissions doc says HandyBar "changes no other system settings". An assertion
isn't a setting, but the doc should mention it. Cost: M (the engine reports "an Alarm
that keeps the Mac awake is pending", and the app target holds or releases the
assertion). Risks: battery drain overnight on a laptop, and a closed lid still sleeps.
The UI must say that the Mac still sleeps when the lid is closed.

### 7. Notifications as backup, Time Sensitive, Focus

7.1 Time Sensitive notifications "break through system controls such as Notification
Summary and Focus", and users can turn that off [21]. Critical alerts need an approved
entitlement [22]. Notification sounds must be under 30 seconds, or the default sound
plays [23]. The HIG reserves Time Sensitive for alerts relevant in the moment [24].
Mac Clock itself rings through a notification [1]. Awaken has a "system-alert fallback" [14].

7.2 Fit: ADR 0003 rejected notifications for these reasons, and the Time Sensitive
entitlement needs a provisioning profile that a self-signed build can't have (ADR 0003).
A plain notification as a second channel would add the notification permission, and
Focus would silence it. HandyBar's in-app window already rings during Focus. Not
recommended. App Intents' `SetFocusFilterIntent` (macOS 13+) could let a Focus mute
selected Alarms [29], but that inverts the "never silenced" user story 17 in issue #9.

### 8. Specific dates, every N days or weeks, monthly

8.1 Apple and Google clock alarms repeat by weekday only [1][4][8]; Microsoft's page
doesn't describe repeat options [11].
Alarm Clock Pro has weekly (with "first Friday of a month"), monthly, specific-date, and
hourly alarms [13]. Its feature request list asks for "every X days/weeks/months/years" and
"last day of month" [13]. Awaken has date-specific alarms [14].

8.2 Fit: CONTEXT.md defines Repeat days as weekdays, so this is a domain change. A
specific date ("Friday 3 Oct, 09:00") is the smallest step and covers "one-off
appointment next week". Every N weeks needs an anchor date, plus a rule for what a miss
does to the cycle. Cost: S to M for date, M for interval rules. Engine tests need
calendar edge cases (DST, month length, time zone change).

### 9. Upcoming-alarm notice and "rings in" display

9.1 Android Bedtime can send a bedtime reminder notification and brighten the screen
15 minutes before the alarm ("Sunrise alarm") [10]. Apple Watch Nightstand mode shows
the time of the next alarm [7]. HandyBar's sidebar already shows "Next 7:00 today", and
quick add previews the day.

9.2 Fit: a pre-alarm notice would be a second ringing-like event and a new domain term.
A relative label ("in 7 h 20 min") in the editor is pure UI, with no permissions. Cost:
S, but it has to update while the panel is open, and the README forbids idle timers. A
label that only updates while visible is fine. Value: low to medium.

### 10. Global shortcut, Shortcuts, URL scheme, AppleScript

10.1 Global key monitoring with `NSEvent.addGlobalMonitorForEvents` sees key events only
if the app is trusted for Accessibility [31]. Carbon's `RegisterEventHotKey` registers a
global hot key, and its header lists no permission (SDK `CarbonEvents.h` [32]). App
Intents expose actions to Shortcuts, Siri, and Spotlight on macOS 13+ [28], and users can
assign a keyboard shortcut to a shortcut [35]. Custom URL schemes work but are "a
potential attack vector", so only safe actions should be exposed [30]. Shortcuts itself
can be run by URL or with the `shortcuts run` command [33][34]. Alarm Clock Pro supports
AppleScript and a show-app hot key [13].

10.2 Fit: Stop and Snooze already work by click, Return, and Esc. A global shortcut adds
little, and accidental presses could silence an Alarm, which user story 18 in issue #9
guards against. App Intents ("Create Alarm", "Turn Alarm on/off", "Stop Ringing") need
no new permission, and they would make Shortcuts automations and Focus-based switching
possible. Cost: M. Whether App Intents register for a self-signed app outside
`/Applications`: UNCONFIRMED; test before committing. A URL scheme costs S but needs
input validation [30].

### 11. Actions when an alarm rings

11.1 Android can run a Google Assistant Routine with an alarm [8]. Alarm Clock Pro opens
URLs and files, runs shell commands, sends email and texts, and speaks text [12].
`NSWorkspace.open(_:)` opens a URL [36], and `shortcuts://run-shortcut?name=` runs a
user's shortcut [34].

11.2 Fit: running arbitrary actions from a timer is a security and support burden.
Shell commands also run against the "no surprises" spirit of the permissions doc, and
Apple Events targets would add prompts. A single "Open URL or shortcut when stopped" field
is S, but it turns Alarm into an automation tool. Not recommended now; App Intents (10)
let Shortcuts drive HandyBar instead.

### 12. Duplicate, groups, bulk on/off, sorting

12.1 None of the official guides document duplicate, groups, or bulk toggles; they
document add, edit, switch, and delete [1][4][8]. Android notes that turning off a repeating
alarm "turns all repeats on or off" [8]. HandyBar already sorts by time (issue #9, story 10)
and has Undo delete.

12.2 Fit and cost: Duplicate (context menu) is S and safe. "Turn all off" is S, but
has to say how to undo it. Groups are M and add a domain concept for little gain at a
handful of Alarms. Value: low.

### 13. Bedtime and sleep schedule

13.1 iPhone puts wake-up alarms in Health sleep schedules, with bedtime, wind-down, and
Sleep Focus [6]. Android Clock's Bedtime tab has a reminder, bedtime mode, sunrise alarm,
and sleep sounds [10]. Awaken has a sleep timer that fades music out [14].

13.2 Fit: a Mac usually sleeps overnight, and HandyBar can't ring then (6). A sleep
schedule implies waking, which is out of scope. Not recommended.

### 14. Accessibility: VoiceOver, flashing, speech

14.1 HIG: "Augment audio cues with visual cues" and "Be cautious with fast-moving and
blinking animations" [37]. macOS can "Flash the screen when an alert sound occurs" [40],
but HandyBar's sound is its own audio, not a system alert sound, so that setting probably
won't flash for it (UNCONFIRMED). `NSAccessibility` `announcementRequested` makes
VoiceOver speak a string [38]. `AVSpeechSynthesizer` speaks text on macOS 10.14+ [39].
Alarm Clock Pro and Awaken can speak text when an alarm rings [12][14].

14.2 Fit: no permissions. A VoiceOver announcement of the label when Ringing starts is
S and should ship by default. Speaking the label aloud for everyone (an option) is S; it
needs to share audio with the looping sound. A gentle pulsing border on the ringing
window is S; avoid full-screen strobing [37].

### 15. Missed Alarm history

15.1 No official source checked documents a missed-alarm history. Android only reports
problems such as "Do Not Disturb silenced your alarm" or volume below 30% [8]. Alarm Clock
Pro's manual explains why alarms may not ring after sleep [13].

15.2 Fit: HandyBar stores `missedIDs` and clears them when the panel is opened. A short
history ("Missed Standup at 10:00, Tue — Mac was asleep") would explain misses, but needs
new stored data (the permissions doc lists what's stored) and a cause the engine can tell
apart (asleep vs not running vs unattended). Cost: M. Value: medium for trust in the
feature.

### 16. Import/export and iCloud sync

16.1 The permissions doc puts accounts and cloud sync outside the initial scope, and
issue #9 lists syncing as out of scope. Alarms already live in a documented JSON file.
Export is S but needs a file format contract. Sync is L and adds network access.
Not recommended.

### 17. AlarmKit

17.1 AlarmKit provides system alarms and countdowns with snooze, but it's available on
iOS 26, iPadOS 26, and Mac Catalyst 26 only [16]. HandyBar is an AppKit app targeting
macOS 14, so it can't use AlarmKit.

## Recommendations

Costs: S ≈ a day, M ≈ a few days, L ≈ a week or more including manual checks.

### Next

1. **Per-Alarm snooze length, including Off.** Value: high; Apple has it on every
   platform [1][4][7]. Cost: S. Constraints: lifts "configurable snooze length" from
   issue #9's Out of Scope; no permissions; update CONTEXT.md (Ringing) and the Ringing
   window label. Engine tests: snooze uses the Alarm's length; Off makes `.snooze` a
   no-op; a mixed Ringing set uses the agreed rule; old `alarms.json` decodes with 5 min.
2. **Skip next occurrence for a repeating Alarm.** Value: high for weekday Alarms [5][7][8].
   Cost: S. Constraints: glossary entry distinct from Missed Alarm; stored field in
   `alarms.json` (permissions doc already says Alarms are stored there). Engine tests:
   next deadline jumps one occurrence; skip clears after the skipped time; editing,
   switching off, or deleting clears it; a skipped occurrence is never Missed, even after
   wake or launch; time zone change keeps the skip on the right day.
3. **Gradual fade-in.** Value: medium to high [9][14][15]. Cost: S, using
   `setVolume(_:fadeDuration:)` [25]. Constraints: none in the engine; the permissions
   doc's 50% boost is unchanged. Tests: a fake player in the app target confirms the
   start and target volumes; manual check that the first second is audible.
4. **Opt-in "Keep Mac awake for this Alarm".** Value: medium to high; it is the only
   permission-free answer to missed Alarms during idle sleep [18][19]. Cost: M.
   Constraints: permissions doc needs a line on power assertions; README still true
   ("while the Mac is awake"); UI must say a closed lid still sleeps. Engine tests: the
   engine reports "keep awake" while any opted-in, enabled Alarm is pending, and stops
   after its last occurrence, when it's switched off, or when it's deleted.

### Later

5. **VoiceOver announcement and optional spoken label** [38][39]. S. Tests: none in the
   engine; manual VoiceOver check.
6. **Specific-date Alarms** [13][14]. S–M; changes CONTEXT.md. Engine tests: date in the
   past rejected; DST and time zone moves; missed date Alarm switches off.
7. **Pause a repeating Alarm for a date range** [8]. M; builds on Skip next. Tests: range
   start and end across sleep; edit during range.
8. **Countdown timer as its own feature** [2][9][11]. M–L; needs a README scope decision.
   It would have its own seam, with no change to the Alarm engine.
9. **App Intents for Shortcuts** (create, toggle, stop, snooze) [28][35]. M; verify
   registration for self-signed builds first. Tests: intents call the same engine events.
10. **Missed Alarm history with cause.** M; extends stored data. Engine tests: cause
    recorded for asleep, not running, and unattended.
11. **Duplicate Alarm; snooze limit; configurable auto-stop.** S each; snooze limit and
    auto-stop also touch issue #9's Out of Scope.

### Not recommended

- **Waking the Mac from sleep**: needs root [17][20], so a privileged helper and admin
  prompt; out of scope in issue #9; wakes can still fail at the login screen [13].
- **Notifications as backup or Time Sensitive**: rejected by ADR 0003; the entitlement
  isn't available to a self-signed build; Focus silences plain notifications [21][24].
- **Custom files, system sounds, Apple Music**: reverses issue #9's sound decision;
  Music adds permissions or network access [8][12][14].
- **Actions on ring (URLs, shell, Shortcuts)**: security and scope cost [12][30]; App
  Intents cover automation the other way round.
- **Bedtime or sleep schedule**: relies on waking the Mac [6][10].
- **Global Stop/Snooze shortcut**: little gain over click, Return, and Esc; risks
  accidental silencing; key monitoring needs Accessibility [31].
- **Groups, sync, import/export**: low value at a few Alarms; sync adds network access.
- **AlarmKit**: not available to AppKit apps on macOS [16].

## Open questions for the maintainer

1. Snooze length: (a) keep fixed 5 min, (b) one setting in Settings > Alarm, or
   (c) per Alarm with Off? If (c), does a shared Ringing set use the shortest length or
   the first Alarm's?
2. Which options for snooze length: 5/10/15, 1/5/10/15/30, or free entry?
3. Skip: (a) Skip next only, (b) Skip next plus a date-range pause, or (c) neither?
4. Fade-in: (a) always on, (b) a setting in Settings > Alarm, or (c) per Alarm? Fade
   time: 15, 30, or 60 seconds?
5. Keep awake: (a) not at all, (b) per Alarm opt-in, or (c) one setting for all
   Alarms? On battery: (i) same, or (ii) never hold it on battery?
6. Timers: (a) out of HandyBar, (b) a separate sidebar feature later, or (c) now?
7. Schedules: (a) weekdays only, (b) add specific dates, or (c) also every N weeks?
8. Automation: (a) none, (b) App Intents for Shortcuts, or (c) App Intents plus a URL
   scheme?
9. Accessibility: should a VoiceOver announcement be always on, and should a spoken
   label be (a) off by default or (b) not offered?
10. Missed Alarms: (a) keep today's marks only, or (b) keep a short history with the
    cause, stored in `alarms.json`?

## Sources

1. Apple, Set alarms in Clock on Mac. https://support.apple.com/guide/clock-mac/set-alarms-apdwe31bfcbc/mac
2. Apple, Set timers in Clock on Mac. https://support.apple.com/guide/clock-mac/set-timers-apdw3d5aebf9/mac
3. Apple, Clock User Guide for Mac. https://support.apple.com/guide/clock-mac/welcome/mac
4. Apple, Set an alarm in Clock on iPhone. https://support.apple.com/guide/iphone/set-an-alarm-iph2909d3a74/ios
5. Apple, Change your wake up alarm in Clock on iPhone. https://support.apple.com/guide/iphone/change-your-wake-up-alarm-iphf2a780f81/ios
6. Apple, Set up sleep in Health on iPhone. https://support.apple.com/guide/iphone/set-up-sleep-iphaf56dceb4/ios
7. Apple, Add an alarm on Apple Watch. https://support.apple.com/guide/watch/alarms-apd27ce65478/watchos
8. Google, Set, cancel, or snooze alarms on your Android device. https://support.google.com/clock/answer/2840926
9. Google, Set time, date and time zone (alarm and timer settings). https://support.google.com/clock/answer/2841106
10. Google, Set a bedtime schedule. https://support.google.com/clock/answer/9887159
11. Microsoft, How to use alarms and timers in the Clock app in Windows. https://support.microsoft.com/en-us/windows/apps/how-to-use-alarms-and-timers-in-the-clock-app-in-windows
12. Koingo Software, Alarm Clock Pro 15 (product page). https://www.koingosw.com/products/alarmclockpro/
13. Koingo Software, Alarm Clock Pro manual (includes a user feature-request list). https://www.koingosw.com/products/alarmclockpro/manual.php
14. Embraceware, Awaken 7.1.1, Mac App Store listing (developer's description and release notes). https://apps.apple.com/us/app/awaken/id404221531
15. Rocky Sand Studio, Wake Up Time 1.4 (2015), Mac App Store listing. https://apps.apple.com/us/app/wake-up-time-alarm-clock/id495945638
16. Apple, AlarmKit. https://developer.apple.com/documentation/alarmkit
17. Apple, IOPMSchedulePowerEvent. https://developer.apple.com/documentation/iokit/1557076-iopmschedulepowerevent
18. Apple, IOPMAssertionCreateWithName. https://developer.apple.com/documentation/iokit/1557134-iopmassertioncreatewithname
19. Apple, IOPMLib.h (`kIOPMAssertPreventUserIdleSystemSleep` discussion in the macOS SDK header). https://developer.apple.com/documentation/iokit/iopmlib_h
20. Apple, Schedule your Mac to turn on or off in Terminal, and `man pmset`. https://support.apple.com/guide/mac-help/schedule-your-mac-to-turn-on-or-off-mchl40376151/mac
21. Apple, UNNotificationInterruptionLevel.timeSensitive. https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
22. Apple, Critical Alerts entitlement. https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts
23. Apple, UNNotificationSound. https://developer.apple.com/documentation/usernotifications/unnotificationsound
24. Apple HIG, Managing notifications. https://developer.apple.com/design/human-interface-guidelines/managing-notifications
25. Apple, AVAudioPlayer setVolume(_:fadeDuration:). https://developer.apple.com/documentation/avfaudio/avaudioplayer/setvolume(_:fadeduration:)
26. Apple, AVAudioPlayer numberOfLoops. https://developer.apple.com/documentation/avfaudio/avaudioplayer/numberofloops
27. Apple, NSSound. https://developer.apple.com/documentation/appkit/nssound
28. Apple, App Intents. https://developer.apple.com/documentation/appintents
29. Apple, SetFocusFilterIntent. https://developer.apple.com/documentation/appintents/setfocusfilterintent
30. Apple, Defining a custom URL scheme for your app. https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app
31. Apple, NSEvent addGlobalMonitorForEvents(matching:handler:). https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents(matching:handler:)
32. Apple, `RegisterEventHotKey` in the macOS SDK header `HIToolbox.framework/Headers/CarbonEvents.h` (no current web page).
33. Apple, Run shortcuts from the command line. https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac
34. Apple, Run a shortcut using a URL scheme on Mac. https://support.apple.com/guide/shortcuts-mac/run-a-shortcut-from-a-url-apd624386f42/mac
35. Apple, Run a shortcut while working on your Mac. https://support.apple.com/guide/shortcuts-mac/run-a-shortcut-from-another-app-apd163eb9f95/mac
36. Apple, NSWorkspace open(_:). https://developer.apple.com/documentation/appkit/nsworkspace/open(_:)
37. Apple HIG, Accessibility. https://developer.apple.com/design/human-interface-guidelines/accessibility
38. Apple, NSAccessibility.Notification announcementRequested. https://developer.apple.com/documentation/appkit/nsaccessibility-swift.struct/notification/announcementrequested
39. Apple, AVSpeechSynthesizer. https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer
40. Apple, Accessibility features for hearing on Mac. https://support.apple.com/guide/mac-help/accessibility-features-for-hearing-mchlb4f015b1/mac
41. Apple, Set sleep and wake settings for your Mac. https://support.apple.com/guide/mac-help/set-sleep-and-wake-settings-mchle41a6ccd/mac
