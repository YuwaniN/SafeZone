import Foundation

enum AlertKind: String, Codable, Sendable {
    case riskChange
    case geofence
    case emergency
}

struct AlertRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let message: String
    let level: RiskLevel
    let locationName: String
    let locationID: UUID?
    let kind: AlertKind
    let createdAt: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        level: RiskLevel,
        locationName: String,
        locationID: UUID? = nil,
        kind: AlertKind,
        createdAt: Date = .now,
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.level = level
        self.locationName = locationName
        self.locationID = locationID
        self.kind = kind
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

struct AlertBanner: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let level: RiskLevel
    let locationName: String
    let locationID: UUID?

    var isHighRisk: Bool { level == .high }
}
