import XCTest
@testable import MigMouse

final class TapRecognizerTests: XCTestCase {
    func testOneFingerTapRecognizesLeftClick() {
        var recognizer = TapRecognizer(configuration: testingConfiguration())
        XCTAssertNil(recognizer.process(frame: frame(1.0, [contact(1, 0.3, 0.5)]), activity: .empty))

        let result = recognizer.process(frame: frame(1.12, []), activity: .empty)

        XCTAssertEqual(result?.button, .left)
        XCTAssertEqual(result?.fingerCount, 1)
    }

    func testTwoFingerTapRecognizesRightClick() {
        var recognizer = TapRecognizer(configuration: testingConfiguration())
        XCTAssertNil(recognizer.process(
            frame: frame(2.0, [contact(1, 0.3, 0.5), contact(2, 0.7, 0.5)]),
            activity: .empty
        ))

        let result = recognizer.process(frame: frame(2.14, []), activity: .empty)

        XCTAssertEqual(result?.button, .right)
        XCTAssertEqual(result?.fingerCount, 2)
    }

    func testMovementCancelsTap() {
        var recognizer = TapRecognizer(configuration: testingConfiguration())
        _ = recognizer.process(frame: frame(3.0, [contact(1, 0.2, 0.5)]), activity: .empty)
        _ = recognizer.process(frame: frame(3.05, [contact(1, 0.5, 0.5)]), activity: .empty)

        XCTAssertNil(recognizer.process(frame: frame(3.1, []), activity: .empty))
        XCTAssertEqual(recognizer.lastRejectionReason, .moved)
    }

    func testRecentScrollCancelsTap() {
        var recognizer = TapRecognizer(configuration: testingConfiguration())
        _ = recognizer.process(frame: frame(4.0, [contact(1, 0.3, 0.5)]), activity: .empty)
        let activity = InputActivitySnapshot(lastScrollTimestamp: 4.08, lastPhysicalClickTimestamp: nil)

        XCTAssertNil(recognizer.process(frame: frame(4.12, []), activity: activity))
        XCTAssertEqual(recognizer.lastRejectionReason, .recentScroll)
    }

    func testPhysicalClickCancelsTap() {
        var recognizer = TapRecognizer(configuration: testingConfiguration())
        _ = recognizer.process(frame: frame(5.0, [contact(1, 0.3, 0.5)]), activity: .empty)
        let activity = InputActivitySnapshot(lastScrollTimestamp: nil, lastPhysicalClickTimestamp: 5.05)

        XCTAssertNil(recognizer.process(frame: frame(5.12, []), activity: activity))
        XCTAssertEqual(recognizer.lastRejectionReason, .physicalClick)
    }

    func testRightZoneMode() {
        var configuration = testingConfiguration()
        configuration.secondaryTapMode = .rightZone
        var recognizer = TapRecognizer(configuration: configuration)
        _ = recognizer.process(frame: frame(6.0, [contact(1, 0.8, 0.5)]), activity: .empty)

        XCTAssertEqual(
            recognizer.process(frame: frame(6.1, []), activity: .empty)?.button,
            .right
        )
    }

    func testPinchProducesNativeGestureSequence() {
        var configuration = testingConfiguration()
        configuration.pinchActivationScale = 0.03
        configuration.pinchSensitivity = 1
        var recognizer = PinchGestureRecognizer(configuration: configuration)

        XCTAssertTrue(recognizer.process(frame: frame(9.0, [
            contact(1, 0.4, 0.5), contact(2, 0.6, 0.5)
        ])).events.isEmpty)

        let changed = recognizer.process(frame: frame(9.1, [
            contact(1, 0.38, 0.5), contact(2, 0.62, 0.5)
        ]))
        XCTAssertEqual(changed.events.first, .magnifyBegan(timestamp: 9.1))
        guard case let .magnifyChanged(delta, timestamp) = changed.events.last else {
            return XCTFail("Expected magnification change")
        }
        XCTAssertGreaterThan(delta, 0)
        XCTAssertEqual(timestamp, 9.1)
        XCTAssertTrue(changed.suppressesNativeScroll)
        XCTAssertEqual(
            recognizer.process(frame: frame(9.2, [])).events,
            [.magnifyEnded(timestamp: 9.2)]
        )
    }

    func testSmallTwoFingerMotionRemainsEligibleForSecondaryTap() {
        var recognizer = PinchGestureRecognizer(configuration: testingConfiguration())
        _ = recognizer.process(frame: frame(10.0, [
            contact(1, 0.4, 0.5), contact(2, 0.6, 0.5)
        ]))
        let movement = recognizer.process(frame: frame(10.1, [
            contact(1, 0.398, 0.5), contact(2, 0.602, 0.5)
        ]))

        XCTAssertTrue(movement.events.isEmpty)
        XCTAssertFalse(movement.cancelsTapCandidate)
        XCTAssertFalse(movement.suppressesNativeScroll)
    }

    func testHealthPolicyReconnectsForRecentPointerMotionWithoutTouchFrames() {
        let policy = TouchConnectionHealthPolicy()

        XCTAssertTrue(policy.shouldReconnect(
            now: 20,
            lastPointerMovement: 19.5,
            lastTouchFrame: 15,
            lastReconnect: 10,
            isEnabled: true,
            isBridgeRunning: true
        ))
    }

    func testHealthPolicyDoesNotReconnectWhenTouchFramesAreCurrent() {
        let policy = TouchConnectionHealthPolicy()

        XCTAssertFalse(policy.shouldReconnect(
            now: 20,
            lastPointerMovement: 19.5,
            lastTouchFrame: 19,
            lastReconnect: nil,
            isEnabled: true,
            isBridgeRunning: true
        ))
    }

    func testHealthPolicyThrottlesAutomaticReconnects() {
        let policy = TouchConnectionHealthPolicy()

        XCTAssertFalse(policy.shouldReconnect(
            now: 20,
            lastPointerMovement: 19.5,
            lastTouchFrame: nil,
            lastReconnect: 15,
            isEnabled: true,
            isBridgeRunning: true
        ))
    }

    private func testingConfiguration() -> GestureConfiguration {
        var configuration = GestureConfiguration.default
        configuration.minimumPeakContact = 0
        return configuration
    }

    private func frame(_ timestamp: TimeInterval, _ contacts: [TouchContact]) -> TouchFrame {
        TouchFrame(timestamp: timestamp, contacts: contacts)
    }

    private func contact(_ id: Int32, _ x: Double, _ y: Double) -> TouchContact {
        TouchContact(
            id: id,
            stage: 4,
            position: CGPoint(x: x, y: y),
            velocity: .zero,
            totalPressure: 1,
            pressure: 1,
            majorAxis: 8,
            minorAxis: 6
        )
    }
}

private extension InputActivitySnapshot {
    static let empty = InputActivitySnapshot(
        lastScrollTimestamp: nil,
        lastPhysicalClickTimestamp: nil
    )
}
