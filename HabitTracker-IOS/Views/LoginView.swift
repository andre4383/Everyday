import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingRegister = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 40)

                Text("Welcome back.")
                    .font(.display())
                    .foregroundStyle(Theme.textPrimary)

                Text("Sign in to keep your streaks going.")
                    .font(.body_())
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)

                VStack(spacing: 32) {
                    inputField(label: "Email", text: $email, secure: false, keyboard: .emailAddress)
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
                    Task { await handleLogin() }
                } label: {
                    HStack {
                        Text("Sign in")
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
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button {
                    showingRegister = true
                } label: {
                    Text("Create an account")
                        .font(.small())
                        .foregroundStyle(Theme.textPrimary)
                        .underline()
                }
                .padding(.top, 24)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }

    private func inputField(label: String, text: Binding<String>, secure: Bool, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.small())
                .foregroundStyle(Theme.textSecondary)

            Group {
                if secure {
                    SecureField("", text: text)
                        .textContentType(.password)
                } else {
                    TextField("", text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(.body_())
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.divider).frame(height: 1)
            }
        }
    }

    private func handleLogin() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.login(email: email, password: password)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService.shared)
}
