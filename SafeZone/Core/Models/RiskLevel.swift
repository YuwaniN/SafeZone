import Foundation

enum RiskLevel: String, Codable, CaseIterable, Identifiable, Sendable, Comparable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        }
    }

    var shortTitle: String {
        switch self {
        case .low: return "LOW"
        case .medium: return "MEDIUM"
        case .high: return "HIGH"
        }
    }

    var priority: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    var recommendedAction: String {
        switch self {
        case .low: return "Conditions are calm. Continue normal activities and stay informed."
        case .medium: return "Prepare emergency supplies and keep an eye on official updates."
        case .high: return "Take action now. Review official warnings and be ready to move to safety."
        }
    }

    var iconName: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.priority < rhs.priority
    }
}

struct RiskFactor: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let detail: String
    let iconName: String
    let impact: Impact

    enum Impact: String, Hashable, Sendable {
        case low
        case moderate
        case elevated
        case severe
    }
}

struct RiskAssessment: Hashable, Sendable {
    let level: RiskLevel
    let score: Int
    let summary: String
    let recommendedActions: [String]
    let factors: [RiskFactor]
    let assessedAt: Date

    var isElevated: Bool { level >= .medium }

    static let placeholder = RiskAssessment(
        level: .low,
        score: 12,
        summary: "No significant weather risk is expected in the near term.",
        recommendedActions: ["Continue normal activities", "Keep monitoring official updates"],
        factors: [],
        assessedAt: .now
    )
}

struct RiskChangeDetector {
    static func shouldNotify(previous: RiskLevel?, current: RiskLevel) -> Bool {
        guard let previous else { return false }
        if current == .high && previous != .high { return true }
        return current != previous
    }

    static func alertMessage(for level: RiskLevel, locationName: String) -> String {
        switch level {
        case .low:
            return "Weather risk at \(locationName) has eased to Low. Normal activity can resume."
        case .medium:
            return "Weather risk at \(locationName) has risen to Medium. Prepare supplies and monitor updates."
        case .high:
            return "Weather risk at \(locationName) is now High. Review official warnings and be ready to act."
        }
    }
}
