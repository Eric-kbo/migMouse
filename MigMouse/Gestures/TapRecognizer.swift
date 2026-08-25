import Foundation

struct InputActivitySnapshot: Sendable {
    var lastScrollTimestamp: TimeInterval?
    var lastPhysicalClickTimestamp: TimeInterval?
}

struct TapRecognizer {
    private struct Candidate {
        let startedAt: TimeInterval
        var firstPositions: [Int32: CGPoint]
        var previousPositions: [Int32: CGPoint]
        var finalPositions: [Int32: CGPoint]
        var maximumFingerCount: Int
        var maximumDisplacement: Double
        var totalPathLength: Double
        var peakContact: Double
        var rejectionReason: TapRejectionReason?
    }

    var configuration: GestureConfiguration
    private var candidate: Candidate?
    private(set) var lastRejectionReason: TapRejectionReason?

    init(configuration: GestureConfiguration = .default) {
        self.configuration = configuration
    }

    mutating func reset() {
        candidate = nil
        lastRejectionReason = nil
    }

    mutating func cancelCurrentGesture() {
        candidate = nil
        lastRejectionReason = .moved
    }

    mutating func process(
        frame: TouchFrame,
        activity: InputActivitySnapshot
    ) -> RecognizedTap? {
        let active = frame.activeContacts

        if candidate == nil, !active.isEmpty {
            let positions = Dictionary(uniqueKeysWithValues: active.map { ($0.id, $0.position) })
            candidate = Candidate(
                startedAt: frame.timestamp,
                firstPositions: positions,
                previousPositions: positions,
                finalPositions: positions,
                maximumFingerCount: active.count,
                maximumDisplacement: 0,
                totalPathLength: 0,
                peakContact: active.map(\.totalPressure).max() ?? 0,
                rejectionReason: active.count > 2 ? .tooManyFingers : nil
            )
            return nil
        }

        guard var current = candidate else {
            return nil
        }

        if !active.isEmpty {
            current.maximumFingerCount = max(current.maximumFingerCount, active.count)
            if active.count > 2 {
                current.rejectionReason = .tooManyFingers
            }

            for contact in active {
                let position = contact.position
                if current.firstPositions[contact.id] == nil {
                    current.firstPositions[contact.id] = position
                }
                if let previous = current.previousPositions[contact.id] {
                    current.totalPathLength += previous.distance(to: position)
                }
                if let first = current.firstPositions[contact.id] {
                    current.maximumDisplacement = max(
                        current.maximumDisplacement,
                        first.distance(to: position)
                    )
                }
                current.previousPositions[contact.id] = position
                current.finalPositions[contact.id] = position
                current.peakContact = max(current.peakContact, contact.totalPressure)
            }

            if current.maximumDisplacement > configuration.maximumDisplacement ||
                current.totalPathLength > configuration.maximumPathLength {
                current.rejectionReason = .moved
            }
            candidate = current
            return nil
        }

        candidate = nil
        let duration = frame.timestamp - current.startedAt
        if let reason = current.rejectionReason {
            lastRejectionReason = reason
            return nil
        }
        guard duration >= 0, duration <= configuration.maximumTapDuration else {
            lastRejectionReason = .tooLong
            return nil
        }
        guard current.peakContact >= configuration.minimumPeakContact else {
            lastRejectionReason = .contactTooLight
            return nil
        }
        if let reason = suppressionReason(timestamp: frame.timestamp, activity: activity) {
            lastRejectionReason = reason
            return nil
        }

        let positions = Array(current.finalPositions.values)
        guard !positions.isEmpty else { return nil }
        let average = CGPoint(
            x: positions.map(\.x).reduce(0, +) / Double(positions.count),
            y: positions.map(\.y).reduce(0, +) / Double(positions.count)
        )
        guard average.x >= configuration.edgeInset,
              average.x <= 1 - configuration.edgeInset else {
            lastRejectionReason = .edge
            return nil
        }

        let button: MouseButton
        switch current.maximumFingerCount {
        case 1:
            guard configuration.tapToClickEnabled else {
                lastRejectionReason = .gestureDisabled
                return nil
            }
            if configuration.secondaryTapEnabled,
               configuration.secondaryTapMode == .rightZone,
               average.x >= configuration.rightZoneStart {
                button = .right
            } else {
                button = .left
            }
        case 2:
            guard configuration.secondaryTapEnabled,
                  configuration.secondaryTapMode == .twoFingers else {
                lastRejectionReason = .gestureDisabled
                return nil
            }
            button = .right
        default:
            return nil
        }

        lastRejectionReason = nil
        return RecognizedTap(
            button: button,
            timestamp: frame.timestamp,
            position: average,
            fingerCount: current.maximumFingerCount
        )
    }

