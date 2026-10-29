import SwiftUI

enum AuthRoute: Hashable {
    case register
    case forgotPassword
}

struct AuthFlowView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(container: container, appState: appState, path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView(container: container, appState: appState)
                    case .forgotPassword:
                        ForgotPasswordView(container: container)
                    }
                }
        }
    }
}

struct LoginView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @Binding var path: [AuthRoute]

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var socialMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    form
                    demoCard
                    socialSection
                    signUpPrompt
                }
                .frame(maxWidth: 480)
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Social Sign-In", isPresented: Binding(
            get: { socialMessage != nil },
            set: { if !$0 { socialMessage = nil } }
        )) {
            Button("OK", role: .cancel) { socialMessage = nil }
        } message: {
            Text(socialMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 82, height: 82)
                    .shadow(color: Theme.brandTeal.opacity(0.3), radius: 18, x: 0, y: 10)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Welcome Back")
                    .font(.szTitle(30))
                    .foregroundStyle(Theme.textPrimary)
                Text("Access real-time monitoring and emergency tools")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 18)
    }

    private var form: some View {
        VStack(spacing: 14) {
            AuthField(
                title: "Email",
                icon: "envelope.fill",
                text: $email,
                placeholder: "you@example.com",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }

            AuthField(
                title: "Password",
                icon: "lock.fill",
                text: $password,
                placeholder: "Enter your password",
                textContentType: .password,
                isSecure: !showPassword
            )
            .focused($focusedField, equals: .password)
            .submitLabel(.go)
            .onSubmit { Task { await signIn() } }
            .overlay(alignment: .trailing) {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.trailing, 14)
                }
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }

            HStack {
                Spacer()
                Button("Forgot Password?") {
                    path.append(.forgotPassword)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
            }

            if let errorMessage {
                InlineMessage(style: .error, message: errorMessage)
            }

            Button {
                Task { await signIn() }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(isLoading ? "Signing In…" : "Sign In")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            .padding(.top, 2)
        }
    }

    private var demoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.brandTeal)
                Text("Demo Account")
                    .font(.szHeadline(15))
                Spacer()
                Button("Use Demo") {
                    email = AppConfig.demoEmail
                    password = AppConfig.demoPassword
                    errorMessage = nil
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
            }
            Text("\(AppConfig.demoEmail)  •  \(AppConfig.demoPassword)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
            Text("Includes saved Home and Work locations, community reports and geofence alerts.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.brandTeal.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.brandTeal.opacity(0.16), lineWidth: 0.8)
        )
    }

    private var socialSection: some View {
        VStack(spacing: 14) {
            DividerLabel(text: "Or continue with")

            HStack(spacing: 12) {
                SocialProviderButton(title: "Google", systemImage: "g.circle.fill") {
                    socialMessage = "Google sign-in is not configured in this build. Use email or the demo account."
                }
                SocialProviderButton(title: "Apple", systemImage: "apple.logo") {
                    socialMessage = "Sign in with Apple requires a configured Apple Developer team. Use email or the demo account."
                }
            }
        }
    }

    private var signUpPrompt: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(Theme.textSecondary)
            Button("Sign Up") {
                path.append(.register)
            }
            .foregroundStyle(Theme.brandTeal)
            .fontWeight(.semibold)
        }
        .font(.system(size: 14))
    }

    private func signIn() async {
        focusedField = nil
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await appState.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct RegisterView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var emergencyName = ""
    @State private var emergencyPhone = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create Account")
                            .font(.szTitle(28))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Sign up to receive localised disaster risk alerts and emergency guidance.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    VStack(spacing: 14) {
                        AuthField(
                            title: "Full Name",
                            icon: "person.fill",
                            text: $name,
                            placeholder: "Kasun Perera",
                            textContentType: .name
                        )
                        AuthField(
                            title: "Email",
                            icon: "envelope.fill",
                            text: $email,
                            placeholder: "you@example.com",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        AuthField(
                            title: "Password",
                            icon: "lock.fill",
                            text: $password,
                            placeholder: "At least 8 characters",
                            textContentType: .newPassword,
                            isSecure: !showPassword
                        )
                        .overlay(alignment: .trailing) {
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.trailing, 14)
                            }
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                        AuthField(
                            title: "Confirm Password",
                            icon: "lock.rotation",
                            text: $confirmPassword,
                            placeholder: "Re-enter password",
                            textContentType: .newPassword,
                            isSecure: true
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Emergency Contact (optional)")
                            .font(.szHeadline(16))
                            .foregroundStyle(Theme.textPrimary)
                        AuthField(
                            title: "Contact Name",
                            icon: "person.crop.circle.badge.checkmark",
                            text: $emergencyName,
                            placeholder: "Amara Perera",
                            textContentType: .name
                        )
                        AuthField(
                            title: "Contact Number",
                            icon: "phone.fill",
                            text: $emergencyPhone,
                            placeholder: "+94 77 123 4567",
                            keyboardType: .phonePad,
                            textContentType: .telephoneNumber
                        )
                    }

                    Text("By creating an account you agree to use SafeZone as an indicative safety tool, not a replacement for official DMC warnings.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage {
                        InlineMessage(style: .error, message: errorMessage)
                    }

                    Button {
                        Task { await register() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(isLoading ? "Creating Account…" : "Create Account")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(Theme.textSecondary)
                        Button("Log In") {
                            dismiss()
                        }
                        .foregroundStyle(Theme.brandTeal)
                        .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: 480)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func register() async {
        errorMessage = nil
        guard password == confirmPassword else {
            errorMessage = AuthError.passwordsDoNotMatch.localizedDescription
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await appState.register(
                name: name,
                email: email,
                password: password,
                emergencyContactName: emergencyName.nilIfBlank,
                emergencyContactPhone: emergencyPhone.nilIfBlank
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ForgotPasswordView: View {
    let container: AppContainer
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didSend = false

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reset Password")
                            .font(.szTitle(28))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    AuthField(
                        title: "Email",
                        icon: "envelope.fill",
                        text: $email,
                        placeholder: "you@example.com",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )

                    if let errorMessage {
                        InlineMessage(style: .error, message: errorMessage)
                    }

                    if didSend {
                        InlineMessage(
                            style: .success,
                            message: "If an account exists for \(email), a password reset link has been sent. In local demo mode, use the demo credentials to sign in."
                        )
                    }

                    Button {
                        Task { await resetPassword() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(isLoading ? "Sending…" : "Send Reset Link")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading)

                    Button("Back to Log In") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .frame(maxWidth: 480)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Password Reset")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resetPassword() async {
        errorMessage = nil
        didSend = false
        isLoading = true
        defer { isLoading = false }
        do {
            try await container.authService.resetPassword(email: email)
            didSend = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AuthField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(textContentType)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
            )
        }
        .accessibilityElement(children: .contain)
    }
}

struct SocialProviderButton: View {
    let title: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}
