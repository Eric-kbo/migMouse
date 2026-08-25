import ApplicationServices
import CoreGraphics
import Foundation

struct PermissionState: Equatable {
    let canListen: Bool
    let canPost: Bool

    var isReady: Bool { canListen && canPost }
}

enum PermissionManager {
    static func currentState() -> PermissionState {
        // Accessibility trust is the canonical authorization used by existing
        // macOS assistive apps. CGPreflightPostEventAccess can lag behind TCC's
        // Accessibility state on development-signed, directly installed apps.
        let accessibilityTrusted = AXIsProcessTrusted()
        return PermissionState(
            canListen: CGPreflightListenEventAccess() || accessibilityTrusted,
            canPost: CGPreflightPostEventAccess() || accessibilityTrusted
        )
    }

    static func request() {
        _ = CGRequestListenEventAccess()
        _ = CGRequestPostEventAccess()
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
