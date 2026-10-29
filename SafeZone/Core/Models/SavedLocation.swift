import Foundation

struct SavedLocation: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var isMonitoring: Bool
    var weatherAlerts: Bool
    var riskLevelChanges: Bool
    var emergencyAlerts: Bool
    var monitoringStartedAt: Date
    var createdAt: Date
    var sortIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 500,
        isMonitoring: Bool = true,
        weatherAlerts: Bool = true,
        riskLevelChanges: Bool = true,
        emergencyAlerts: Bool = true,
        monitoringStartedAt: Date = .now,
        createdAt: Date = .now,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.isMonitoring = isMonitoring
        self.weatherAlerts = weatherAlerts
        self.riskLevelChanges = riskLevelChanges
        self.emergencyAlerts = emergencyAlerts
        self.monitoringStartedAt = monitoringStartedAt
        self.createdAt = createdAt
        self.sortIndex = sortIndex
    }

    var weatherLocation: WeatherLocation {
        WeatherLocation(savedLocation: self)
    }

    var coordinate: (latitude: Double, longitude: Double) {
        (latitude, longitude)
    }

    var radiusDisplay: String {
        if radius >= 1000 {
            return String(format: "%.1f km", radius / 1000)
        }
        return "\(Int(radius.rounded())) m"
    }
}

extension SavedLocation {
    static let demoHome = SavedLocation(
        id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
        name: "Home",
        address: "23 Galle Road, Colombo 03",
        latitude: 6.8916,
        longitude: 79.8558,
        radius: 500,
        monitoringStartedAt: Calendar.current.date(byAdding: .day, value: -44, to: .now) ?? .now,
        createdAt: Calendar.current.date(byAdding: .day, value: -120, to: .now) ?? .now,
        sortIndex: 0
    )

    static let demoWork = SavedLocation(
        id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
        name: "Work",
        address: "Orion City, Colombo 09",
        latitude: 6.9254,
        longitude: 79.8698,
        radius: 500,
        monitoringStartedAt: Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now,
        createdAt: Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now,
        sortIndex: 1
    )
}
