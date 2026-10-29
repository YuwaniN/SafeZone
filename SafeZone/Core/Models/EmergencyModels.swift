import Foundation

enum EmergencyServiceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case hospital
    case police
    case fire
    case shelter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hospital: return "Hospitals"
        case .police: return "Police"
        case .fire: return "Fire"
        case .shelter: return "Shelters"
        }
    }

    var singularTitle: String {
        switch self {
        case .hospital: return "Hospital"
        case .police: return "Police Station"
        case .fire: return "Fire Station"
        case .shelter: return "Emergency Shelter"
        }
    }

    var iconName: String {
        switch self {
        case .hospital: return "cross.case.fill"
        case .police: return "shield.lefthalf.filled"
        case .fire: return "flame.fill"
        case .shelter: return "house.fill"
        }
    }

    var searchQuery: String {
        switch self {
        case .hospital: return "hospital"
        case .police: return "police station"
        case .fire: return "fire station"
        case .shelter: return "shelter"
        }
    }
}

enum MapFilter: String, CaseIterable, Identifiable {
    case all
    case hospitals
    case police
    case fire
    case shelters
    case incidents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .hospitals: return "Hospitals"
        case .police: return "Police"
        case .fire: return "Fire"
        case .shelters: return "Shelters"
        case .incidents: return "Incidents"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .hospitals: return "cross.case.fill"
        case .police: return "shield.lefthalf.filled"
        case .fire: return "flame.fill"
        case .shelters: return "house.fill"
        case .incidents: return "exclamationmark.bubble.fill"
        }
    }

    var serviceCategory: EmergencyServiceCategory? {
        switch self {
        case .hospitals: return .hospital
        case .police: return .police
        case .fire: return .fire
        case .shelters: return .shelter
        case .all, .incidents: return nil
        }
    }
}

struct EmergencyService: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: EmergencyServiceCategory
    let latitude: Double
    let longitude: Double
    let address: String
    let phoneNumber: String?
    let distanceMeters: Double?
    let isOpen: Bool?

    init(
        id: UUID = UUID(),
        name: String,
        category: EmergencyServiceCategory,
        latitude: Double,
        longitude: Double,
        address: String,
        phoneNumber: String? = nil,
        distanceMeters: Double? = nil,
        isOpen: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.phoneNumber = phoneNumber
        self.distanceMeters = distanceMeters
        self.isOpen = isOpen
    }

    var distanceDisplay: String? {
        guard let distanceMeters else { return nil }
        if distanceMeters >= 1000 {
            return String(format: "%.1f km away", distanceMeters / 1000)
        }
        return "\(Int(distanceMeters.rounded())) m away"
    }

    var mapsURL: URL? {
        URL(string: "http://maps.apple.com/?daddr=\(latitude),\(longitude)&dirflg=d")
    }

    var callURL: URL? {
        guard let phoneNumber else { return nil }
        let digits = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel://\(digits)")
    }
}

struct EmergencyContact: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let number: String
    let subtitle: String
    let iconName: String

    init(id: UUID = UUID(), name: String, number: String, subtitle: String, iconName: String) {
        self.id = id
        self.name = name
        self.number = number
        self.subtitle = subtitle
        self.iconName = iconName
    }

    var callURL: URL? {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel://\(digits)")
    }

    static let sriLankaHotlines: [EmergencyContact] = [
        EmergencyContact(name: "Disaster Management Centre", number: "117", subtitle: "DMC emergency operations", iconName: "exclamationmark.shield.fill"),
        EmergencyContact(name: "Police Emergency", number: "119", subtitle: "Sri Lanka Police", iconName: "shield.lefthalf.filled"),
        EmergencyContact(name: "Suwa Seriya Ambulance", number: "1990", subtitle: "Free pre-hospital care", iconName: "cross.case.fill"),
        EmergencyContact(name: "Fire & Rescue Service", number: "110", subtitle: "Colombo Fire Brigade", iconName: "flame.fill"),
        EmergencyContact(name: "Coast Guard", number: "118", subtitle: "Maritime rescue", iconName: "water.waves"),
        EmergencyContact(name: "Emergency Services", number: "119", subtitle: "General emergency line", iconName: "phone.fill")
    ]
}

extension EmergencyService {
    static let fallbackServices: [EmergencyService] = [
        EmergencyService(name: "National Hospital Colombo", category: .hospital, latitude: 6.9198, longitude: 79.8650, address: "E.W. Perera Mawatha, Colombo 10", phoneNumber: "+94112691111", isOpen: true),
        EmergencyService(name: "Colombo South Teaching Hospital", category: .hospital, latitude: 6.8520, longitude: 79.8635, address: "Kalubowila, Dehiwala", phoneNumber: "+94112762761", isOpen: true),
        EmergencyService(name: "Lanka Hospitals", category: .hospital, latitude: 6.8895, longitude: 79.8600, address: "578 Elvitigala Mawatha, Colombo 05", phoneNumber: "+94115430000", isOpen: true),
        EmergencyService(name: "Police Headquarters", category: .police, latitude: 6.9345, longitude: 79.8428, address: "Colombo 01", phoneNumber: "119", isOpen: true),
        EmergencyService(name: "Fort Police Station", category: .police, latitude: 6.9356, longitude: 79.8440, address: "Fort, Colombo 01", phoneNumber: "119", isOpen: true),
        EmergencyService(name: "Bambalapitiya Police Station", category: .police, latitude: 6.8901, longitude: 79.8560, address: "Galle Road, Colombo 04", phoneNumber: "119", isOpen: true),
        EmergencyService(name: "Colombo Fire Brigade", category: .fire, latitude: 6.9319, longitude: 79.8487, address: "T. B. Jayah Mawatha, Colombo 10", phoneNumber: "110", isOpen: true),
        EmergencyService(name: "Dehiwala Fire Station", category: .fire, latitude: 6.8518, longitude: 79.8650, address: "Galle Road, Dehiwala", phoneNumber: "110", isOpen: true),
        EmergencyService(name: "BMICH Emergency Shelter", category: .shelter, latitude: 6.9020, longitude: 79.8610, address: "Bauddhaloka Mawatha, Colombo 07", isOpen: true),
        EmergencyService(name: "Sugathadasa Stadium Shelter", category: .shelter, latitude: 6.9419, longitude: 79.8690, address: "Arthur de Silva Mawatha, Colombo 13", isOpen: true),
        EmergencyService(name: "Royal College Shelter", category: .shelter, latitude: 6.9066, longitude: 79.8588, address: "Rajakeeya Mawatha, Colombo 07", isOpen: true),
        EmergencyService(name: "Nalanda College Shelter", category: .shelter, latitude: 6.9128, longitude: 79.8760, address: "Albert Crescent, Colombo 07", isOpen: true)
    ]
}
