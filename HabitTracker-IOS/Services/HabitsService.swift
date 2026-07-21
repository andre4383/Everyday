import Foundation

@Observable
final class HabitsService {
    static let shared = HabitsService()

    private let api = APIClient.shared

    private init() {}

    func list() async throws -> [Habit] {
        try await api.get("/habits")
    }

    func get(id: String) async throws -> Habit {
        try await api.get("/habits/\(id)")
    }

    func create(_ body: CreateHabitRequest) async throws -> Habit {
        try await api.post("/habits", body: body)
    }

    func update(id: String, body: CreateHabitRequest) async throws -> Habit {
        try await api.patch("/habits/\(id)", body: body)
    }

    func delete(id: String) async throws {
        let _: EmptyResponse = try await api.delete("/habits/\(id)")
    }

    func markDone(habitId: String) async throws -> HabitLog {
        try await api.postEmpty("/habits/\(habitId)/logs")
    }

    func unmark(habitId: String) async throws {
        let _: EmptyResponse = try await api.delete("/habits/\(habitId)/logs")
    }

    func logs(habitId: String) async throws -> [HabitLog] {
        try await api.get("/habits/\(habitId)/logs")
    }

    func stats(habitId: String) async throws -> HabitStats {
        try await api.get("/habits/\(habitId)/stats")
    }
}
