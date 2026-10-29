import Foundation
import Testing
@testable import SafeZone

struct ContentAndModelTests {
    @Test func fallbackGuideContainsOfflineTopics() {
        let content = GuideRepository.fallbackContent
        #expect(content.topics.isEmpty == false)
        #expect(content.contacts.isEmpty == false)
        #expect(content.topics.first?.sections.isEmpty == false)
    }

    @Test func guideJSONDecodesIntoTopicModels() throws {
        let json = """
        {
          "topics": [
            {
              "id": "test-topic",
              "title": "Test Topic",
              "subtitle": "A test subtitle",
              "iconName": "shield.fill",
              "accentHex": "#0E7490",
              "badge": "Test",
              "sections": [
                {
                  "id": "section-1",
                  "title": "First step",
                  "body": "Do the safe thing.",
                  "steps": ["Step one", "Step two"]
                }
              ],
              "contacts": []
            }
          ],
          "contacts": [
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "name": "Test Contact",
              "number": "117",
              "subtitle": "Test subtitle",
              "iconName": "phone.fill"
            }
          ]
        }
        """

        let content = try JSONDecoder().decode(GuideContent.self, from: Data(json.utf8))
        #expect(content.topics.count == 1)
        #expect(content.topics[0].sections[0].steps.count == 2)
        #expect(content.contacts[0].number == "117")
    }

    @Test func emergencyFallbackCoversAllCategories() {
        let services = EmergencyService.fallbackServices
        #expect(services.count >= 8)
        for category in EmergencyServiceCategory.allCases {
            #expect(services.contains { $0.category == category })
        }
    }

    @Test func savedLocationDisplaysRadius() {
        let location = SavedLocation.demoHome
        #expect(location.radiusDisplay.isEmpty == false)
        #expect(location.isMonitoring)
        #expect(location.weatherLocation.savedLocationID == location.id)
    }

    @Test func distanceFormattingHandlesMetersAndKilometres() {
        #expect(AppFormatters.distance(450) == "450 m")
        #expect(AppFormatters.distance(2_450) == "2.5 km")
    }
}
