import Foundation

struct UserProfile: Identifiable, Hashable, Sendable {
    let id: String
    var displayName: String
    var email: String
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var createdAt: Date

    var initials: String {
        let parts = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        let initials = String(parts).uppercased()
        return initials.isEmpty ? "SZ" : initials
    }

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    static let demo = UserProfile(
        id: "11111111-1111-1111-1111-111111111111",
        displayName: "Kasun Perera",
        email: "demo@safezone.lk",
        emergencyContactName: "Amara Perera",
        emergencyContactPhone: "+94771234567",
        createdAt: Calendar.current.date(byAdding: .day, value: -120, to: .now) ?? .now
    )
}

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case passwordsDoNotMatch
    case nameRequired
    case emailAlreadyInUse
    case invalidCredentials
    case userNotFound
    case network
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Enter a valid email address."
        case .weakPassword: return "Use at least 8 characters, including a letter and a number."
        case .passwordsDoNotMatch: return "The passwords do not match."
        case .nameRequired: return "Enter your name."
        case .emailAlreadyInUse: return "An account already exists with this email."
        case .invalidCredentials: return "The email or password is incorrect."
        case .userNotFound: return "No account was found with this email."
        case .network: return "Check your internet connection and try again."
        case .unknown(let message): return message
        }
    }
}

enum AuthValidation {
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 8 &&
        password.rangeOfCharacter(from: .letters) != nil &&
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }
}
