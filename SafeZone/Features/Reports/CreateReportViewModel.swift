import CoreLocation
import Foundation
import UIKit

@MainActor
final class CreateReportViewModel: ObservableObject {
    @Published var category: IncidentCategory = .floodedRoad
    @Published var title = ""
    @Published var details = ""
    @Published var address = ""
    @Published var photoData: Data?
    @Published private(set) var latitude: Double?
    @Published private(set) var longitude: Double?
    @Published private(set) var isResolvingLocation = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var usingFallbackLocation = false
    @Published private(set) var isLocationDenied = false
    @Published var errorMessage: String?

    private let container: AppContainer
    private let appState: AppState
    private let ownerID: String

    init(container: AppContainer, appState: AppState) {
        self.container = container
        self.appState = appState
        ownerID = appState.profile?.id ?? AppConfig.demoUserID
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        coordinate != nil &&
        !isSubmitting
    }

    var authorName: String {
        appState.profile?.displayName ?? "SafeZone User"
    }

    func prepare() async {
        guard coordinate == nil else { return }
        await resolveLocation()
    }

    func useCurrentLocation() async {
        errorMessage = nil
        await resolveLocation(forceCurrent: true)
    }

    func openSettings() {
        container.locationService.openSettings()
    }

    func submit() async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedTitle.count >= 4 else {
            errorMessage = ReportError.invalidTitle.localizedDescription
            return false
        }
        guard trimmedDetails.count >= 10 else {
            errorMessage = ReportError.invalidDescription.localizedDescription
            return false
        }
        guard let latitude, let longitude else {
            errorMessage = ReportError.missingLocation.localizedDescription
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let report = IncidentReport(
            category: category,
            title: trimmedTitle,
            details: trimmedDetails,
            latitude: latitude,
            longitude: longitude,
            address: address.isEmpty ? "Pinned location" : address,
            authorName: authorName,
            createdAt: .now,
            upvotes: 0,
            isVerified: false,
            isFlagged: false,
            isMine: true,
            photoData: photoData
        )

        do {
            try container.incidentRepository.create(report, ownerID: ownerID)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            errorMessage = nil
            return true
        } catch {
            errorMessage = ReportError.saveFailed.localizedDescription
            return false
        }
    }

    private func resolveLocation(forceCurrent: Bool = false) async {
        isResolvingLocation = true
        defer { isResolvingLocation = false }

        if forceCurrent || !usingFallbackLocation {
            if let location = await container.locationService.requestLocation() {
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
                address = await container.locationService.placeName(for: location) ?? "Pinned location"
                usingFallbackLocation = false
                isLocationDenied = false
                return
            }
        }

        let saved = (try? container.savedLocationRepository.fetchAll(ownerID: ownerID)) ?? []
        if let home = saved.first {
            latitude = home.latitude
            longitude = home.longitude
            address = home.address
            usingFallbackLocation = true
        } else {
            latitude = 6.9271
            longitude = 79.8612
            address = "Colombo, Sri Lanka"
            usingFallbackLocation = true
        }
        isLocationDenied = container.locationService.isDenied
        if forceCurrent {
            errorMessage = "Current location is unavailable. Using your saved Home location instead."
        }
    }
}
