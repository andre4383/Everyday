import SwiftUI

struct CreateHabitView: View {
    @Environment(HabitsService.self) private var service
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var color: Color = HabitPalette.swatches[0]
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case name, description }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    previewCard
                    nameField
                    descriptionField
                    colorSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.small())
                            .foregroundStyle(.red)
                    }

                    saveButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
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

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New habit")
                .font(.display())
                .foregroundStyle(Theme.textPrimary)
            Text("Give it a name and a color you'll recognise.")
                .font(.body_())
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Your habit" : name)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(name.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                if !description.isEmpty {
                    Text(description)
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
        .padding(18)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.4), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(.spring(response: 0.4), value: color)
        .animation(.spring(response: 0.3), value: name)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
            TextField("e.g. Morning run", text: $name)
                .focused($focusedField, equals: .name)
                .font(.body_())
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(focusedField == .name ? Theme.textPrimary : Theme.divider)
                        .frame(height: focusedField == .name ? 1.5 : 1)
                }
                .animation(.easeOut(duration: 0.2), value: focusedField)
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.small())
                .foregroundStyle(Theme.textSecondary)
            TextField("Optional context or goal", text: $description)
                .focused($focusedField, equals: .description)
                .font(.body_())
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(focusedField == .description ? Theme.textPrimary : Theme.divider)
                        .frame(height: focusedField == .description ? 1.5 : 1)
                }
                .animation(.easeOut(duration: 0.2), value: focusedField)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Color")
                    .font(.small())
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                ColorPicker("", selection: $color)
                    .labelsHidden()
                    .scaleEffect(0.85)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(HabitPalette.swatches, id: \.self) { swatch in
                    Button {
                        color = swatch
                    } label: {
                        ZStack {
                            Circle()
                                .fill(swatch)
                                .frame(width: 36, height: 36)
                            if swatch.toHex() == color.toHex() {
                                Circle()
                                    .stroke(Theme.textPrimary, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .frame(width: 44, height: 44)
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack {
                Text("Create habit")
                    .font(.body_())
                Spacer()
                if isSaving { ProgressView().tint(.white) }
                else { Image(systemName: "arrow.right").font(.system(size: 14)) }
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(name.isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(name.isEmpty || isSaving)
        .padding(.top, 12)
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
            _ = try await service.create(request)
            onCreated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum HabitPalette {
    static let swatches: [Color] = [
        Color(hex: "#0A0A0A")!,   // black
        Color(hex: "#C86B3C")!,   // terracotta
        Color(hex: "#D9A441")!,   // mustard
        Color(hex: "#7BA05B")!,   // sage
        Color(hex: "#4A6FA5")!,   // dusty blue
        Color(hex: "#8B5A8C")!,   // plum
        Color(hex: "#B04A5A")!,   // rose
        Color(hex: "#3F7D6E")!,   // teal
        Color(hex: "#A8895C")!,   // camel
        Color(hex: "#5A6B7D")!,   // slate
        Color(hex: "#C77B6D")!,   // salmon
        Color(hex: "#6B7A3F")!,   // olive
    ]
}

extension Color {
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

#Preview {
    CreateHabitView(onCreated: {})
        .environment(HabitsService.shared)
}
