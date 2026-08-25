import SwiftUI

@main
struct MigMouseApp: App {
    @StateObject private var runtime = AppRuntime()

    var body: some Scene {
        MenuBarExtra("MigMouse", systemImage: runtime.enabled ? "computermouse.fill" : "computermouse") {
            MenuBarContent(runtime: runtime)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(runtime: runtime)
        }
        .defaultSize(width: 620, height: 600)
    }
}
