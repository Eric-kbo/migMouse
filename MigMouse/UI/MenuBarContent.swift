import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var runtime: AppRuntime

    var body: some View {
        Label(statusTitle, systemImage: statusSymbol)

        Divider()

        Toggle(L10n.text("tap_to_click_title"), isOn: $runtime.enabled)

        Divider()

        SettingsLink {
            Text(L10n.text("settings"))
        }

        Menu(runtime.permissionState.isReady ? L10n.text("more_actions") : L10n.text("complete_setup")) {
            Button(L10n.text("grant_permissions")) {
                runtime.requestPermissions()
            }
            Button(L10n.text("reconnect_magic_mouse")) {
                runtime.restartDeviceDiscovery()
            }
        }

        Divider()

        Button(L10n.text("quit_migmouse")) {
            runtime.quit()
        }
        .keyboardShortcut("q")
    }

    private var statusTitle: String {
        if !runtime.permissionState.isReady {
            return L10n.text("setup_required")
        }
        if runtime.activeDeviceCount > 0 {
            return L10n.text("ready")
        }
        return runtime.deviceStatus
    }

    private var statusSymbol: String {
        runtime.permissionState.isReady && runtime.activeDeviceCount > 0
            ? "checkmark.circle.fill"
            : "exclamationmark.triangle.fill"
    }
}
