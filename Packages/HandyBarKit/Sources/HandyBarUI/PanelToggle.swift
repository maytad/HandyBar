/// Decides what a click on the menu bar item does to the panel.
///
/// A transient popover keeps reporting itself as shown while its close animation
/// runs, so a click during that animation must not be read as "close".
public struct PanelToggle: Sendable {
    public enum Command: Equatable, Sendable {
        case show
        case close
        case none
    }

    private enum Phase {
        case closed
        case shown
        case closing
    }

    private var phase = Phase.closed
    private var reopenWhenClosed = false

    public init() {}

    public mutating func click() -> Command {
        switch phase {
        case .closed:
            phase = .shown
            return .show
        case .shown:
            return .close
        case .closing:
            reopenWhenClosed = true
            return .none
        }
    }

    public mutating func willClose() {
        phase = .closing
    }

    public mutating func didClose() -> Command {
        phase = .closed
        guard reopenWhenClosed else { return .none }
        reopenWhenClosed = false
        phase = .shown
        return .show
    }
}
