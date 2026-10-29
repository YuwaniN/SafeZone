import Foundation
import LocalAuthentication

enum BiometricKind: String {
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case opticID = "Optic ID"
    case none = "Biometrics"
}

struct BiometricAvailability {
    let isAvailable: Bool
    let kind: BiometricKind
    let description: String

    static let unavailable = BiometricAvailability(
        isAvailable: false,
        kind: .none,
        description: "Biometric authentication is not available on this device."
    )
}

enum BiometricError: LocalizedError {
    case unavailable
    case cancelled
    case failed
    case lockout

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Biometric authentication is not available."
        case .cancelled: return "Authentication was cancelled."
        case .failed: return "Authentication failed. Please try again."
        case .lockout: return "Biometrics are locked. Use your device passcode to unlock, then try again."
        }
    }
}

final class BiometricService {
    func availability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .unavailable
        }

        let kind: BiometricKind
        switch context.biometryType {
        case .faceID: kind = .faceID
        case .touchID: kind = .touchID
        case .opticID: kind = .opticID
        default: kind = .none
        }

        return BiometricAvailability(
            isAvailable: true,
            kind: kind,
            description: "Use \(kind.rawValue) for quick and secure access to SafeZone."
        )
    }

    func authenticate(reason: String) async -> Result<Void, BiometricError> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError, laError.code == .biometryLockout {
                return .failure(.lockout)
            }
            return .failure(.unavailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success ? .success(()) : .failure(.failed)
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .systemCancel, .appCancel:
                return .failure(.cancelled)
            case .biometryLockout:
                return .failure(.lockout)
            default:
                return .failure(.failed)
            }
        } catch {
            return .failure(.failed)
        }
    }

    func authenticateWithDevicePasscode(reason: String) async -> Result<Void, BiometricError> {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success ? .success(()) : .failure(.failed)
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .systemCancel, .appCancel:
                return .failure(.cancelled)
            case .biometryLockout:
                return .failure(.lockout)
            default:
                return .failure(.failed)
            }
        } catch {
            return .failure(.failed)
        }
    }
}
