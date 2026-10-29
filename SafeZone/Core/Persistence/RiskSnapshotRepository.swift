import CoreData
import Foundation

struct CachedRisk: Hashable {
    let weather: WeatherSnapshot
    let level: RiskLevel
    let score: Int
    let cachedAt: Date
}

@MainActor
protocol RiskSnapshotRepository {
    func save(weather: WeatherSnapshot, assessment: RiskAssessment, location: WeatherLocation) throws
    func latest(locationKey: String) throws -> CachedRisk?
    func previousLevel(locationKey: String) throws -> RiskLevel?
}

@MainActor
final class CoreDataRiskSnapshotRepository: RiskSnapshotRepository {
    private let persistence: PersistenceController
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func save(weather: WeatherSnapshot, assessment: RiskAssessment, location: WeatherLocation) throws {
        let entity = RiskSnapshotEntity(context: persistence.viewContext)
        entity.id = UUID()
        entity.locationKey = location.id
        entity.locationName = location.name
        entity.score = Int16(assessment.score)
        entity.levelRaw = assessment.level.rawValue
        entity.temperature = weather.temperatureC
        entity.rainfall = weather.dailyRainfallMM
        entity.wind = weather.windKph
        entity.humidity = Int16(weather.humidity)
        entity.conditionRaw = weather.condition.rawValue
        entity.weatherData = try encoder.encode(weather)
        entity.createdAt = .now
        try persistence.saveContext()
        trimHistory(locationKey: location.id)
    }

    func latest(locationKey: String) throws -> CachedRisk? {
        let request = RiskSnapshotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "locationKey == %@", locationKey)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        guard let entity = try persistence.viewContext.fetch(request).first else { return nil }

        let weather: WeatherSnapshot
        if let data = entity.weatherData, let decoded = try? decoder.decode(WeatherSnapshot.self, from: data) {
            weather = decoded
        } else {
            weather = WeatherSnapshot(
                temperatureC: entity.temperature,
                feelsLikeC: entity.temperature,
                humidity: Int(entity.humidity),
                windKph: entity.wind,
                rainfallMM: 0,
                dailyRainfallMM: entity.rainfall,
                condition: WeatherCondition(rawValue: entity.conditionRaw) ?? .unknown,
                conditionDescription: WeatherCondition(rawValue: entity.conditionRaw)?.title ?? "Unknown",
                forecast: [],
                updatedAt: entity.createdAt,
                source: .cached
            )
        }

        return CachedRisk(
            weather: weather,
            level: RiskLevel(rawValue: entity.levelRaw) ?? .low,
            score: Int(entity.score),
            cachedAt: entity.createdAt
        )
    }

    func previousLevel(locationKey: String) throws -> RiskLevel? {
        try latest(locationKey: locationKey)?.level
    }

    private func trimHistory(locationKey: String) {
        let request = RiskSnapshotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "locationKey == %@", locationKey)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        guard let entities = try? persistence.viewContext.fetch(request), entities.count > 40 else { return }
        for entity in entities.dropFirst(40) {
            persistence.viewContext.delete(entity)
        }
        try? persistence.saveContext()
    }
}
