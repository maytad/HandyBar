/// A time of day to the minute, on a 24-hour clock.
public struct ClockTime: Equatable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    /// Moves the time by `minutes`, wrapping around midnight.
    public func adding(minutes: Int) -> ClockTime {
        let total = ((hour * 60 + minute + minutes) % 1440 + 1440) % 1440
        return ClockTime(hour: total / 60, minute: total % 60)
    }
}

/// Typing digits into the hour or minute of a time, one key at a time.
public struct ClockDigitTyping: Sendable {
    public enum Component: Sendable {
        case hour
        case minute
    }

    public struct Result: Equatable, Sendable {
        public var value: Int
        /// No further digit could make a valid value, so focus can move on.
        public var isComplete: Bool

        public init(value: Int, isComplete: Bool) {
            self.value = value
            self.isComplete = isComplete
        }
    }

    public let component: Component
    private var pending: Int?

    public init(component: Component) {
        self.component = component
    }

    private var maximum: Int { component == .hour ? 23 : 59 }

    public mutating func type(_ digit: Int) -> Result {
        if let first = pending {
            pending = nil
            let value = first * 10 + digit
            return Result(value: value <= maximum ? value : digit, isComplete: true)
        }
        if digit * 10 > maximum {
            return Result(value: digit, isComplete: true)
        }
        pending = digit
        return Result(value: digit, isComplete: false)
    }
}
