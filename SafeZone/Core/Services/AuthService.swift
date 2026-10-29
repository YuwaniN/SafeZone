import CoreData
import Foundation

@MainActor
protocol AuthService: AnyObject {
    var currentUser: UserProfile? { get }
    func restoreSession() -> UserProfile?
    func register(
        name: String,
        email: String,
        password: String,
        emergencyContactName: String?,
        emergencyContactPhone: String?
    ) async throws -> UserProfile
    func login(email: String, password: String) async throws -> UserProfile
    func resetPassword(email: String) async throws
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
    func logout()
}

@MainActor
final class LocalAuthService: AuthService {
    private let persistence: PersistenceController
    private let defaults: UserDefaults
    private let sessionKey = "auth.currentUserID"

    private(set) var currentUser: UserProfile?

    init(persistence: PersistenceController, defaults: UserDefaults = .standard) {
        self.persistence = persistence
        self.defaults = defaults
    }

    func restoreSession() -> UserProfile? {
        guard let idString = defaults.string(forKey: sessionKey),
              let id = UUID(uuidString: idString),
              let entity = fetchAccount(id: id) else {
            return nil
        }
        let profile = entity.toProfile()
        currentUser = profile
        return profile
    }

    func register(
        name: String,
        email: String,
        password: String,
        emergencyContactName: String?,
        emergencyContactPhone: String?
    ) async throws -> UserProfile {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmedName.isEmpty else { throw AuthError.nameRequired }
        guard AuthValidation.isValidEmail(normalizedEmail) else { throw AuthError.invalidEmail }
        guard AuthValidation.isValidPassword(password) else { throw AuthError.weakPassword }
        guard fetchAccount(email: normalizedEmail) == nil else { throw AuthError.emailAlreadyInUse }

        let account = UserAccountEntity(context: persistence.viewContext)
        account.id = UUID()
        account.email = normalizedEmail
        account.displayName = trimmedName
        account.salt = PasswordHasher.makeSalt()
        account.passwordHash = PasswordHasher.hash(password: password, salt: account.salt)
        account.emergencyContactName = emergencyContactName?.nilIfBlank
        account.emergencyContactPhone = emergencyContactPhone?.nilIfBlank
        account.createdAt = .now

        do {
            try persistence.saveContext()
        } catch {
            throw AuthError.unknown("Your account could not be created. Please try again.")
        }

        defaults.set(account.id.uuidString, forKey: sessionKey)
        let profile = account.toProfile()
        currentUser = profile
        return profile
    }

    func login(email: String, password: String) async throws -> UserProfile {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard AuthValidation.isValidEmail(normalizedEmail) else { throw AuthError.invalidEmail }
        guard let account = fetchAccount(email: normalizedEmail) else {
            throw AuthError.invalidCredentials
        }
        guard PasswordHasher.verify(password: password, salt: account.salt, expectedHash: account.passwordHash) else {
            throw AuthError.invalidCredentials
        }

        defaults.set(account.id.uuidString, forKey: sessionKey)
        let profile = account.toProfile()
        currentUser = profile
        return profile
    }

    func resetPassword(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard AuthValidation.isValidEmail(normalizedEmail) else { throw AuthError.invalidEmail }
        guard fetchAccount(email: normalizedEmail) != nil else {
            throw AuthError.userNotFound
        }
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        guard let id = UUID(uuidString: profile.id), let account = fetchAccount(id: id) else {
            throw AuthError.userNotFound
        }
        account.displayName = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        account.emergencyContactName = profile.emergencyContactName?.nilIfBlank
        account.emergencyContactPhone = profile.emergencyContactPhone?.nilIfBlank
        try persistence.saveContext()
        let updated = account.toProfile()
        currentUser = updated
        return updated
    }

    func logout() {
        defaults.removeObject(forKey: sessionKey)
        currentUser = nil
    }

    private func fetchAccount(id: UUID) -> UserAccountEntity? {
        let request = UserAccountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? persistence.viewContext.fetch(request).first
    }

    private func fetchAccount(email: String) -> UserAccountEntity? {
        let request = UserAccountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "email ==[c] %@", email)
        request.fetchLimit = 1
        return try? persistence.viewContext.fetch(request).first
    }
}

private extension UserAccountEntity {
    func toProfile() -> UserProfile {
        UserProfile(
            id: id.uuidString,
            displayName: displayName,
            email: email,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone,
            createdAt: createdAt
        )
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
