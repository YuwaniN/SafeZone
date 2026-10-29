import Foundation

struct GuideTopic: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let accentHex: String
    let badge: String?
    let sections: [GuideSection]
    let contacts: [EmergencyContact]
}

struct GuideSection: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let body: String
    let steps: [String]
}

struct GuideContent: Codable, Sendable {
    let topics: [GuideTopic]
    let contacts: [EmergencyContact]
}
