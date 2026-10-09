import Foundation
import CoreGraphics

/// Repeated mouse clicks performed automatically under the user's control.
public enum AutoClick {
    public static let isAvailable = true
}

/// Configuration for Auto Click behavior.
public struct AutoClickSettings: Sendable, Equatable {
    /// Minimum allowed interval in milliseconds.
    public static let minimumInterval = 10
    /// Maximum allowed interval in milliseconds (1 hour).
    public static let maximumInterval = 3_600_000

    /// Time between clicks in milliseconds.
    public var intervalMilliseconds: Int
    /// Maximum number of clicks before automatic stop (0 = unlimited).
    public var clickLimit: Int

    public init(intervalMilliseconds: Int = 100, clickLimit: Int = 100) {
        self.intervalMilliseconds = max(Self.minimumInterval, min(intervalMilliseconds, Self.maximumInterval))
        self.clickLimit = max(0, min(clickLimit, 1000))
    }
}

/// A click command emitted by the engine.
/// The click is posted at the current cursor position.
public struct Click: Sendable, Equatable {
    public init() {}
}

/// Protocol for posting clicks to the system.
public protocol ClickPoster: Sendable {
    func post(_ click: Click)
}

/// Events that drive the Auto Click engine.
public enum AutoClickEvent: Sendable {
    case start(Date)
    case tick(Date)
    case stop
    case userMovedMouse
    case postAccessLost
}

/// Reason why clicking stopped.
public enum StopReason: Sendable, Equatable {
    case manual
    case limitReached
    case mouseMoved
    case permissionLost
}

/// Decides when clicks are posted and when to stop.
///
/// It performs no I/O: the caller owns timers and event monitors.
public struct AutoClickEngine: Sendable {
    public var settings: AutoClickSettings
    private var state: State
    private var lastClicksDone: Int = 0

    private enum State: Sendable {
        case idle(lastStopReason: StopReason?)
        case running(clicksDone: Int, startTime: Date, nextTickAt: Date)
    }

    public init(settings: AutoClickSettings) {
        self.settings = settings
        self.state = .idle(lastStopReason: nil)
    }

    public var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    public var clicksDone: Int {
        if case .running(let done, _, _) = state { return done }
        return lastClicksDone
    }

    public var nextTickAt: Date? {
        if case .running(_, _, let next) = state { return next }
        return nil
    }

    public var stopReason: StopReason? {
        if case .idle(let reason) = state { return reason }
        return nil
    }

    public mutating func handle(_ event: AutoClickEvent, poster: some ClickPoster) {
        switch event {
        case .start(let now):
            let interval = TimeInterval(settings.intervalMilliseconds) / 1000.0
            state = .running(clicksDone: 0, startTime: now, nextTickAt: now.addingTimeInterval(interval))
            lastClicksDone = 0

        case .tick:
            guard case .running(let done, let startTime, _) = state else { return }

            // Post click at current cursor position
            poster.post(Click())
            let newDone = done + 1

            // Check if limit reached
            if settings.clickLimit > 0 && newDone >= settings.clickLimit {
                lastClicksDone = newDone
                state = .idle(lastStopReason: .limitReached)
                return
            }

            // Schedule next tick based on start time to maintain average rate
            let interval = TimeInterval(settings.intervalMilliseconds) / 1000.0
            let nextTick = startTime.addingTimeInterval(interval * TimeInterval(newDone + 1))
            state = .running(clicksDone: newDone, startTime: startTime, nextTickAt: nextTick)

        case .stop:
            if case .running(let done, _, _) = state {
                lastClicksDone = done
                state = .idle(lastStopReason: .manual)
            }

        case .userMovedMouse:
            if case .running(let done, _, _) = state {
                lastClicksDone = done
                state = .idle(lastStopReason: .mouseMoved)
            }

        case .postAccessLost:
            if case .running(let done, _, _) = state {
                lastClicksDone = done
                state = .idle(lastStopReason: .permissionLost)
            }
        }
    }
}
