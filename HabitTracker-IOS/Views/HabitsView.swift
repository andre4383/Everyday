import SwiftUI

struct HabitsView: View {
    @Environment(HabitsService.self) private var service
    @Environment(AuthService.self) private var auth

    @State private var habits: [Habit] = []
    @State private var todayCount = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreate = false
    @State private var selectedHabit: Habit?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        header
                        todayCard

                        if isLoading {
                            ProgressView().padding(.top, 40)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .font(.small())
                                .foregroundStyle(.red)
                        } else if habits.isEmpty {
                            emptyState
                        } else {
                            habitsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 140)
                }

                createButton.padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        auth.logout()
                    } label: {
                        Image(systemName: "arrow.right.square")
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit, onChanged: {
                    Task { await loadAll() }
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showingCreate) {
                CreateHabitView(onCreated: {
                    Task { await loadAll() }
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .task {
                await auth.loadCurrentUser()
                await loadAll()
            }
        }
        .tint(Theme.textPrimary)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(todayString)
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)
            Text(greeting)
                .font(.display())
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(todayLine)
                        .font(.small())
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(todayCount)/\(habits.count)")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5), value: todayCount)
            }

            progressBar
        }
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.divider)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.textPrimary)
                    .frame(width: progressWidth(total: geo.size.width))
                    .animation(.spring(response: 0.6), value: todayCount)
            }
        }
        .frame(height: 6)
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All habits")
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.leading, 4)

            VStack(spacing: 10) {
                ForEach(habits) { habit in
                    Button {
                        selectedHabit = habit
                    } label: {
                        HabitCard(habit: habit)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No habits yet.")
                .font(.title())
                .foregroundStyle(Theme.textPrimary)
            Text("Tap the plus button to add your first one.")
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 20)
    }

    private var createButton: some View {
        Button {
            showingCreate = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.textPrimary)
                .clipShape(Circle())
        }
    }

    // MARK: - Helpers

    private var greeting: String {
        if let name = auth.currentUser?.name, !name.isEmpty {
            return "Hello, \(name)."
        }
        return "Hello."
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: Date())
    }

    private var todayLine: String {
        if habits.isEmpty { return "Nothing to track yet." }
        if todayCount == habits.count { return "All done for today." }
        let remaining = habits.count - todayCount
        return remaining == 1 ? "1 habit left." : "\(remaining) habits left."
    }

    private func progressWidth(total: CGFloat) -> CGFloat {
        guard !habits.isEmpty else { return 0 }
        return total * (CGFloat(todayCount) / CGFloat(habits.count))
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let list = try await service.list()
            withAnimation(.spring(response: 0.4)) {
                habits = list
                errorMessage = nil
            }
            await loadTodayCount(for: list)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadTodayCount(for list: [Habit]) async {
        var count = 0
        await withTaskGroup(of: Bool.self) { group in
            for habit in list {
                group.addTask {
                    guard let logs = try? await service.logs(habitId: habit.id) else { return false }
                    return logs.contains { Calendar.current.isDateInToday($0.date) }
                }
            }
            for await done in group where done { count += 1 }
        }
        withAnimation(.spring(response: 0.5)) {
            todayCount = count
        }
    }
}

struct HabitCard: View {
    let habit: Habit

    private var accent: Color {
        Color(hex: habit.color) ?? Theme.accent
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(accent)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                if let desc = habit.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HabitsView()
        .environment(HabitsService.shared)
        .environment(AuthService.shared)
}
