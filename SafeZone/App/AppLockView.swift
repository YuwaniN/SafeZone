import SwiftUI

struct AppLockView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState

    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @State private var hasAttempted = false

    private var availability: BiometricAvailability {
        container.biometricService.availability()
    }

    var body: some View {
        ScreenBackground {
            VStack(spacing: 22) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Theme.aquaGradient)
                        .frame(width: 118, height: 118)
                        .shadow(color: Theme.brandTeal.opacity(0.35), radius: 26, x: 0, y: 12)
                    Image(systemName: availability.kind == .touchID ? "touchid" : "faceid")
                        .font(.szScaled(50, weight: .light))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("SafeZone is locked")
                        .font(.szTitle(27))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Verify it's you to view risk alerts and emergency information.")
                        .font(.szScaled(15))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                if let errorMessage {
                    InlineMessage(style: .error, message: errorMessage)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 12) {
                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack(spacing: 9) {
                            if isAuthenticating {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: availability.kind == .touchID ? "touchid" : "faceid")
                            }
                            Text(isAuthenticating ? "Verifying…" : "Unlock with \(availability.kind.rawValue)")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isAuthenticating)

                    Button("Use Device Passcode") {
                        Task { await authenticate(usePasscode: true) }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isAuthenticating)

                    Button("Sign in with Password") {
                        appState.signOut()
                    }
                    .font(.szScaled(14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)

                Spacer()
                Spacer()
            }
        }
        .task {
            guard !hasAttempted else { return }
            hasAttempted = true
            await authenticate()
        }
        .accessibilityElement(children: .contain)
    }

    private func authenticate(usePasscode: Bool = false) async {
        isAuthenticating = true
        errorMessage = nil
        let result: Result<Void, BiometricError>
        if usePasscode {
            result = await container.biometricService.authenticateWithDevicePasscode(
                reason: "Unlock SafeZone to view your risk alerts."
            )
        } else {
            result = await container.biometricService.authenticate(
                reason: "Unlock SafeZone to view your risk alerts."
            )
        }
        isAuthenticating = false
        switch result {
        case .success:
            appState.unlock()
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }
}
