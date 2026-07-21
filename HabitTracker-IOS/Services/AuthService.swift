import Foundation

@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool

    private let api = APIClient.shared

    private init() {
        self.isAuthenticated = KeychainHelper.read() != nil
    }

    func login(email: String, password: String) async throws {
        let body = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await api.post("/auth/login", body: body)
        KeychainHelper.save(response.accessToken)
        self.currentUser = response.user
        self.isAuthenticated = true
    }

    func register(email: String, password: String, name: String?) async throws {
        let body = RegisterRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await api.post("/auth/register", body: body)
        KeychainHelper.save(response.accessToken)
        self.currentUser = response.user
        self.isAuthenticated = true
    }

    func logout() {
        KeychainHelper.delete()
        self.currentUser = nil
        self.isAuthenticated = false
    }

    func loadCurrentUser() async {
        guard isAuthenticated else { return }
        do {
            let user: User = try await api.get("/auth/me")
            self.currentUser = user
        } catch {
            // token invalid or expired
            logout()
        }
    }
}
