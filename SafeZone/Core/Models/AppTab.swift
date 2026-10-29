import Foundation

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case map
    case reports
    case guide
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .map: return "Map"
        case .reports: return "Reports"
        case .guide: return "Guide"
        case .profile: return "Profile"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .map: return "map.fill"
        case .reports: return "exclamationmark.bubble.fill"
        case .guide: return "book.closed.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}
