import CoreData
import Foundation

@MainActor
protocol IncidentRepository {
    func fetchAll() throws -> [IncidentReport]
    func fetch(id: UUID) throws -> IncidentReport?
    func create(_ report: IncidentReport, ownerID: String) throws
    func upvote(id: UUID) throws
    func flag(id: UUID) throws
    func delete(id: UUID) throws
}

@MainActor
final class CoreDataIncidentRepository: IncidentRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll() throws -> [IncidentReport] {
        let request = IncidentReportEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try persistence.viewContext.fetch(request).map { $0.toModel() }
    }

    func fetch(id: UUID) throws -> IncidentReport? {
        let request = IncidentReportEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try persistence.viewContext.fetch(request).first?.toModel()
    }

    func create(_ report: IncidentReport, ownerID: String) throws {
        let entity = IncidentReportEntity(context: persistence.viewContext)
        entity.id = report.id
        entity.categoryRaw = report.category.rawValue
        entity.title = report.title
        entity.details = report.details
        entity.latitude = report.latitude
        entity.longitude = report.longitude
        entity.address = report.address
        entity.authorName = report.authorName
        entity.createdAt = report.createdAt
        entity.upvotes = Int32(report.upvotes)
        entity.isVerified = report.isVerified
        entity.isFlagged = report.isFlagged
        entity.isMine = report.isMine
        entity.ownerID = ownerID
        entity.photoData = report.photoData
        entity.isPendingSync = false
        try persistence.saveContext()
    }

    func upvote(id: UUID) throws {
        let request = IncidentReportEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try persistence.viewContext.fetch(request).first else { return }
        entity.upvotes += 1
        try persistence.saveContext()
    }

    func flag(id: UUID) throws {
        let request = IncidentReportEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try persistence.viewContext.fetch(request).first else { return }
        entity.isFlagged = true
        try persistence.saveContext()
    }

    func delete(id: UUID) throws {
        let request = IncidentReportEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        if let entity = try persistence.viewContext.fetch(request).first {
            persistence.viewContext.delete(entity)
            try persistence.saveContext()
        }
    }
}

private extension IncidentReportEntity {
    func toModel() -> IncidentReport {
        IncidentReport(
            id: id,
            category: IncidentCategory(rawValue: categoryRaw) ?? .other,
            title: title,
            details: details,
            latitude: latitude,
            longitude: longitude,
            address: address,
            authorName: authorName,
            createdAt: createdAt,
            upvotes: Int(upvotes),
            isVerified: isVerified,
            isFlagged: isFlagged,
            isMine: isMine,
            photoData: photoData
        )
    }
}
