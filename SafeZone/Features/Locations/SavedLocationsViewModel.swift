import Foundation

struct LocationRiskSummary {
    let weather: WeatherSnapshot
    let risk: RiskAssessment
    let isStale: Bool
}

@MainActor
final class SavedLocationsViewModel: ObservableObject {
    @Published private(set) var locations: [SavedLocation] = []
    @Published private(set) var summaries: [UUID: LocationRiskSummary] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer
    private let appState: AppState
    private let ownerID: String

    init(container: AppContainer, appState: AppState) {
        self.container = container
        self.appState = appState
        ownerID = appState.profile?.id ?? AppConfig.demoUserID
    }

    var monitoredCount: Int {
        locations.filter(\.isMonitoring).count
    }

    func load() async {
        isLoading = summaries.isEmpty
        do {
            locations = try container.savedLocationRepository.fetchAll(ownerID: ownerID)
            errorMessage = nil
        } catch {
            locations = []
            errorMessage = "Saved locations could not be loaded."
        }
        await loadSummaries()
        isLoading = false
    }

    func refresh() async {
        await load()
    }

    private func loadSummaries() async {
        for location in locations {
            let result = await container.weatherRepository.load(for: location.weatherLocation)
            if let weather = result.weather, let risk = result.assessment {
                summaries[location.id] = LocationRiskSummary(
                    weather: weather,
                    risk: risk,
                    isStale: result.isStale
                )
            }
        }
    }

    func setMonitoring(_ enabled: Bool, for location: SavedLocation) async {
        do {
            try container.savedLocationRepository.setMonitoring(enabled, id: location.id)
            await load()
            appState.syncGeofences()
        } catch {
            errorMessage = "The monitoring setting could not be updated."
        }
    }

    func delete(_ location: SavedLocation) {
        do {
            try container.savedLocationRepository.delete(id: location.id)
            locations.removeAll { $0.id == location.id }
            summaries[location.id] = nil
            appState.syncGeofences()
        } catch {
            errorMessage = "The location could not be deleted."
        }
    }

    func summary(for location: SavedLocation) -> LocationRiskSummary? {
        summaries[location.id]
    }
}
