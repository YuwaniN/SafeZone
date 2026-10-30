import SwiftUI

struct FaceIDSetupView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState

    @State private var isAuthenticating = false
    @State private var errorMessage: String?

    private var availability: BiometricAvailability {
        container.biometricService.availability()
    }

    var body: some View {
        ScreenBackground {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(Theme.aquaGradient)
                            .frame(width: 128, height: 128)
                            .shadow(color: Theme.brandTeal.opacity(0.35), radius: 28, x: 0, y: 14)
                        Image(systemName: availability.kind == .touchID ? "touchid" : "faceid")
                            .font(.szScaled(56, weight: .light))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        Text("Use \(availability.kind.rawValue) to Log In")
                            .font(.szTitle(28))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("Quick and secure access to your SafeZone account for real-time risk alerts and DMC response tracking.")
                            .font(.szScaled(15))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    if !availability.isAvailable {
                        InlineMessage(
                            style: .info,
                            message: "Biometrics are not available on this device. You can sign in with your password and enable Face ID later."
                        )
                        .padding(.horizontal, 28)
                    }

                    if let errorMessage {
                        InlineMessage(style: .error, message: errorMessage)
                            .padding(.horizontal, 28)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    if availability.isAvailable {
                        Button {
                            Task { await enableBiometrics() }
                        } label: {
                            HStack(spacing: 9) {
                                if isAuthenticating {
                                    ProgressView().tint(.white)
                                }
                                Text(isAuthenticating ? "Enabling…" : "Enable \(availability.kind.rawValue)")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isAuthenticating)
                    }

                    Button(availability.isAvailable ? "Not Now" : "Continue") {
                        appState.finishBiometricSetup(enabled: false)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text("You can change this any time in Profile settings.")
                        .font(.szScaled(12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 34)
            }
        }
    }

    private func enableBiometrics() async {
        isAuthenticating = true
        errorMessage = nil
        let result = await container.biometricService.authenticate(
            reason: "Enable biometric login for SafeZone."
        )
        isAuthenticating = false
        switch result {
        case .success:
            appState.finishBiometricSetup(enabled: true)
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }
}
