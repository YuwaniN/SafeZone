import CoreData
import Foundation

@objc(UserAccountEntity)
final class UserAccountEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var email: String
    @NSManaged var displayName: String
    @NSManaged var passwordHash: String
    @NSManaged var salt: String
    @NSManaged var emergencyContactName: String?
    @NSManaged var emergencyContactPhone: String?
    @NSManaged var createdAt: Date
}

@objc(SavedLocationEntity)
final class SavedLocationEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var ownerID: String
    @NSManaged var name: String
    @NSManaged var address: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var radius: Double
    @NSManaged var isMonitoring: Bool
    @NSManaged var weatherAlerts: Bool
    @NSManaged var riskLevelChanges: Bool
    @NSManaged var emergencyAlerts: Bool
    @NSManaged var monitoringStartedAt: Date
    @NSManaged var createdAt: Date
    @NSManaged var sortIndex: Int16
}

@objc(IncidentReportEntity)
final class IncidentReportEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var categoryRaw: String
    @NSManaged var title: String
    @NSManaged var details: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var address: String
    @NSManaged var authorName: String
    @NSManaged var createdAt: Date
    @NSManaged var upvotes: Int32
    @NSManaged var isVerified: Bool
    @NSManaged var isFlagged: Bool
    @NSManaged var isMine: Bool
    @NSManaged var ownerID: String?
    @NSManaged var isPendingSync: Bool
    @NSManaged var photoData: Data?
}

@objc(RiskSnapshotEntity)
final class RiskSnapshotEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var locationKey: String
    @NSManaged var locationName: String
    @NSManaged var score: Int16
    @NSManaged var levelRaw: String
    @NSManaged var temperature: Double
    @NSManaged var rainfall: Double
    @NSManaged var wind: Double
    @NSManaged var humidity: Int16
    @NSManaged var conditionRaw: String
    @NSManaged var weatherData: Data?
    @NSManaged var createdAt: Date
}

@objc(AlertRecordEntity)
final class AlertRecordEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var ownerID: String
    @NSManaged var title: String
    @NSManaged var message: String
    @NSManaged var levelRaw: String
    @NSManaged var locationName: String
    @NSManaged var locationID: UUID?
    @NSManaged var kindRaw: String
    @NSManaged var createdAt: Date
    @NSManaged var isRead: Bool
}
