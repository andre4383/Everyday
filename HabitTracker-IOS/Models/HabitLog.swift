import Foundation

struct HabitLog: Codable, Identifiable, Hashable {
    let id: String
    let habitId: String
    let date: Date
    let createdAt: Date
}

struct HabitStats: Codable, Hashable {
    let total: Int
    let currentStreak: Int
    let longestStreak: Int
}
