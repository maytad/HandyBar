import Foundation
import HandyBarUI
import Testing

@MainActor
private final class FakeLoginItem: LoginItemService {
    struct Failure: Error {}

    var status = LoginItemStatus.disabled
    var statusAfterRegister = LoginItemStatus.enabled
    var failsToRegister = false
    var calls: [String] = []

    func register() throws {
        calls.append("register")
        if failsToRegister { throw Failure() }
        status = statusAfterRegister
    }

    func unregister() throws {
        calls.append("unregister")
        status = .disabled
    }

    func openSystemSettings() {
        calls.append("openSystemSettings")
    }
}

@MainActor
struct OpenAtLoginModelTests {
    private let service = FakeLoginItem()
    private let defaults = UserDefaults(suiteName: "OpenAtLoginModelTests-\(UUID())")!

    private func model() -> OpenAtLoginModel {
        OpenAtLoginModel(service: service, defaults: defaults)
    }

    @Test func isOffByDefault() {
        #expect(!model().isEnabled)
        #expect(service.calls.isEmpty)
    }

    @Test func switchingOnAndOffRegistersAndUnregisters() {
        let model = model()
        model.setEnabled(true)
        #expect(model.isEnabled)
        model.setEnabled(false)
        #expect(!model.isEnabled)
        #expect(service.calls == ["register", "unregister"])
    }

    @Test func followsChangesMadeInSystemSettings() {
        let model = model()
        service.status = .enabled
        model.refresh()
        #expect(model.isEnabled)
    }

    @Test func explainsWhenMacOSNeedsApproval() {
        service.statusAfterRegister = .requiresApproval
        let model = model()
        model.setEnabled(true)
        #expect(model.needsApproval)
        model.openSystemSettings()
        #expect(service.calls.last == "openSystemSettings")
    }

    @Test func reportsAFailedRegistration() {
        service.failsToRegister = true
        let model = model()
        model.setEnabled(true)
        #expect(!model.isEnabled)
        #expect(model.errorMessage != nil)
    }

    @Test func suggestsOnTheFirstAlarmOnlyOnce() {
        let model = model()
        model.firstAlarmCreated()
        #expect(model.isSuggesting)
        model.declineSuggestion()
        #expect(!model.isSuggesting)
        model.firstAlarmCreated()
        #expect(!model.isSuggesting)
        let relaunched = self.model()
        relaunched.firstAlarmCreated()
        #expect(!relaunched.isSuggesting)
    }

    @Test func acceptingTheSuggestionTurnsItOn() {
        let model = model()
        model.firstAlarmCreated()
        model.acceptSuggestion()
        #expect(model.isEnabled)
        #expect(!model.isSuggesting)
    }

    @Test func doesNotSuggestWhenAlreadyOn() {
        service.status = .enabled
        let model = model()
        model.firstAlarmCreated()
        #expect(!model.isSuggesting)
    }
}
