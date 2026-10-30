import CoreLocation
import Foundation
import MapKit
import SwiftUI

@MainActor
final class EmergencyMapViewModel: ObservableObject {
    @Published private(set) var services: [EmergencyService] = []
    @Published private(set) var incidents: [IncidentReport] = []
    @Published private(set) var savedLocations: [SavedLocation] = []
    @Published private(set) var savedRisks: [UUID: RiskLevel] = [:]
    @Published var filter: MapFilter = .all {
        didSet { clearSelectionIfNeeded() }
    }
    @Published var searchText = ""
    @Published var selectedService: EmergencyService?
    @Published var selectedIncident: IncidentReport?
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @Published private(set) var center = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
    @Published private(set) var centerName = "Colombo, Sri Lanka"
    @Published private(set) var isLoading = false
    @Published private(set) var isLocating = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLocationDenied = false

    private let container: AppContainer
    private let appState: AppState
    private let ownerID: String
    private var hasLoaded = false

    init(container: AppContainer, appState: AppState) {
        self.container = container
        self.appState = appState
        ownerID = appState.profile?.id ?? AppConfig.demoUserID
    }

    var visibleServices: [EmergencyService] {
        var items = services
        if let category = filter.serviceCategory {
            items = items.filter { $0.category == category }
        } else if filter == .incidents {
            return []
        }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.name.lowercased().contains(query) ||
                $0.address.lowercased().contains(query) ||
                $0.category.title.lowercased().contains(query)
            }
        }
        return items.sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
    }

    var visibleIncidents: [IncidentReport] {
        guard filter == .all || filter == .incidents else { return [] }
        var items = incidents
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(query) ||
                $0.address.lowercased().contains(query) ||
                $0.category.title.lowercased().contains(query)
            }
        }
        return items.sorted { distance(for: $0) < distance(for: $1) }
    }

    var mapServices: [EmergencyService] {
        let limit = filter == .all ? 16 : 24
        return Array(visibleServices.prefix(limit))
    }

    var savedLocationCount: Int {
        savedLocations.filter(\.isMonitoring).count
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true
        loadIncidents()
        loadSavedLocations()
        await resolveCenter()
        await loadServices()
        isLoading = false
        Task { await loadSavedRisks() }
    }

    func refresh() async {
        isLoading = true
        loadIncidents()
        loadSavedLocations()
        await loadServices()
        isLoading = false
        Task { await loadSavedRisks() }
    }

    private func loadIncidents() {
        incidents = (try? container.incidentRepository.fetchAll()) ?? []
    }

    private func loadSavedLocations() {
        savedLocations = (try? container.savedLocationRepository.fetchAll(ownerID: ownerID)) ?? []
    }

    private func resolveCenter() async {
        isLocating = true
        defer { isLocating = false }

        if let location = await container.locationService.requestLocation() {
            center = location.coordinate
            isLocationDenied = false
            centerName = await container.locationService.placeName(for: location) ?? "Current Location"
        } else if let home = savedLocations.first {
            center = CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)
            centerName = home.address
            isLocationDenied = container.locationService.isDenied
        } else {
            isLocationDenied = container.locationService.isDenied
        }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
        )
    }

    private func loadServices() async {
        services = await container.emergencyServices.allServices(near: center)
        if services.isEmpty {
            errorMessage = "Nearby services could not be loaded. Check your connection."
        } else {
            errorMessage = nil
        }
    }

    private func loadSavedRisks() async {
        for location in savedLocations {
            let result = await container.weatherRepository.load(for: location.weatherLocation)
            if let level = result.assessment?.level {
                savedRisks[location.id] = level
            }
        }
    }

    func select(_ service: EmergencyService) {
        selectedService = service
        selectedIncident = nil
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: service.latitude, longitude: service.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        )
    }

    func select(_ incident: IncidentReport) {
        selectedIncident = incident
        selectedService = nil
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: incident.latitude, longitude: incident.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    func clearSelection() {
        selectedService = nil
        selectedIncident = nil
    }

    func recenter() {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
        )
    }

    func recenterToUser() async {
        isLocating = true
        defer { isLocating = false }
        guard let location = await container.locationService.requestLocation() else {
            isLocationDenied = container.locationService.isDenied
            return
        }
        center = location.coordinate
        centerName = await container.locationService.placeName(for: location) ?? "Current Location"
        isLocationDenied = false
        recenter()
        await loadServices()
    }

    func openSettings() {
        container.locationService.openSettings()
    }

    func distance(for incident: IncidentReport) -> Double {
        let incidentLocation = CLLocation(latitude: incident.latitude, longitude: incident.longitude)
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return incidentLocation.distance(from: centerLocation)
    }

    func risk(for location: SavedLocation) -> RiskLevel {
        savedRisks[location.id] ?? .low
    }

    private func clearSelectionIfNeeded() {
        if filter == .incidents {
            selectedService = nil
        } else {
            selectedIncident = nil
        }
    }
}
