import AppKit
import SwiftUI

@main
struct SixSevenMemeApp: App {
    init() {
        // Ensure the app appears as a regular macOS app with a Dock icon,
        // even when launched from a Swift Package executable.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .defaultSize(width: 700, height: 600)
    }
}
