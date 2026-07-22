import SwiftUI

struct HabitDetailView: View {
    @Environment(HabitsService.self) private var service
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    let onChanged: () -> Void

    @State private var stats: HabitStats?
    @State private var logs: [HabitLog] = []
    @State private var isLoading = false
    @State private var isMarking = false
    @State private var errorMessage: String?
    @State private var showDeleteAlert = false
    @State private var pulse = false
    @State private var showingEdit = false

    private var accent: Color { Color(hex: habit.color) ?? Theme.accent }

    private var isMarkedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return logs.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    topBar
                    prose
                    startedRow
                    totalCard
                    scheduleCard

                    markButton
                        .padding(.top, 8)

                    deleteButton

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.small())
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .task { await load() }
        .alert("Delete habit?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { Task { await deleteHabit() } }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingEdit) {
            EditHabitView(habit: habit, onSaved: {
                onChanged()
                Task { await load() }
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Circle().fill(accent).frame(width: 10, height: 10)
                Text(habit.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.surface)
            .clipShape(Capsule())

            Spacer()

            Button {
                showingEdit = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Sections

    private var prose: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(habit.name)
                .font(.system(size: 34, weight: .medium, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)

            if let desc = habit.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private var startedRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            Text("Started \(shortDate(habit.createdAt))")
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Total check-ins")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Since \(shortDate(habit.createdAt))")
                    .font(.small())
                    .foregroundStyle(Theme.textSecondary)
                Text("\(stats?.total ?? 0)")
                    .font(.system(size: 52, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5), value: stats?.total)
                    .padding(.top, 4)
            }

            ContributionGrid(logs: logs, accent: accent)

            HStack(spacing: 12) {
                miniStat(title: "Current", value: stats?.currentStreak ?? 0)
                miniStat(title: "Longest", value: stats?.longestStreak ?? 0)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func miniStat(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5), value: value)
                Text(value == 1 ? "day" : "days")
                    .font(.small())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var scheduleCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current schedule")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Every day")
                    .font(.small())
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var markButton: some View {
        Button {
            Task { await toggleToday() }
        } label: {
            HStack {
                Text(isMarkedToday ? "Done for today" : "Mark as done")
                    .font(.body_())
                Spacer()
                if isMarking {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: isMarkedToday ? "checkmark" : "arrow.right")
                        .font(.system(size: 14))
                        .scaleEffect(pulse ? 1.2 : 1.0)
                }
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(isMarkedToday ? accent : Theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .animation(.easeInOut(duration: 0.25), value: isMarkedToday)
        }
        .disabled(isMarking)
    }

    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Text("Delete habit")
                .font(.small())
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let statsCall = service.stats(habitId: habit.id)
            async let logsCall = service.logs(habitId: habit.id)
            let s = try await statsCall
            let l = try await logsCall
            withAnimation(.spring(response: 0.5)) {
                self.stats = s
                self.logs = l
            }
            self.errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleToday() async {
        isMarking = true
        defer { isMarking = false }
        withAnimation(.spring(response: 0.3)) { pulse = true }
        do {
            if isMarkedToday {
                try await service.unmark(habitId: habit.id)
            } else {
                _ = try await service.markDone(habitId: habit.id)
            }
            await load()
            onChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
        withAnimation(.spring(response: 0.3)) { pulse = false }
    }

    private func deleteHabit() async {
        do {
            try await service.delete(id: habit.id)
            onChanged()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(
            habit: Habit(
                id: "1",
                userId: "u",
                name: "Read 20 pages",
                description: "I can become a mindful person",
                color: "#F97316",
                icon: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            onChanged: {}
        )
    }
    .environment(HabitsService.shared)
}
