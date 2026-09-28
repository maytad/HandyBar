# Permissions and data

HandyBar has no runnable release yet. This document describes the intended
behavior to implement and verify, not a claim about an existing app.

## Permissions

| Feature | Planned access | Purpose |
| --- | --- | --- |
| Alarm | Notification permission | Deliver alerts and sounds if system notifications are selected. |
| Auto Click | Accessibility permission | Generate mouse clicks under the user's control. |
| Cleanup | File access or administrator authorization required by the selected Mole command | Let Mole perform the user-requested cleanup. |

Request permissions when the relevant feature needs them and explain their purpose.
The exact prompts depend on the chosen implementation, macOS version, and Mole
version. Verify them on supported macOS versions before documenting them as final.

## Auto Click

Start only on the user's command. Provide a clearly visible running state and
a reliable stop control, including a shortcut usable outside HandyBar's panel.
Define click targets and stop behavior before implementation. Input recording
and screen recording are outside the initial scope.

## Cleanup

Invoke the user's separately installed [Mole CLI](https://github.com/tw93/Mole).
Let Alarm and Auto Click remain usable when Mole is missing; explain the missing
dependency when the user opens Cleanup.

Show the intended cleanup through Mole's supported preview/dry-run behavior before
requesting confirmation to delete files. Explain which command will run and retain
Mole's authorization prompts. Cleanup must not start automatically on app launch.
HandyBar must not collect or store administrator passwords.

The cleanup categories, exclusions, logs, and authorization requirements belong
to the installed Mole version. Document the supported version and actual command
behavior before release; do not promise that every deleted file can be restored.

## Data handling

The initial design keeps alarm and auto-click settings locally on the Mac.
Accounts, cloud synchronization, analytics, and telemetry are outside the initial
scope. Specify the actual storage location and deletion procedure once implemented.

Command output may contain local paths or other personal information. Keep any
captured output local, avoid logging secrets, and require deliberate user action
before sharing diagnostics. Explain any future network access before adding it.
Mole's own behavior and logs must be documented separately from HandyBar's.

Review this document against the app and supported Mole version before a release.
