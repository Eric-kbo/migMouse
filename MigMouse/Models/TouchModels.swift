import Foundation

struct TouchContact: Equatable, Sendable, Identifiable {
    let id: Int32
    let stage: Int32
    let position: CGPoint
    let velocity: CGVector
    let totalPressure: Double
    let pressure: Double
    let majorAxis: Double
    let minorAxis: Double

    var isTouching: Bool { stage == 4 }
}

struct TouchFrame: Equatable, Sendable {
    let timestamp: TimeInterval
    let contacts: [TouchContact]

    var activeContacts: [TouchContact] {
        contacts.filter(\.isTouching)
    }
}

enum MouseButton: String, Codable, CaseIterable, Sendable {
    case left
    case right
    case center

    var localizedTitle: String { L10n.text("button_\(rawValue)") }
}

enum SecondaryTapMode: String, Codable, CaseIterable, Sendable {
    case twoFingers
    case rightZone

    var title: String {
        switch self {
        case .twoFingers: L10n.text("tap_with_two_fingers")
        case .rightZone: L10n.text("tap_on_right_side")
        }
    }
}

struct RecognizedTap: Equatable, Sendable {
    let button: MouseButton
    let timestamp: TimeInterval
    let position: CGPoint
    let fingerCount: Int
}

enum PinchGestureEvent: Equatable, Sendable {
    case magnifyBegan(timestamp: TimeInterval)
    case magnifyChanged(delta: Double, timestamp: TimeInterval)
    case magnifyEnded(timestamp: TimeInterval)
}

struct PinchGestureOutput: Equatable, Sendable {
    var events: [PinchGestureEvent] = []
    var cancelsTapCandidate = false
    var suppressesNativeScroll = false
}

enum TapRejectionReason: String, Equatable, Sendable {
    case tooLong
    case moved
    case contactTooLight
    case recentScroll
    case physicalClick
    case edge
    case tooManyFingers
    case gestureDisabled

    var localizedDescription: String { L10n.text("rejection_\(rawValue)") }
}
