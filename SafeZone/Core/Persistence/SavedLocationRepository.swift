import CoreData
import Foundation

@MainActor
protocol SavedLocationRepository {
    func fetchAll(ownerID: String) throws -> [SavedLocation]
    func fetch(id: UUID) throws -> SavedLocation?
    func save(_ location: SavedLocation, ownerID: String) throws
    func delete(id: UUID) throws
    func setMonitoring(_ enabled: Bool, id: UUID) throws
    func monitoredLocations(ownerID: String) throws -> [SavedLocation]
}

@MainActor
final class CoreDataSavedLocationRepository: SavedLocationRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll(ownerID: String) throws -> [SavedLocation] {
        let request = SavedLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortIndex", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return try persistence.viewContext.fetch(request).map { $0.toModel() }
    }

    func fetch(id: UUID) throws -> SavedLocation? {
        let request = SavedLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try persistence.viewContext.fetch(request).first?.toModel()
    }

    func save(_ location: SavedLocation, ownerID: String) throws {
        let request = SavedLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", location.id as CVarArg)
        request.fetchLimit = 1

        let entity = try persistence.viewContext.fetch(request).first ?? SavedLocationEntity(context: persistence.viewContext)
        entity.id = location.id
        entity.ownerID = ownerID
        entity.name = location.name
        entity.address = location.address
        entity.latitude = location.latitude
        entity.longitude = location.longitude
        entity.radius = location.radius
        entity.isMonitoring = location.isMonitoring
        entity.weatherAlerts = location.weatherAlerts
        entity.riskLevelChanges = location.riskLevelChanges
        entity.emergencyAlerts = location.emergencyAlerts
        entity.monitoringStartedAt = location.monitoringStartedAt
        entity.createdAt = location.createdAt
        entity.sortIndex = Int16(location.sortIndex)
        try persistence.saveContext()
    }

    func delete(id: UUID) throws {
        let request = SavedLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        if let entity = try persistence.viewContext.fetch(request).first {
            persistence.viewContext.delete(entity)
            try persistence.saveContext()
        }
    }

    func setMonitoring(_ enabled: Bool, id: UUID) throws {
        let request = SavedLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try persistence.viewContext.fetch(request).first else { return }
        entity.isMonitoring = enabled
        if enabled {
            entity.monitoringStartedAt = .now
        }
        try persistence.saveContext()
    }

    func monitoredLocations(ownerID: String) throws -> [SavedLocation] {
        try fetchAll(ownerID: ownerID).filter(\.isMonitoring)
    }
}

private extension SavedLocationEntity {
    func toModel() -> SavedLocation {
        SavedLocation(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            isMonitoring: isMonitoring,
            weatherAlerts: weatherAlerts,
            riskLevelChanges: riskLevelChanges,
            emergencyAlerts: emergencyAlerts,
            monitoringStartedAt: monitoringStartedAt,
            createdAt: createdAt,
            sortIndex: Int(sortIndex)
        )
    }
}
