import SwiftUI

struct EditHabitView: View {
    @Environment(HabitsService.self) private var service
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    let onSaved: () -> Void

    @State private var name: String
    @State private var description: String
    @State private var color: Color
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(habit: Habit, onSaved: @escaping () -> Void) {
        self.habit = habit
        self.onSaved = onSaved
        _name = State(initialValue: habit.name)
        _description = State(initialValue: habit.description ?? "")
        _color = State(initialValue: Color(hex: habit.color) ?? Theme.accent)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit habit.")
                            .font(.display())
                            .foregroundStyle(Theme.textPrimary)
                        Text("Update the details below.")
                            .font(.body_())
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 32) {
                        inputField(label: "Name", text: $name)
                        inputField(label: "Description", text: $description)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Accent color")
                                .font(.small())
                                .foregroundStyle(Theme.textSecondary)
                            HStack {
                                Circle().fill(color).frame(width: 16, height: 16)
                                ColorPicker("", selection: $color).labelsHidden()
                                Spacer()
                            }
                            .padding(.bottom, 10)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(Theme.divider).frame(height: 1)
                            }
                        }
                    }
                    .padding(.top, 40)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.small())
                            .foregroundStyle(.red)
                            .padding(.top, 20)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Text("Save changes")
                                .font(.body_())
                            Spacer()
                            if isSaving { ProgressView().tint(.white) }
                            else { Image(systemName: "checkmark").font(.system(size: 14)) }
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 40)
                    .disabled(name.isEmpty || isSaving)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .topTrailing) {
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
            .padding()
        }
    }

    private func inputField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
            TextField("", text: text)
                .font(.body_())
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Theme.divider).frame(height: 1)
                }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let request = CreateHabitRequest(
                name: name,
                description: description.isEmpty ? nil : description,
                color: color.toHex(),
                icon: nil
            )
            _ = try await service.update(id: habit.id, body: request)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EditHabitView(
        habit: Habit(
            id: "1", userId: "u",
            name: "Read", description: "20 pages",
            color: "#F97316", icon: nil,
            createdAt: Date(), updatedAt: Date()
        ),
        onSaved: {}
    )
    .environment(HabitsService.shared)
}
