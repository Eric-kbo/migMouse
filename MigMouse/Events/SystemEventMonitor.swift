import CoreGraphics
import Foundation

final class SystemEventMonitor {
    private(set) var lastScrollTimestamp: TimeInterval?
    private(set) var lastPhysicalClickTimestamp: TimeInterval?
    private(set) var lastPointerMovementTimestamp: TimeInterval?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var suppressScrollEvents = false

    var snapshot: InputActivitySnapshot {
        InputActivitySnapshot(
            lastScrollTimestamp: lastScrollTimestamp,
            lastPhysicalClickTimestamp: lastPhysicalClickTimestamp
        )
    }

    func start() -> Bool {
        if eventTap != nil { return true }

        let types: [CGEventType] = [
            .scrollWheel,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged
        ]
        let mask = types.reduce(CGEventMask(0)) { partial, type in
            partial | (CGEventMask(1) << type.rawValue)
        }

        let pointer = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<SystemEventMonitor>.fromOpaque(context).takeUnretainedValue()
                if monitor.handle(type: type, event: event) {
                    return nil
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: pointer
        ) else {
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Bool {
        guard !SyntheticEventIdentity.owns(event) else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        switch type {
        case .scrollWheel:
            lastScrollTimestamp = now
            return suppressScrollEvents
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            lastPhysicalClickTimestamp = now
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            lastPointerMovementTimestamp = now
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
        default:
            break
        }
        return false
    }
}

struct TouchConnectionHealthPolicy {
    // This must be longer than AppRuntime's two-second health-check interval,
    // otherwise pointer activity immediately after one tick could be missed.
    var recentPointerWindow: TimeInterval = 3
    var staleTouchWindow: TimeInterval = 2.5
    var reconnectCooldown: TimeInterval = 8

    func shouldReconnect(
        now: TimeInterval,
        lastPointerMovement: TimeInterval?,
        lastTouchFrame: TimeInterval?,
        lastReconnect: TimeInterval?,
        isEnabled: Bool,
        isBridgeRunning: Bool
    ) -> Bool {
        guard isEnabled,
              isBridgeRunning,
              let lastPointerMovement,
              now - lastPointerMovement <= recentPointerWindow else {
            return false
        }

        if let lastTouchFrame, now - lastTouchFrame < staleTouchWindow {
            return false
        }
        if let lastReconnect, now - lastReconnect < reconnectCooldown {
            return false
        }
        return true
    }
}
