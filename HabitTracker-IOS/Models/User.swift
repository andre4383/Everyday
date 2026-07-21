import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let name: String?
}
