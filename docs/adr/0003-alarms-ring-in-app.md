# Alarms ring in HandyBar, not through system notifications

An Alarm rings by showing a HandyBar window above other windows and Spaces and looping
its sound until the user stops it. System notifications were rejected: their sounds
play once and must be under 30 seconds, Focus and Do Not Disturb silence them, and
the Time Sensitive entitlement that breaks through Focus requires a provisioning
profile, which a self-signed build cannot have. As a result, an Alarm rings only while
the Mac is awake and HandyBar is running; one whose time passes otherwise becomes a
Missed Alarm instead of ringing late. Alarm needs no notification permission.
