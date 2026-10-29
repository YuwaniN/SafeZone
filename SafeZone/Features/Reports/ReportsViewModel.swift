import CoreLocation
import Foundation

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published private(set) var reports: [IncidentReport] = []
    @Published var filter: IncidentFilter = .all
    @Published var searchText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer
    private let appState: AppState
    private let ownerID: String
    private var referenceCoordinate = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)

    init(container: AppContainer, appState: AppState) {
        self.container = container
        self.appState = appState
        ownerID = appState.profile?.id ?? AppConfig.demoUserID
    }

    var filteredReports: [IncidentReport] {
        var items = reports

        switch filter {
        case .all:
            break
        case .nearby:
            items = items
                .filter { distance(for: $0) <= 30_000 }
                .sorted { distance(for: $0) < distance(for: $1) }
        case .verified:
            items = items.filter(\.isVerified)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            items = items.filter {
                $0.title.lowercased().contains(query) ||
                $0.details.lowercased().contains(query) ||
                $0.address.lowercased().contains(query) ||
                $0.category.title.lowercased().contains(query)
            }
        }

        if filter != .nearby {
            items.sort { $0.createdAt > $1.createdAt }
        }
        return items
    }

    var verifiedCount: Int {
        reports.filter(\.isVerified).count
    }

    var nearbyCount: Int {
        reports.filter { distance(for: $0) <= 30_000 }.count
    }

    func load() async {
        isLoading = reports.isEmpty
        defer { isLoading = false }

        if let home = try? container.savedLocationRepository.fetchAll(ownerID: ownerID).first {
            referenceCoordinate = CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)
        }

        do {
            reports = try container.incidentRepository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "Community reports could not be loaded."
        }
    }

    func distance(for report: IncidentReport) -> Double {
        let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
        let reference = CLLocation(latitude: referenceCoordinate.latitude, longitude: referenceCoordinate.longitude)
        return reportLocation.distance(from: reference)
    }
}
