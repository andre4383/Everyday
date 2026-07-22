import SwiftUI

struct RegisterView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 20)

                Text("Create your account.")
                    .font(.display())
                    .foregroundStyle(Theme.textPrimary)

                Text("Build habits that stick.")
                    .font(.body_())
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)

                VStack(spacing: 32) {
                    inputField(label: "Name", text: $name)
                    inputField(label: "Email", text: $email, keyboard: .emailAddress, noAuto: true)
                    inputField(label: "Password", text: $password, secure: true)
                }
                .padding(.top, 56)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.small())
                        .foregroundStyle(.red)
                        .padding(.top, 20)
                }

                Button {
                    Task { await handleRegister() }
                } label: {
                    HStack {
                        Text("Create account")
                            .font(.body_())
                        Spacer()
                        if isLoading { ProgressView().tint(.white) }
                        else { Image(systemName: "arrow.right").font(.system(size: 14)) }
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(Theme.textPrimary)
                }
                .padding(.top, 40)
                .disabled(email.isEmpty || password.count < 6 || isLoading)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding()
        }
    }

    private func inputField(label: String, text: Binding<String>, secure: Bool = false, keyboard: UIKeyboardType = .default, noAuto: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.small())
                .foregroundStyle(Theme.textSecondary)

            Group {
                if secure {
                    SecureField("", text: text)
                        .textContentType(.newPassword)
                } else {
                    TextField("", text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(noAuto ? .never : .words)
                        .autocorrectionDisabled(noAuto)
                }
            }
            .font(.body_())
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.divider).frame(height: 1)
            }
        }
    }

    private func handleRegister() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.register(
                email: email,
                password: password,
                name: name.isEmpty ? nil : name
            )
            errorMessage = nil
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    RegisterView()
        .environment(AuthService.shared)
}
