import Foundation
import UIKit

@MainActor
final class GeofenceMonitoringViewModel: ObservableObject {
    @Published private(set) var locations: [SavedLocation] = []
    @Published private(set) var selectedLocation: SavedLocation?
    @Published private(set) var alerts: [AlertRecord] = []
    @Published private(set) var isSimulating = false
    @Published private(set) var lastResult: GeofenceSimulationResult?
    @Published private(set) var errorMessage: String?

    private let container: AppContainer
    private let appState: AppState
    private let ownerID: String

    init(container: AppContainer, appState: AppState) {
        self.container = container
        self.appState = appState
        ownerID = appState.profile?.id ?? AppConfig.demoUserID
    }

    func load() async {
        do {
            let all = try container.savedLocationRepository.fetchAll(ownerID: ownerID)
            let monitored = all.filter(\.isMonitoring)
            locations = monitored.isEmpty ? all : monitored
            errorMessage = nil
        } catch {
            locations = []
            errorMessage = "Monitored locations could not be loaded."
        }

        if let current = selectedLocation, let match = locations.first(where: { $0.id == current.id }) {
            selectedLocation = match
        } else {
            selectedLocation = locations.first
        }
        loadAlerts()
    }

    func select(_ location: SavedLocation) {
        selectedLocation = location
        lastResult = nil
        loadAlerts()
    }

    func loadAlerts() {
        guard let selectedLocation else {
            alerts = []
            return
        }
        let all = (try? container.alertRepository.fetch(ownerID: ownerID, locationID: selectedLocation.id)) ?? []
        alerts = all.filter { $0.kind == .geofence }
    }

    func simulate(forceHighRisk: Bool) async {
        guard let selectedLocation else { return }
        isSimulating = true
        lastResult = nil
        defer { isSimulating = false }

        let result = await container.geofenceManager.simulateEntry(
            for: selectedLocation,
            forceHighRisk: forceHighRisk && AppConfig.isDemoMode
        )
        lastResult = result
        loadAlerts()
        appState.refreshUnreadBadge()

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(result.level == .high ? .warning : .success)
    }

    func requestAuthorization() {
        if container.geofenceManager.authorizationStatus == .denied {
            container.locationService.openSettings()
        } else {
            container.geofenceManager.requestAuthorization()
        }
    }

    var authorizationDescription: String {
        container.geofenceManager.authorizationDescription
    }

    var isAlwaysAuthorized: Bool {
        container.geofenceManager.isAuthorizedForMonitoring
    }
}
