import Foundation

enum IncidentCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case floodedRoad
    case roadBlockage
    case fallenTree
    case stormDamage
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .floodedRoad: return "Flooded Road"
        case .roadBlockage: return "Road Blockage"
        case .fallenTree: return "Fallen Tree"
        case .stormDamage: return "Storm Damage"
        case .other: return "Other"
        }
    }

    var shortTitle: String {
        switch self {
        case .floodedRoad: return "FLOOD"
        case .roadBlockage: return "BLOCKAGE"
        case .fallenTree: return "TREE"
        case .stormDamage: return "DAMAGE"
        case .other: return "OTHER"
        }
    }

    var iconName: String {
        switch self {
        case .floodedRoad: return "water.waves"
        case .roadBlockage: return "nosign"
        case .fallenTree: return "tree.fill"
        case .stormDamage: return "bolt.trianglebadge.exclamationmark.fill"
        case .other: return "exclamationmark.bubble.fill"
        }
    }

    var systemPrompt: String {
        switch self {
        case .floodedRoad: return "Water on the road"
        case .roadBlockage: return "Road is blocked"
        case .fallenTree: return "Tree has fallen"
        case .stormDamage: return "Storm damage"
        case .other: return "Other hazard"
        }
    }
}

struct IncidentReport: Identifiable, Hashable, Sendable {
    let id: UUID
    var category: IncidentCategory
    var title: String
    var details: String
    var latitude: Double
    var longitude: Double
    var address: String
    var authorName: String
    var createdAt: Date
    var upvotes: Int
    var isVerified: Bool
    var isFlagged: Bool
    var isMine: Bool
    var photoData: Data?

    init(
        id: UUID = UUID(),
        category: IncidentCategory,
        title: String,
        details: String,
        latitude: Double,
        longitude: Double,
        address: String,
        authorName: String,
        createdAt: Date = .now,
        upvotes: Int = 0,
        isVerified: Bool = false,
        isFlagged: Bool = false,
        isMine: Bool = false,
        photoData: Data? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.details = details
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.authorName = authorName
        self.createdAt = createdAt
        self.upvotes = upvotes
        self.isVerified = isVerified
        self.isFlagged = isFlagged
        self.isMine = isMine
        self.photoData = photoData
    }

    var isUnverified: Bool { !isVerified }
}

enum IncidentFilter: String, CaseIterable, Identifiable {
    case all
    case nearby
    case verified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .nearby: return "Nearby"
        case .verified: return "Verified"
        }
    }
}

enum ReportError: LocalizedError {
    case invalidTitle
    case invalidDescription
    case missingLocation
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .invalidTitle: return "Add a short title for the report."
        case .invalidDescription: return "Describe the situation so others understand the hazard."
        case .missingLocation: return "Choose a location for this report."
        case .saveFailed: return "The report could not be saved. Please try again."
        }
    }
}
