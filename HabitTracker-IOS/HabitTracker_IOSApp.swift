import SwiftUI

@main
struct HabitTracker_IOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AuthService.shared)
                .environment(HabitsService.shared)
        }
    }
}
