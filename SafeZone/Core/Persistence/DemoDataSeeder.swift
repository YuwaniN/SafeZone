import CoreData
import Foundation

enum DemoDataSeeder {
    static func seedIfNeeded(context: NSManagedObjectContext) {
        do {
            try seedDemoAccount(in: context)
            try seedLocations(in: context)
            try seedIncidents(in: context)
            try seedAlerts(in: context)
            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Failed to seed demo data: \(error)")
        }
    }

    private static func seedDemoAccount(in context: NSManagedObjectContext) throws {
        let request = UserAccountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "email ==[c] %@", AppConfig.demoEmail)
        request.fetchLimit = 1
        if try context.count(for: request) > 0 { return }

        let account = UserAccountEntity(context: context)
        account.id = UUID(uuidString: AppConfig.demoUserID)!
        account.email = AppConfig.demoEmail
        account.displayName = "Kasun Perera"
        account.salt = PasswordHasher.makeSalt()
        account.passwordHash = PasswordHasher.hash(password: AppConfig.demoPassword, salt: account.salt)
        account.emergencyContactName = "Amara Perera"
        account.emergencyContactPhone = "+94 77 123 4567"
        account.createdAt = Calendar.current.date(byAdding: .day, value: -120, to: .now) ?? .now
    }

    private static func seedLocations(in context: NSManagedObjectContext) throws {
        let request = SavedLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", AppConfig.demoUserID)
        request.fetchLimit = 1
        if try context.count(for: request) > 0 { return }

        for location in [SavedLocation.demoHome, SavedLocation.demoWork] {
            let entity = SavedLocationEntity(context: context)
            entity.id = location.id
            entity.ownerID = AppConfig.demoUserID
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
        }
    }

    private static func seedIncidents(in context: NSManagedObjectContext) throws {
        let request = IncidentReportEntity.fetchRequest()
        request.fetchLimit = 1
        if try context.count(for: request) > 0 { return }

        let samples: [IncidentReport] = [
            IncidentReport(
                category: .floodedRoad,
                title: "Flooded Road – Baseline Road, Colombo 09",
                details: "Water level approximately 2 feet on Baseline Road between Colombo 09 junction and Dematagoda. Multiple vehicles stranded. Avoid this route.",
                latitude: 6.9335,
                longitude: 79.8690,
                address: "Baseline Road, Colombo 09",
                authorName: "Amara D.",
                createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: .now) ?? .now,
                upvotes: 12
            ),
            IncidentReport(
                category: .fallenTree,
                title: "Fallen Tree – Galle Road near Bambalapitiya",
                details: "A large tree has fallen across two lanes near the Bambalapitiya junction. One lane is passable with care. Avoid if possible.",
                latitude: 6.8910,
                longitude: 79.8565,
                address: "Galle Road, Bambalapitiya, Colombo 04",
                authorName: "Nuwan P.",
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now,
                upvotes: 8
            ),
            IncidentReport(
                category: .roadBlockage,
                title: "Road Blockage – Kaduwela Bridge",
                details: "Kaduwela Bridge is blocked by debris and standing water. Police are redirecting traffic via the alternative route.",
                latitude: 6.9330,
                longitude: 79.9840,
                address: "Kaduwela Bridge, Kaduwela",
                authorName: "Sithara M.",
                createdAt: Calendar.current.date(byAdding: .hour, value: -4, to: .now) ?? .now,
                upvotes: 23,
                isVerified: true
            ),
            IncidentReport(
                category: .stormDamage,
                title: "Storm Damage – Dehiwala Junction",
                details: "Strong winds brought down a hoarding near Dehiwala junction. The pavement is partially blocked. Proceed with caution.",
                latitude: 6.8515,
                longitude: 79.8655,
                address: "Dehiwala Junction, Dehiwala",
                authorName: "Ruwan K.",
                createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: .now) ?? .now,
                upvotes: 5
            ),
            IncidentReport(
                category: .floodedRoad,
                title: "Flooded Road – Kolonnawa",
                details: "Water is rising quickly along the Kolonnawa main road. Several low-lying lanes are impassable for cars.",
                latitude: 6.9330,
                longitude: 79.8900,
                address: "Kolonnawa, Colombo",
                authorName: "Nimal S.",
                createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: .now) ?? .now,
                upvotes: 15
            ),
            IncidentReport(
                category: .fallenTree,
                title: "Fallen Tree – Nugegoda",
                details: "A tree has fallen onto the roadside near Nugegoda junction. No injuries reported. Take care when passing.",
                latitude: 6.8649,
                longitude: 79.8997,
                address: "Nugegoda, Colombo",
                authorName: "Ishara W.",
                createdAt: Calendar.current.date(byAdding: .hour, value: -8, to: .now) ?? .now,
                upvotes: 3,
                isVerified: true
            )
        ]

        for sample in samples {
            let entity = IncidentReportEntity(context: context)
            entity.id = sample.id
            entity.categoryRaw = sample.category.rawValue
            entity.title = sample.title
            entity.details = sample.details
            entity.latitude = sample.latitude
            entity.longitude = sample.longitude
            entity.address = sample.address
            entity.authorName = sample.authorName
            entity.createdAt = sample.createdAt
            entity.upvotes = Int32(sample.upvotes)
            entity.isVerified = sample.isVerified
            entity.isFlagged = false
            entity.isMine = false
            entity.isPendingSync = false
        }
    }

    private static func seedAlerts(in context: NSManagedObjectContext) throws {
        let request = AlertRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", AppConfig.demoUserID)
        request.fetchLimit = 1
        if try context.count(for: request) > 0 { return }

        let alerts: [AlertRecord] = [
            AlertRecord(
                title: "Heavy Rainfall Warning – Colombo",
                message: "Sustained rainfall is expected across Colombo. Risk remains Medium for the next few hours.",
                level: .medium,
                locationName: "Colombo",
                locationID: SavedLocation.demoWork.id,
                kind: .riskChange,
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now
            ),
            AlertRecord(
                title: "Entered Moderate Rain Risk Zone",
                message: "You entered the monitored zone around Home (Colombo 03). Current risk is Medium.",
                level: .medium,
                locationName: "Home",
                locationID: SavedLocation.demoHome.id,
                kind: .geofence,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            ),
            AlertRecord(
                title: "Risk cleared for Galle Road zone",
                message: "The weather risk around Home (Colombo 03) has returned to Low.",
                level: .low,
                locationName: "Home",
                locationID: SavedLocation.demoHome.id,
                kind: .geofence,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now
            )
        ]

        for alert in alerts {
            let entity = AlertRecordEntity(context: context)
            entity.id = alert.id
            entity.ownerID = AppConfig.demoUserID
            entity.title = alert.title
            entity.message = alert.message
            entity.levelRaw = alert.level.rawValue
            entity.locationName = alert.locationName
            entity.locationID = alert.locationID
            entity.kindRaw = alert.kind.rawValue
            entity.createdAt = alert.createdAt
            entity.isRead = false
        }
    }
}
