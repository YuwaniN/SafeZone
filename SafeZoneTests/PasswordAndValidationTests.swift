import Foundation
import Testing
@testable import SafeZone

struct PasswordAndValidationTests {
    @Test func hashedPasswordVerifiesOnlyWithCorrectPassword() {
        let salt = PasswordHasher.makeSalt()
        let hash = PasswordHasher.hash(password: AppConfig.demoPassword, salt: salt)

        #expect(PasswordHasher.verify(password: AppConfig.demoPassword, salt: salt, expectedHash: hash))
        #expect(!PasswordHasher.verify(password: "WrongPassword1", salt: salt, expectedHash: hash))
        #expect(!PasswordHasher.verify(password: AppConfig.demoPassword, salt: "different-salt", expectedHash: hash))
    }

    @Test func saltsAreUnique() {
        let first = PasswordHasher.makeSalt()
        let second = PasswordHasher.makeSalt()
        #expect(first != second)
        #expect(first.isEmpty == false)
    }

    @Test func emailValidation() {
        #expect(AuthValidation.isValidEmail("demo@safezone.lk"))
        #expect(AuthValidation.isValidEmail("user.name+tag@example.co.uk"))
        #expect(!AuthValidation.isValidEmail("not-an-email"))
        #expect(!AuthValidation.isValidEmail("user@"))
        #expect(!AuthValidation.isValidEmail(""))
    }

    @Test func passwordValidation() {
        #expect(AuthValidation.isValidPassword("SafeZone123"))
        #expect(!AuthValidation.isValidPassword("short1"))
        #expect(!AuthValidation.isValidPassword("onlyletters"))
        #expect(!AuthValidation.isValidPassword("12345678"))
    }

    @Test func riskChangeDetection() {
        #expect(RiskChangeDetector.shouldNotify(previous: nil, current: .high) == false)
        #expect(RiskChangeDetector.shouldNotify(previous: .low, current: .high))
        #expect(RiskChangeDetector.shouldNotify(previous: .medium, current: .low))
        #expect(RiskChangeDetector.shouldNotify(previous: .medium, current: .medium) == false)
    }
}
