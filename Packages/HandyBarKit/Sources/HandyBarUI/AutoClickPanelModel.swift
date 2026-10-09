import Foundation

/// Observable model for Auto Click panel UI.
@MainActor
public final class AutoClickPanelModel: ObservableObject {
    @Published public var intervalMilliseconds: Int = 100
    @Published public var clickLimit: Int = 100
    @Published public var isRunning: Bool = false
    @Published public var clicksDone: Int = 0
    @Published public var hasPermission: Bool = false

    public var onStart: (() -> Void)?
    public var onStop: (() -> Void)?
    public var onRequestPermission: (() -> Void)?

    public init() {}

    public func start() {
        onStart?()
    }

    public func stop() {
        onStop?()
    }

    public func requestPermission() {
        onRequestPermission?()
    }
}
