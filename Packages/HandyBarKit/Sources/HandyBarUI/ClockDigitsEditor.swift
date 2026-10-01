import AppKit
import HandyBarAlarm
import SwiftUI

/// A 24-hour time as two large numbers. Each number changes by its chevrons, the scroll
/// wheel, the arrow keys, or typed digits; buttons below move the whole time.
struct ClockDigitsEditor: View {
    typealias Component = ClockDigitTyping.Component

    @Binding var time: ClockTime
    var focusOnAppear = false
    var onSubmit: () -> Void = {}

    @FocusState private var focused: Component?
    @State private var typing: ClockDigitTyping?

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                digits(.hour)
                Text(":")
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                digits(.minute)
            }
            HStack(spacing: 6) {
                ForEach([-15, -5, 5, 15], id: \.self) { minutes in
                    Button(minutes > 0 ? "+\(minutes)" : "−\(-minutes)") {
                        time = time.adding(minutes: minutes)
                    }
                    .frame(minWidth: 44)
                    .accessibilityLabel(
                        "\(abs(minutes)) minutes \(minutes > 0 ? "later" : "earlier")")
                }
                Text("min").font(.caption).foregroundStyle(.secondary)
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .onAppear { if focusOnAppear { focused = .hour } }
        .onChange(of: focused) { typing = nil }
    }

    private func value(_ component: Component) -> Int {
        component == .hour ? time.hour : time.minute
    }

    private func step(_ component: Component, by amount: Int) {
        time = time.adding(minutes: component == .hour ? amount * 60 : amount)
    }

    private func digits(_ component: Component) -> some View {
        let isFocused = focused == component
        return VStack(spacing: 2) {
            chevron("chevron.up", component, by: 1)
            Text(String(format: "%02d", value(component)))
                .font(.system(size: 40, weight: .medium, design: .rounded).monospacedDigit())
                .frame(width: 76, height: 54)
                .background(
                    isFocused
                        ? AnyShapeStyle(Color.accentColor.opacity(0.2))
                        : AnyShapeStyle(.quaternary.opacity(0.6)),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .overlay {
                    if isFocused {
                        RoundedRectangle(cornerRadius: 10).strokeBorder(
                            Color.accentColor, lineWidth: 2)
                    }
                }
                .background(ScrollWheelReader { step(component, by: $0) })
                .contentShape(Rectangle())
                .onTapGesture { focused = component }
                .focusable(interactions: .edit)
                .focusEffectDisabled()
                .focused($focused, equals: component)
                .onKeyPress(phases: .down) { press in handle(press, component) }
                .accessibilityElement()
                .accessibilityLabel(component == .hour ? "Hour" : "Minute")
                .accessibilityValue("\(value(component))")
                .accessibilityAdjustableAction { direction in
                    step(component, by: direction == .increment ? 1 : -1)
                }
            chevron("chevron.down", component, by: -1)
        }
    }

    private func chevron(_ symbol: String, _ component: Component, by amount: Int) -> some View {
        Button {
            step(component, by: amount)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 76, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .buttonRepeatBehavior(.enabled)
        .accessibilityHidden(true)
    }

    private func handle(_ press: KeyPress, _ component: Component) -> KeyPress.Result {
        switch press.key {
        case .upArrow:
            step(component, by: 1)
        case .downArrow:
            step(component, by: -1)
        case .leftArrow:
            focused = .hour
        case .rightArrow:
            focused = .minute
        case .return:
            onSubmit()
        default:
            guard let digit = press.characters.first?.wholeNumberValue else { return .ignored }
            if typing?.component != component { typing = ClockDigitTyping(component: component) }
            let result = typing!.type(digit)
            if component == .hour { time.hour = result.value } else { time.minute = result.value }
            if result.isComplete {
                typing = nil
                if component == .hour { focused = .minute } else { onSubmit() }
            }
        }
        return .handled
    }
}

/// Reports scroll-wheel and trackpad scrolling over its area as whole steps (up is +1).
private struct ScrollWheelReader: NSViewRepresentable {
    let onStep: (Int) -> Void

    func makeNSView(context: Context) -> ScrollWheelView {
        let view = ScrollWheelView()
        view.onStep = onStep
        return view
    }

    func updateNSView(_ view: ScrollWheelView, context: Context) {
        view.onStep = onStep
    }

    static func dismantleNSView(_ view: ScrollWheelView, coordinator: ()) {
        view.stopMonitoring()
    }
}

private final class ScrollWheelView: NSView {
    var onStep: (Int) -> Void = { _ in }
    private var monitor: Any?
    private var accumulated: CGFloat = 0

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, event.window === self.window,
                bounds.contains(convert(event.locationInWindow, from: nil))
            else { return event }
            handle(event)
            return nil
        }
    }

    func stopMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func handle(_ event: NSEvent) {
        if event.phase == .began { accumulated = 0 }
        let delta = event.scrollingDeltaY * (event.isDirectionInvertedFromDevice ? -1 : 1)
        let threshold: CGFloat = event.hasPreciseScrollingDeltas ? 12 : 1
        accumulated += delta
        while abs(accumulated) >= threshold {
            let step = accumulated > 0 ? 1 : -1
            accumulated -= CGFloat(step) * threshold
            onStep(step)
        }
    }
}
