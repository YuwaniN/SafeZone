import Foundation
import Testing
@testable import SafeZone

struct RiskScoringEngineTests {
    private let engine = RiskScoringEngine()

    @Test func demoWeatherProducesPrototypeRiskLevels() {
        let service = DemoWeatherService()

        let home = WeatherLocation(
            id: "home",
            name: "Home",
            address: "Galle Road, Colombo 03",
            latitude: 6.8900,
            longitude: 79.8560
        )
        let work = WeatherLocation(
            id: "work",
            name: "Work",
            address: "Orion City, Colombo 09",
            latitude: 6.9270,
            longitude: 79.8650
        )
        let kolonnawa = WeatherLocation(
            id: "kolonnawa",
            name: "Kolonnawa",
            address: "Kolonnawa, Colombo",
            latitude: 6.9330,
            longitude: 79.8900
        )

        #expect(engine.assess(weather: service.snapshot(for: home)).level == .low)
        #expect(engine.assess(weather: service.snapshot(for: work)).level == .medium)
        #expect(engine.assess(weather: service.snapshot(for: kolonnawa)).level == .high)
    }

    @Test func rainfallScoringUsesDocumentedThresholds() {
        #expect(engine.scoreRainfall(0) == 0)
        #expect(engine.scoreRainfall(2.4) == 0)
        #expect(engine.scoreRainfall(3.0) == 20)
        #expect(engine.scoreRainfall(8.0) == 35)
        #expect(engine.scoreRainfall(16.0) == 50)
    }

    @Test func windScoringUsesDocumentedThresholds() {
        #expect(engine.scoreWind(10) == 0)
        #expect(engine.scoreWind(25) == 10)
        #expect(engine.scoreWind(45) == 20)
        #expect(engine.scoreWind(65) == 25)
    }

    @Test func levelBoundariesAreInclusive() {
        #expect(engine.level(for: 0) == .low)
        #expect(engine.level(for: 29) == .low)
        #expect(engine.level(for: 30) == .medium)
        #expect(engine.level(for: 59) == .medium)
        #expect(engine.level(for: 60) == .high)
        #expect(engine.level(for: 100) == .high)
    }

    @Test func assessmentIncludesFactorsAndActions() {
        let weather = DemoWeatherService().highRiskSnapshot(
            for: WeatherLocation(
                id: "test",
                name: "Test",
                address: "Test",
                latitude: 6.9,
                longitude: 79.9
            )
        )
        let assessment = engine.assess(weather: weather)

        #expect(assessment.level == .high)
        #expect(assessment.factors.count == 3)
        #expect(assessment.recommendedActions.isEmpty == false)
        #expect(assessment.summary.contains("Severe weather risk"))
    }
}
