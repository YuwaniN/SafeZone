import CoreData
import Foundation
import Testing
@testable import SafeZone

@MainActor
struct PersistenceRepositoryTests {
    @Test func demoDataIsSeededOnce() throws {
        let persistence = PersistenceController(inMemory: true)
        let locations = try CoreDataSavedLocationRepository(persistence: persistence)
            .fetchAll(ownerID: AppConfig.demoUserID)
        let incidents = try CoreDataIncidentRepository(persistence: persistence).fetchAll()
        let alerts = try CoreDataAlertRepository(persistence: persistence)
            .unreadCount(ownerID: AppConfig.demoUserID)

        #expect(locations.count == 2)
        #expect(locations.filter(\.isMonitoring).count == 2)
        #expect(incidents.count == 6)
        #expect(alerts == 3)

        let secondController = PersistenceController(inMemory: true)
        let secondCount = try CoreDataSavedLocationRepository(persistence: secondController)
            .fetchAll(ownerID: AppConfig.demoUserID)
            .count
        #expect(secondCount == 2)
    }

    @Test func incidentLifecycle() throws {
        let persistence = PersistenceController(inMemory: true)
        let repository = CoreDataIncidentRepository(persistence: persistence)
        let report = IncidentReport(
            category: .floodedRoad,
            title: "Test flood report",
            details: "Water is rising across the test road and should be avoided.",
            latitude: 6.9271,
            longitude: 79.8612,
            address: "Test Road, Colombo",
            authorName: "Test User",
            isMine: true
        )

        try repository.create(report, ownerID: AppConfig.demoUserID)
        let created = try repository.fetch(id: report.id)
        #expect(created?.title == report.title)
        #expect(created?.isMine == true)

        try repository.upvote(id: report.id)
        let upvoted = try repository.fetch(id: report.id)
        #expect(upvoted?.upvotes == 1)

        try repository.flag(id: report.id)
        let flagged = try repository.fetch(id: report.id)
        #expect(flagged?.isFlagged == true)

        try repository.delete(id: report.id)
        let deleted = try repository.fetch(id: report.id)
        #expect(deleted == nil)
    }

    @Test func alertReadStateUpdatesUnreadCount() throws {
        let persistence = PersistenceController(inMemory: true)
        let repository = CoreDataAlertRepository(persistence: persistence)

        #expect(try repository.unreadCount(ownerID: AppConfig.demoUserID) == 3)
        try repository.markAllRead(ownerID: AppConfig.demoUserID)
        #expect(try repository.unreadCount(ownerID: AppConfig.demoUserID) == 0)
    }

    @Test func demoAccountCanSignIn() async throws {
        let persistence = PersistenceController(inMemory: true)
        let suiteName = "SafeZoneTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let auth = LocalAuthService(persistence: persistence, defaults: defaults)
        let profile = try await auth.login(
            email: AppConfig.demoEmail,
            password: AppConfig.demoPassword
        )

        #expect(profile.id == AppConfig.demoUserID)
        #expect(profile.displayName == "Kasun Perera")
        #expect(profile.emergencyContactName == "Amara Perera")
        #expect(auth.currentUser?.email == AppConfig.demoEmail)
    }

    @Test func invalidCredentialsAreRejected() async throws {
        let persistence = PersistenceController(inMemory: true)
        let suiteName = "SafeZoneTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let auth = LocalAuthService(persistence: persistence, defaults: defaults)

        await #expect(throws: AuthError.self) {
            try await auth.login(email: AppConfig.demoEmail, password: "WrongPassword1")
        }
    }
}
