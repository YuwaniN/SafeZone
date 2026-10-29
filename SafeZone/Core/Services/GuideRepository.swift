import Foundation

struct GuideRepository {
    func loadGuide(bundle: Bundle = .main) -> GuideContent {
        let url = bundle.url(forResource: "guide", withExtension: "json")
            ?? bundle.url(forResource: "guide", withExtension: "json", subdirectory: "Guide")

        guard let url,
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(GuideContent.self, from: data) else {
            return Self.fallbackContent
        }
        return content
    }

    static let fallbackContent = GuideContent(
        topics: [
            GuideTopic(
                id: "flood-safety",
                title: "Flood Safety",
                subtitle: "Stay safe before, during and after flooding",
                iconName: "water.waves",
                accentHex: "#2563EB",
                badge: "Offline",
                sections: [
                    GuideSection(
                        id: "flood-1",
                        title: "Move to higher ground",
                        body: "If flooding is imminent, move to the highest point in your building or evacuate to elevated terrain.",
                        steps: []
                    ),
                    GuideSection(
                        id: "flood-2",
                        title: "Avoid floodwater",
                        body: "Never walk, swim or drive through flood waters. Just 6 inches of moving water can knock you down.",
                        steps: []
                    )
                ],
                contacts: []
            )
        ],
        contacts: EmergencyContact.sriLankaHotlines
    )
}
