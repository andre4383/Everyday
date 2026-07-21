import Foundation

struct Habit: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    let color: String
    let icon: String?
    let createdAt: Date
    let updatedAt: Date
}
