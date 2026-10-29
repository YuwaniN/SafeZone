import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var savedLocations: [SavedLocation] = []
    @Published private(set) var selectedLocation: WeatherLocation = .colombo
    @Published private(set) var weather: WeatherSnapshot?
    @Published private(set) var risk: RiskAssessment?
    @Published private(set) var locationRisks: [UUID: RiskLevel] = [:]
    @Published private(set) var recentAlerts: [AlertRecord] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLocating = false
    @Published private(set) var isStale = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let container: AppContainer
    private let appState: AppState
    private let ownerID: String
    private var hasLoaded = false

    init(container: AppContainer, appState: AppState) {
        self.container = container
        self.appState = appState
        ownerID = appState.profile?.id ?? AppConfig.demoUserID
    }

    var profileName: String {
        appState.profile?.firstName ?? "there"
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var selectedSavedLocation: SavedLocation? {
        guard let id = selectedLocation.savedLocationID else { return nil }
        return savedLocations.first { $0.id == id }
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    func refresh() async {
        await reload()
    }

    private func reload() async {
        isLoading = weather == nil
        loadSavedLocations()
        resolveSelectedLocation()
        await loadSelectedWeather()
        await loadSavedRiskSummaries()
        loadAlerts()
        isLoading = false
    }

    private func loadSavedLocations() {
        do {
            savedLocations = try container.savedLocationRepository.fetchAll(ownerID: ownerID)
        } catch {
            savedLocations = []
            errorMessage = "Saved locations could not be loaded."
        }
    }

    private func resolveSelectedLocation() {
        guard let storedID = container.settings.selectedLocationID,
              let id = UUID(uuidString: storedID),
              let saved = savedLocations.first(where: { $0.id == id }) else {
            if selectedLocation.savedLocationID == nil && selectedLocation.id != "current" {
                selectedLocation = .colombo
            }
            return
        }
        selectedLocation = saved.weatherLocation
    }

    private func loadSelectedWeather() async {
        let result = await container.weatherRepository.load(for: selectedLocation)
        if let weather = result.weather, let assessment = result.assessment {
            self.weather = weather
            risk = assessment
            isStale = result.isStale
            errorMessage = result.errorMessage
            lastUpdated = weather.updatedAt
            if let savedID = selectedLocation.savedLocationID {
                locationRisks[savedID] = assessment.level
                handleRiskChange(
                    location: savedLocations.first { $0.id == savedID },
                    previous: result.previousLevel,
                    current: assessment
                )
            }
        } else {
            self.weather = nil
            risk = nil
            errorMessage = result.errorMessage ?? "Weather data is unavailable right now."
        }
    }

    private func loadSavedRiskSummaries() async {
        for location in savedLocations where location.id != selectedLocation.savedLocationID {
            let result = await container.weatherRepository.load(for: location.weatherLocation)
            guard let assessment = result.assessment else { continue }
            locationRisks[location.id] = assessment.level
            handleRiskChange(location: location, previous: result.previousLevel, current: assessment)
        }
    }

    private func handleRiskChange(location: SavedLocation?, previous: RiskLevel?, current: RiskAssessment) {
        guard let location,
              container.settings.riskLevelAlerts,
              container.settings.notificationsEnabled,
              location.riskLevelChanges,
              let previous,
              RiskChangeDetector.shouldNotify(previous: previous, current: current.level) else {
            return
        }

        let title = "\(location.name): \(current.level.title)"
        let message = RiskChangeDetector.alertMessage(for: current.level, locationName: location.name)
        let alert = AlertRecord(
            title: title,
            message: message,
            level: current.level,
            locationName: location.name,
            locationID: location.id,
            kind: .riskChange
        )
        try? container.alertRepository.create(alert, ownerID: ownerID)

        if container.notificationService.isAuthorized {
            container.notificationService.scheduleRiskAlert(
                title: title,
                body: message,
                level: current.level,
                locationID: location.id
            )
        }
        appState.refreshUnreadBadge()
    }

    private func loadAlerts() {
        recentAlerts = (try? container.alertRepository.fetchRecent(ownerID: ownerID, limit: 5)) ?? []
        appState.refreshUnreadBadge()
    }

    func selectLocation(_ location: SavedLocation) async {
        container.settings.selectedLocationID = location.id.uuidString
        selectedLocation = location.weatherLocation
        isLoading = weather == nil
        await loadSelectedWeather()
        isLoading = false
    }

    func selectColombo() async {
        container.settings.selectedLocationID = nil
        selectedLocation = .colombo
        isLoading = weather == nil
        await loadSelectedWeather()
        isLoading = false
    }

    func useCurrentLocation() async {
        isLocating = true
        defer { isLocating = false }
        guard let location = await container.locationService.requestLocation() else {
            errorMessage = "Location access is needed to use your current position. Enable it in Settings."
            return
        }
        let place = await container.locationService.placeName(for: location)
        let name = place ?? "Current Location"
        let coordinateKey = String(format: "current-%.3f-%.3f", location.coordinate.latitude, location.coordinate.longitude)
        selectedLocation = WeatherLocation(
            id: coordinateKey,
            name: name,
            address: name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        container.settings.selectedLocationID = nil
        isLoading = weather == nil
        await loadSelectedWeather()
        isLoading = false
    }

    func riskLevel(for location: SavedLocation) -> RiskLevel? {
        locationRisks[location.id]
    }
}