    private func suppressionReason(
        timestamp: TimeInterval,
        activity: InputActivitySnapshot
    ) -> TapRejectionReason? {
        if let scroll = activity.lastScrollTimestamp,
           timestamp - scroll <= configuration.scrollSuppressionWindow {
            return .recentScroll
        }
        if let click = activity.lastPhysicalClickTimestamp,
           timestamp - click <= configuration.physicalClickSuppressionWindow {
            return .physicalClick
        }
        return nil
    }
}

struct PinchGestureRecognizer {
    private struct PinchCandidate {
        let initialDistance: Double
        var previousDistance: Double
    }

    var configuration: GestureConfiguration
    private var pinchCandidate: PinchCandidate?
    private var isMagnifying = false

    init(configuration: GestureConfiguration = .default) {
        self.configuration = configuration
    }

    mutating func reset(timestamp: TimeInterval) -> [PinchGestureEvent] {
        var events: [PinchGestureEvent] = []
        if isMagnifying {
            events.append(.magnifyEnded(timestamp: timestamp))
        }
        pinchCandidate = nil
        isMagnifying = false
        return events
    }

    mutating func process(frame: TouchFrame) -> PinchGestureOutput {
        let active = frame.activeContacts

        if isMagnifying {
            guard active.count == 2 else {
                isMagnifying = false
                pinchCandidate = nil
                return PinchGestureOutput(
                    events: [.magnifyEnded(timestamp: frame.timestamp)],
                    cancelsTapCandidate: true
                )
            }
            let distance = active[0].position.distance(to: active[1].position)
            guard var pinch = pinchCandidate, pinch.previousDistance > 0 else {
                pinchCandidate = PinchCandidate(initialDistance: distance, previousDistance: distance)
                return PinchGestureOutput(cancelsTapCandidate: true, suppressesNativeScroll: true)
            }
            let delta = magnificationDelta(from: pinch.previousDistance, to: distance)
            pinch.previousDistance = distance
            pinchCandidate = pinch
            return PinchGestureOutput(
                events: abs(delta) > 0.0001 ? [.magnifyChanged(delta: delta, timestamp: frame.timestamp)] : [],
                cancelsTapCandidate: true,
                suppressesNativeScroll: true
            )
        }

        guard !active.isEmpty else {
            pinchCandidate = nil
            return PinchGestureOutput()
        }

        if active.count == 2 {
            guard configuration.pinchToZoomEnabled else {
                pinchCandidate = nil
                return PinchGestureOutput()
            }
            let distance = active[0].position.distance(to: active[1].position)
            guard distance > 0.001 else { return PinchGestureOutput() }
            if var pinch = pinchCandidate {
                let totalScale = abs(log(distance / pinch.initialDistance))
                let delta = magnificationDelta(from: pinch.previousDistance, to: distance)
                pinch.previousDistance = distance
                pinchCandidate = pinch
                if totalScale >= configuration.pinchActivationScale {
                    isMagnifying = true
                    return PinchGestureOutput(
                        events: [
                            .magnifyBegan(timestamp: frame.timestamp),
                            .magnifyChanged(delta: delta, timestamp: frame.timestamp)
                        ],
                        cancelsTapCandidate: true,
                        suppressesNativeScroll: true
                    )
                }
            } else {
                pinchCandidate = PinchCandidate(initialDistance: distance, previousDistance: distance)
            }
            return PinchGestureOutput()
        }

        pinchCandidate = nil
        return PinchGestureOutput()
    }

    private func magnificationDelta(from previous: Double, to current: Double) -> Double {
        guard previous > 0, current > 0 else { return 0 }
        return max(-0.12, min(0.12, log(current / previous) * configuration.pinchSensitivity))
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> Double {
        hypot(x - other.x, y - other.y)
    }
}
