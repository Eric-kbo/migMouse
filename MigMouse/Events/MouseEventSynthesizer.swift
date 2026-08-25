import AppKit
import CoreGraphics

final class MouseEventSynthesizer {
    private var lastButton: MouseButton?
    private var lastClickTimestamp: TimeInterval = -.infinity
    private var clickCount = 0

    func click(button: MouseButton, timestamp: TimeInterval) {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let cursor = CGEvent(source: nil)?.location else {
            return
        }

        let doubleClickInterval = NSEvent.doubleClickInterval
        if lastButton == button, timestamp - lastClickTimestamp <= doubleClickInterval {
            clickCount = min(clickCount + 1, 3)
        } else {
            clickCount = 1
        }
        lastButton = button
        lastClickTimestamp = timestamp

        let types = eventTypes(for: button)
        let cgButton = cgMouseButton(for: button)
        guard let down = CGEvent(
            mouseEventSource: source,
            mouseType: types.down,
            mouseCursorPosition: cursor,
            mouseButton: cgButton
        ), let up = CGEvent(
            mouseEventSource: source,
            mouseType: types.up,
            mouseCursorPosition: cursor,
            mouseButton: cgButton
        ) else {
            return
        }

        for event in [down, up] {
            event.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
            event.setDoubleValueField(.mouseEventPressure, value: event === down ? 1 : 0)
            SyntheticEventIdentity.mark(event)
            event.post(tap: .cghidEventTap)
        }
    }

    private func eventTypes(for button: MouseButton) -> (down: CGEventType, up: CGEventType) {
        switch button {
        case .left: (.leftMouseDown, .leftMouseUp)
        case .right: (.rightMouseDown, .rightMouseUp)
        case .center: (.otherMouseDown, .otherMouseUp)
        }
    }

    private func cgMouseButton(for button: MouseButton) -> CGMouseButton {
        switch button {
        case .left: .left
        case .right: .right
        case .center: .center
        }
    }
}
