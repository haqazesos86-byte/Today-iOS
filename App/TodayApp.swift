import SwiftUI
import SwiftData

@main
struct TodayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(try! PersistenceService.shared.container)
    }
}
