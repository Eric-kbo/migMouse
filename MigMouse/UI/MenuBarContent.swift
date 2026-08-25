import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var runtime: AppRuntime

    var body: some View {
        Toggle(L10n.text("tap_to_click_title"), isOn: $runtime.enabled)

        Divider()

        Text(runtime.deviceStatus)
        if !runtime.permissionState.isReady {
            Button(L10n.text("grant_permissions")) {
                runtime.requestPermissions()
            }
        }

        SettingsLink {
            Text(L10n.text("settings"))
        }

        Button(L10n.text("reconnect_magic_mouse")) {
            runtime.restartDeviceDiscovery()
        }

        Divider()

        Button(L10n.text("quit_migmouse")) {
            runtime.quit()
        }
        .keyboardShortcut("q")
    }
}
