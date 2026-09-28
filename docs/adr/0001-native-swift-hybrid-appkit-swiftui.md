# Native Swift with an AppKit shell and SwiftUI panels

HandyBar is written in Swift. AppKit owns the app lifecycle and the menu bar item
(`NSStatusItem` with `NSPopover`), SwiftUI renders panel content, and the Alarm,
Auto Click, and Cleanup logic is plain Swift with no UI dependency. Resource use
while idle is a primary concern, and this split lets the panel's SwiftUI views be
created only while the panel is open, keeps timing-sensitive work measurable apart
from the UI, and avoids requiring `MenuBarExtra` and its minimum macOS version.

## Considered Options

- **SwiftUI with `MenuBarExtra`**: less control over panel lifetime and requires macOS 13.
- **AppKit only**: slightly lower memory, but slower UI development for little gain.
- **Rust core behind FFI**: the workload is timers, system events, and launching Mole,
  not computation, so Rust adds an FFI boundary, a second toolchain, and a second
  language for contributors without a measurable benefit.
- **Web UI (Tauri/Electron)**: a WebView costs more memory than native views and
  every system API would still need a native bridge.
