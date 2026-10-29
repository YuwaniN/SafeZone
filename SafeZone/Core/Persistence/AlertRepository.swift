import CoreData
import Foundation

@MainActor
protocol AlertRepository {
    func fetchRecent(ownerID: String, limit: Int) throws -> [AlertRecord]
    func fetch(ownerID: String, locationID: UUID) throws -> [AlertRecord]
    func create(_ alert: AlertRecord, ownerID: String) throws
    func markAllRead(ownerID: String) throws
    func unreadCount(ownerID: String) throws -> Int
}

@MainActor
final class CoreDataAlertRepository: AlertRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchRecent(ownerID: String, limit: Int = 20) throws -> [AlertRecord] {
        let request = AlertRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        return try persistence.viewContext.fetch(request).map { $0.toModel() }
    }

    func fetch(ownerID: String, locationID: UUID) throws -> [AlertRecord] {
        let request = AlertRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@ AND locationID == %@", ownerID, locationID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try persistence.viewContext.fetch(request).map { $0.toModel() }
    }

    func create(_ alert: AlertRecord, ownerID: String) throws {
        let entity = AlertRecordEntity(context: persistence.viewContext)
        entity.id = alert.id
        entity.ownerID = ownerID
        entity.title = alert.title
        entity.message = alert.message
        entity.levelRaw = alert.level.rawValue
        entity.locationName = alert.locationName
        entity.locationID = alert.locationID
        entity.kindRaw = alert.kind.rawValue
        entity.createdAt = alert.createdAt
        entity.isRead = alert.isRead
        try persistence.saveContext()
    }

    func markAllRead(ownerID: String) throws {
        let request = AlertRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@ AND isRead == NO", ownerID)
        let alerts = try persistence.viewContext.fetch(request)
        alerts.forEach { $0.isRead = true }
        try persistence.saveContext()
    }

    func unreadCount(ownerID: String) throws -> Int {
        let request = AlertRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@ AND isRead == NO", ownerID)
        return try persistence.viewContext.count(for: request)
    }
}

private extension AlertRecordEntity {
    func toModel() -> AlertRecord {
        AlertRecord(
            id: id,
            title: title,
            message: message,
            level: RiskLevel(rawValue: levelRaw) ?? .low,
            locationName: locationName,
            locationID: locationID,
            kind: AlertKind(rawValue: kindRaw) ?? .riskChange,
            createdAt: createdAt,
            isRead: isRead
        )
    }
}
