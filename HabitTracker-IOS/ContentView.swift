import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        if auth.isAuthenticated {
            HabitsView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService.shared)
        .environment(HabitsService.shared)
}
