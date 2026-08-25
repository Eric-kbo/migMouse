import AppKit
import Combine
import Foundation

@MainActor
final class AppRuntime: ObservableObject {
    @Published var enabled = true {
        didSet {
            if !enabled {
                stopPinchGesture()
                recognizer.reset()
            }
        }
    }
    @Published var permissionState = PermissionManager.currentState()
    @Published var deviceStatus = L10n.text("starting")
    @Published var activeDeviceCount = 0
    @Published var currentContacts: [TouchContact] = []
    @Published var lastRecognizedTap: RecognizedTap?
    @Published var lastRejectionReason: TapRejectionReason?
    @Published var recognizedTapCount = 0
    @Published var postedClickCount = 0
    @Published var recognizedPinchCount = 0
    @Published var configuration: GestureConfiguration {
        didSet {
            recognizer.configuration = configuration
            pinchRecognizer.configuration = configuration
            saveConfiguration()
        }
    }

    private let bridge = MMMultitouchBridge()
    private let systemEvents = SystemEventMonitor()
    private let synthesizer = MouseEventSynthesizer()
    private let magnificationSynthesizer = MagnificationEventSynthesizer()
    private var recognizer: TapRecognizer
    private var pinchRecognizer: PinchGestureRecognizer
    private var permissionTimer: Timer?

    init() {
        let configuration = Self.loadConfiguration()
        self.configuration = configuration
        self.recognizer = TapRecognizer(configuration: configuration)
        self.pinchRecognizer = PinchGestureRecognizer(configuration: configuration)
        // An application-hosted XCTest bundle launches the app before running
        // logic tests. Starting MultitouchSupport in that process would take
        // control of the same physical device as a running MigMouse instance;
        // stopping the test host can then silence the live app's callbacks.
        guard !Self.isRunningTests else { return }
        start()
    }

    deinit {
        permissionTimer?.invalidate()
    }

    func start() {
        permissionState = PermissionManager.currentState()
        _ = systemEvents.start()
        startBridgeIfNeeded()

        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.permissionState = PermissionManager.currentState()
                if self.permissionState.canListen {
                    _ = self.systemEvents.start()
                }
                self.startBridgeIfNeeded()
            }
        }
    }

    func restartDeviceDiscovery() {
        stopPinchGesture()
        bridge.stop()
        recognizer.reset()
        start()
    }

    func requestPermissions() {
        PermissionManager.request()
    }

    func sendTestClick() {
        synthesizer.click(button: .left, timestamp: ProcessInfo.processInfo.systemUptime)
        postedClickCount += 1
    }

    func quit() {
        bridge.stop()
        systemEvents.stop()
        NSApplication.shared.terminate(nil)
    }

    private func handle(
        touches: UnsafePointer<MMMTouch>?,
        count: Int,
        timestamp: Double
    ) {
        var contacts: [TouchContact] = []
        if let touches, count > 0 {
            contacts.reserveCapacity(count)
            for index in 0..<count {
                let touch = touches[index]
                contacts.append(TouchContact(
                    id: touch.fingerID,
                    stage: touch.stage,
                    position: CGPoint(
                        x: Double(touch.normalizedVector.position.x),
                        y: Double(touch.normalizedVector.position.y)
                    ),
                    velocity: CGVector(
                        dx: Double(touch.normalizedVector.velocity.x),
                        dy: Double(touch.normalizedVector.velocity.y)
                    ),
                    totalPressure: Double(touch.zTotal),
                    pressure: Double(touch.zPressure),
                    majorAxis: Double(touch.majorAxis),
                    minorAxis: Double(touch.minorAxis)
                ))
            }
        }

        currentContacts = contacts.filter(\.isTouching)
        guard enabled else {
            recognizer.reset()
            return
        }

        let frame = TouchFrame(
            timestamp: ProcessInfo.processInfo.systemUptime,
            contacts: contacts
        )
        let pinchOutput = pinchRecognizer.process(frame: frame)
        systemEvents.suppressScrollEvents = pinchOutput.suppressesNativeScroll
        if pinchOutput.cancelsTapCandidate {
            recognizer.cancelCurrentGesture()
        }
        handle(events: pinchOutput.events)

        let tap = pinchOutput.cancelsTapCandidate
            ? nil
            : recognizer.process(frame: frame, activity: systemEvents.snapshot)
        if currentContacts.isEmpty {
            lastRejectionReason = recognizer.lastRejectionReason
        }
        if let tap {
            lastRecognizedTap = tap
            lastRejectionReason = nil
            recognizedTapCount += 1
            // Always submit the event. Permission preflight APIs are advisory
            // and can report stale values for a directly installed development
            // build; CoreGraphics safely rejects unauthorized posting itself.
            synthesizer.click(button: tap.button, timestamp: frame.timestamp)
            postedClickCount += 1
        }
    }

    private func handle(events: [PinchGestureEvent]) {
        for event in events {
            switch event {
            case .magnifyBegan:
                magnificationSynthesizer.begin()
                recognizedPinchCount += 1
            case let .magnifyChanged(delta, _):
                magnificationSynthesizer.change(by: delta)
            case .magnifyEnded:
                magnificationSynthesizer.end()
            }
        }
    }

    private func stopPinchGesture() {
        let timestamp = ProcessInfo.processInfo.systemUptime
        handle(events: pinchRecognizer.reset(timestamp: timestamp))
        systemEvents.suppressScrollEvents = false
    }

    private func refreshBridgeStatus() {
        deviceStatus = bridge.statusMessage
        activeDeviceCount = bridge.activeDeviceCount
    }

    private func startBridgeIfNeeded() {
        guard !bridge.isRunning else {
            refreshBridgeStatus()
            return
        }
        bridge.start { [weak self] touches, count, timestamp in
            guard let self else { return }
            self.handle(touches: touches, count: count, timestamp: timestamp)
        }
        refreshBridgeStatus()
    }

    private func saveConfiguration() {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        UserDefaults.standard.set(data, forKey: "gestureConfiguration")
    }

    private static func loadConfiguration() -> GestureConfiguration {
        guard let data = UserDefaults.standard.data(forKey: "gestureConfiguration"),
              let value = try? JSONDecoder().decode(GestureConfiguration.self, from: data) else {
            return .default
        }
        return value
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
