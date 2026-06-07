import SwiftUI

@main
struct MarkwayMacApp: App {
    @StateObject private var updater = MarkwayUpdater()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                if updater.canCheckForUpdates {
                    Button("Check for Updates...") {
                        updater.checkForUpdates()
                    }
                }
            }
        }
    }
}
