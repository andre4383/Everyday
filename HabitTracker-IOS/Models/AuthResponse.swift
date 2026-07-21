import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let user: User
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String?
}

struct CreateHabitRequest: Codable {
    let name: String
    let description: String?
    let color: String?
    let icon: String?
}
