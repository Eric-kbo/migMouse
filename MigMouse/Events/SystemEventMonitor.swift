import CoreGraphics
import Foundation

final class SystemEventMonitor {
    private(set) var lastScrollTimestamp: TimeInterval?
    private(set) var lastPhysicalClickTimestamp: TimeInterval?

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
            .otherMouseDown
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
