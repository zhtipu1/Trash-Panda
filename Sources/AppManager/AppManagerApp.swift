import SwiftUI

@main
struct AppManagerApp: App {
    var body: some Scene {
        Window("Trash Panda: App Manager", id: "main") {
            RootView()
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1100, height: 720)

        Settings {
            SettingsView(settings: AppSettings.shared)
                .preferredColorScheme(.dark)
        }
    }
}
