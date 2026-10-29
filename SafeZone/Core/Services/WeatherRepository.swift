import Foundation

struct WeatherLoadResult {
    let weather: WeatherSnapshot?
    let assessment: RiskAssessment?
    let isStale: Bool
    let errorMessage: String?
    let previousLevel: RiskLevel?

    var hasData: Bool {
        weather != nil && assessment != nil
    }

    static let empty = WeatherLoadResult(
        weather: nil,
        assessment: nil,
        isStale: false,
        errorMessage: nil,
        previousLevel: nil
    )
}

@MainActor
final class WeatherRepository {
    let provider: WeatherProviding
    private let snapshots: RiskSnapshotRepository
    let engine: RiskScoringEngine

    init(
        provider: WeatherProviding,
        snapshots: RiskSnapshotRepository,
        engine: RiskScoringEngine = RiskScoringEngine()
    ) {
        self.provider = provider
        self.snapshots = snapshots
        self.engine = engine
    }

    func load(for location: WeatherLocation) async -> WeatherLoadResult {
        let previous = try? snapshots.previousLevel(locationKey: location.id)

        do {
            let weather = try await provider.fetchWeather(for: location)
            let assessment = engine.assess(weather: weather)
            try? snapshots.save(weather: weather, assessment: assessment, location: location)
            return WeatherLoadResult(
                weather: weather,
                assessment: assessment,
                isStale: false,
                errorMessage: nil,
                previousLevel: previous
            )
        } catch {
            if let cached = try? snapshots.latest(locationKey: location.id) {
                let assessment = engine.assess(weather: cached.weather)
                return WeatherLoadResult(
                    weather: cached.weather,
                    assessment: assessment,
                    isStale: true,
                    errorMessage: friendlyMessage(for: error),
                    previousLevel: previous
                )
            }

            return WeatherLoadResult(
                weather: nil,
                assessment: nil,
                isStale: false,
                errorMessage: friendlyMessage(for: error),
                previousLevel: previous
            )
        }
    }

    func loadAll(for locations: [WeatherLocation]) async -> [String: WeatherLoadResult] {
        var results: [String: WeatherLoadResult] = [:]
        for location in locations {
            results[location.id] = await load(for: location)
        }
        return results
    }

    func highRiskAssessment(for location: WeatherLocation) -> (WeatherSnapshot, RiskAssessment) {
        let weather: WeatherSnapshot
        if let demo = provider as? DemoWeatherService {
            weather = demo.highRiskSnapshot(for: location)
        } else {
            weather = WeatherSnapshot(
                temperatureC: 27,
                feelsLikeC: 31,
                humidity: 93,
                windKph: 52,
                rainfallMM: 16.8,
                dailyRainfallMM: 104.2,
                condition: .thunderstorm,
                conditionDescription: "Thunderstorm",
                forecast: [],
                source: .demo
            )
        }
        return (weather, engine.assess(weather: weather))
    }

    private func friendlyMessage(for error: Error) -> String {
        if let weatherError = error as? WeatherError {
            return weatherError.errorDescription ?? "Weather data is unavailable."
        }
        return error.localizedDescription
    }
}
