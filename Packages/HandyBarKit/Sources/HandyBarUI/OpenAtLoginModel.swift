import Foundation
import Observation

public enum LoginItemStatus: Sendable {
    case enabled
    case disabled
    /// Registered, but the user must allow it in System Settings > General > Login Items.
    case requiresApproval
}

/// The system login item for HandyBar itself.
@MainActor
public protocol LoginItemService: AnyObject {
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

/// The Open at login switch and the one-time suggestion shown with the first Alarm.
@MainActor
@Observable
public final class OpenAtLoginModel {
    public private(set) var status: LoginItemStatus
    public private(set) var errorMessage: String?
    public private(set) var isSuggesting = false
    @ObservationIgnored private let service: LoginItemService
    @ObservationIgnored private let defaults: UserDefaults

    private static let suggestedKey = "openAtLoginSuggested"

    public init(service: LoginItemService, defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
        status = service.status
    }

    public var isEnabled: Bool { status == .enabled }
    public var needsApproval: Bool { status == .requiresApproval }

    /// Reads the state again, since the user can change it in System Settings.
    public func refresh() {
        status = service.status
    }

    public func setEnabled(_ isEnabled: Bool) {
        errorMessage = nil
        do {
            if isEnabled { try service.register() } else { try service.unregister() }
        } catch {
            errorMessage =
                isEnabled
                ? "HandyBar couldn't be added to Login Items."
                : "HandyBar couldn't be removed from Login Items."
        }
        refresh()
    }

    public func openSystemSettings() {
        service.openSystemSettings()
    }

    public func firstAlarmCreated() {
        refresh()
        guard !defaults.bool(forKey: Self.suggestedKey), status == .disabled else { return }
        defaults.set(true, forKey: Self.suggestedKey)
        isSuggesting = true
    }

    public func acceptSuggestion() {
        isSuggesting = false
        setEnabled(true)
    }

    public func declineSuggestion() {
        isSuggesting = false
    }
}
