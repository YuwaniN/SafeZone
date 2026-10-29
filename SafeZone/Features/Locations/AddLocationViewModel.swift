import CoreLocation
import Foundation
import MapKit

@MainActor
final class AddLocationViewModel: ObservableObject {
    @Published var name: String
    @Published var address: String
    @Published var radius: Double
    @Published var isMonitoring: Bool
    @Published var weatherAlerts: Bool
    @Published var riskLevelChanges: Bool
    @Published var emergencyAlerts: Bool
    @Published private(set) var latitude: Double
    @Published private(set) var longitude: Double
    @Published private(set) var isSaving = false
    @Published private(set) var isUsingCurrentLocation = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer
    private let appState: AppState
    private let ownerID: String
    private let existingLocation: SavedLocation?

    init(container: AppContainer, appState: AppState, existingLocation: SavedLocation?) {
        self.container = container
        self.appState = appState
        self.existingLocation = existingLocation
        ownerID = appState.profile?.id ?? AppConfig.demoUserID

        name = existingLocation?.name ?? ""
        address = existingLocation?.address ?? ""
        radius = existingLocation?.radius ?? 500
        isMonitoring = existingLocation?.isMonitoring ?? true
        weatherAlerts = existingLocation?.weatherAlerts ?? true
        riskLevelChanges = existingLocation?.riskLevelChanges ?? true
        emergencyAlerts = existingLocation?.emergencyAlerts ?? true
        latitude = existingLocation?.latitude ?? 6.9271
        longitude = existingLocation?.longitude ?? 79.8612
    }

    var isEditing: Bool { existingLocation != nil }

    var hasLocation: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasLocation && !isSaving
    }

    func applyMapItem(_ item: MKMapItem) {
        let placemark = item.placemark
        let parts = [placemark.name, placemark.thoroughfare, placemark.locality]
            .compactMap { $0 }
        let uniqueParts = parts.reduce(into: [String]()) { result, part in
            if !result.contains(part) { result.append(part) }
        }
        address = uniqueParts.joined(separator: ", ")
        latitude = placemark.coordinate.latitude
        longitude = placemark.coordinate.longitude
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = placemark.name ?? item.name ?? "Saved Location"
        }
        errorMessage = nil
    }

    func useCurrentLocation() async {
        isUsingCurrentLocation = true
        defer { isUsingCurrentLocation = false }

        guard let location = await container.locationService.requestLocation() else {
            errorMessage = "Location access is unavailable. Enable it in Settings or search for an address."
            return
        }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        if let place = await container.locationService.placeName(for: location) {
            address = place
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = "Current Location"
            }
        }
        errorMessage = nil
    }

    func save() async -> Bool {
        guard canSave else {
            errorMessage = "Add a name and choose an address or GPS location."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let existing = existingLocation
        let location = SavedLocation(
            id: existing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            isMonitoring: isMonitoring,
            weatherAlerts: weatherAlerts,
            riskLevelChanges: riskLevelChanges,
            emergencyAlerts: emergencyAlerts,
            monitoringStartedAt: isMonitoring
                ? (existing?.isMonitoring == true ? existing?.monitoringStartedAt ?? .now : .now)
                : existing?.monitoringStartedAt ?? .now,
            createdAt: existing?.createdAt ?? .now,
            sortIndex: existing?.sortIndex ?? nextSortIndex()
        )

        do {
            try container.savedLocationRepository.save(location, ownerID: ownerID)
            appState.syncGeofences()
            return true
        } catch {
            errorMessage = "The location could not be saved. Please try again."
            return false
        }
    }

    func delete() -> Bool {
        guard let existingLocation else { return false }
        do {
            try container.savedLocationRepository.delete(id: existingLocation.id)
            appState.syncGeofences()
            return true
        } catch {
            errorMessage = "The location could not be deleted."
            return false
        }
    }

    private func nextSortIndex() -> Int {
        let count = (try? container.savedLocationRepository.fetchAll(ownerID: ownerID).count) ?? 0
        return count
    }
}
