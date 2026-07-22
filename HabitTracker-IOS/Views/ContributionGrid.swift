import SwiftUI

struct ContributionGrid: View {
    let logs: [HabitLog]
    let accent: Color
    var weeks: Int = 14

    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 4

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeks * 7
        return (0..<totalDays).compactMap {
            calendar.date(byAdding: .day, value: -($0), to: today)
        }.reversed()
    }

    private var logDates: Set<String> {
        Set(logs.map { dayKey(from: $0.date) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(0..<weeks, id: \.self) { week in
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { weekday in
                            let index = week * 7 + weekday
                            if index < days.count {
                                cell(for: days[index])
                            }
                        }
                    }
                }
            }

            HStack {
                Text(monthLabel(days.first))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(monthLabel(days.last))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func cell(for date: Date) -> some View {
        let key = dayKey(from: date)
        let isDone = logDates.contains(key)
        let isToday = Calendar.current.isDateInToday(date)

        RoundedRectangle(cornerRadius: 3)
            .fill(isDone ? accent : Theme.divider)
            .frame(width: cellSize, height: cellSize)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.textPrimary, lineWidth: 1)
                }
            }
    }

    private func dayKey(from date: Date) -> String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return "\(calendar.component(.year, from: start))-\(calendar.component(.month, from: start))-\(calendar.component(.day, from: start))"
    }

    private func monthLabel(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}
