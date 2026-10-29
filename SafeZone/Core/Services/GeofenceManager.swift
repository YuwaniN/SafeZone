import CoreLocation
import Foundation
import UIKit

struct GeofenceSimulationResult {
    let locationName: String
    let level: RiskLevel
    let message: String
    let didCreateAlert: Bool
}

@MainActor
final class GeofenceManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var monitoredLocationIDs: Set<UUID> = []
    @Published private(set) var isMonitoringAvailable = true

    private let manager = CLLocationManager()
    private let locationRepository: SavedLocationRepository
    private let weatherRepository: WeatherRepository
    private let notificationService: NotificationService
    private let alertRepository: AlertRepository
    private let alertCenter: AlertCenter
    private let settings: AppSettings

    private var ownerID: String?
    private var locationsByID: [UUID: SavedLocation] = [:]

    private static let regionPrefix = "safezone."
    private static let maxRegions = 20

    init(
        locationRepository: SavedLocationRepository,
        weatherRepository: WeatherRepository,
        notificationService: NotificationService,
        alertRepository: AlertRepository,
        alertCenter: AlertCenter,
        settings: AppSettings
    ) {
        self.locationRepository = locationRepository
        self.weatherRepository = weatherRepository
        self.notificationService = notificationService
        self.alertRepository = alertRepository
        self.alertCenter = alertCenter
        self.settings = settings
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
        isMonitoringAvailable = CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }

    var isAuthorizedForMonitoring: Bool {
        authorizationStatus == .authorizedAlways
    }

    var authorizationDescription: String {
        switch authorizationStatus {
        case .authorizedAlways: return "Always allowed"
        case .authorizedWhenInUse: return "While using the app – choose Always for background alerts"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    func requestAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func start(ownerID: String, locations: [SavedLocation]) {
        self.ownerID = ownerID
        locationsByID = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
        if authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
        syncRegions(with: locations)
    }

    func syncRegions(with locations: [SavedLocation]) {
        locationsByID = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })

        for region in manager.monitoredRegions where region.identifier.hasPrefix(Self.regionPrefix) {
            manager.stopMonitoring(for: region)
        }

        let monitorable = locations
            .filter(\.isMonitoring)
            .sorted { $0.sortIndex < $1.sortIndex }
            .prefix(Self.maxRegions)

        var ids: Set<UUID> = []
        for location in monitorable {
            guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { continue }
            let radius = min(max(location.radius, 100), 2_000)
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                radius: radius,
                identifier: Self.regionPrefix + location.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            manager.startMonitoring(for: region)
            ids.insert(location.id)
        }
        monitoredLocationIDs = ids
    }

    func stopAll() {
        for region in manager.monitoredRegions where region.identifier.hasPrefix(Self.regionPrefix) {
            manager.stopMonitoring(for: region)
        }
        monitoredLocationIDs = []
        ownerID = nil
        locationsByID = [:]
    }

    func simulateEntry(for location: SavedLocation, forceHighRisk: Bool = false) async -> GeofenceSimulationResult {
        let weatherLocation = location.weatherLocation
        let level: RiskLevel
        let message: String

        if forceHighRisk {
            let (weather, assessment) = weatherRepository.highRiskAssessment(for: weatherLocation)
            level = assessment.level
            message = "You have entered a high-risk flood zone near \(location.name). Water levels in this area may exceed the danger threshold. Immediate precaution is recommended."
            _ = weather
        } else {
            let result = await weatherRepository.load(for: weatherLocation)
            guard let assessment = result.assessment else {
                return GeofenceSimulationResult(
                    locationName: location.name,
                    level: .low,
                    message: "Risk could not be evaluated. Check your connection and try again.",
                    didCreateAlert: false
                )
            }
            level = assessment.level
            message = level == .high
                ? "You have entered a high-risk weather zone near \(location.name). Review official warnings and be ready to act."
                : "You entered the monitored zone around \(location.name). Current weather risk is \(level.title)."
        }

        let alert = AlertRecord(
            title: level == .high ? "High Risk Zone Alert" : "\(level.title) Zone Alert",
            message: message,
            level: level,
            locationName: location.name,
            locationID: location.id,
            kind: .geofence
        )

        let didCreateAlert = level >= .medium
        if didCreateAlert {
            try? alertRepository.create(alert, ownerID: ownerID ?? AppConfig.demoUserID)
            presentAlertIfNeeded(alert)
        }

        return GeofenceSimulationResult(
            locationName: location.name,
            level: level,
            message: message,
            didCreateAlert: didCreateAlert
        )
    }

    private func processEntry(for location: SavedLocation) async {
        guard location.emergencyAlerts, settings.emergencyAlerts, settings.notificationsEnabled else { return }
        let result = await weatherRepository.load(for: location.weatherLocation)
        guard let assessment = result.assessment, assessment.level >= .medium else { return }

        let message = "You entered the monitored zone around \(location.name). Current weather risk is \(assessment.level.title)."
        let alert = AlertRecord(
            title: assessment.level == .high ? "High Risk Zone Alert" : "\(assessment.level.title) Zone Alert",
            message: message,
            level: assessment.level,
            locationName: location.name,
            locationID: location.id,
            kind: .geofence
        )
        try? alertRepository.create(alert, ownerID: ownerID ?? AppConfig.demoUserID)
        presentAlertIfNeeded(alert)
    }

    private func presentAlertIfNeeded(_ alert: AlertRecord) {
        let banner = AlertBanner(
            title: alert.title,
            message: alert.message,
            level: alert.level,
            locationName: alert.locationName,
            locationID: alert.locationID
        )

        if UIApplication.shared.applicationState == .active {
            alertCenter.present(banner)
        } else {
            notificationService.scheduleGeofenceAlert(
                title: alert.title,
                body: alert.message,
                level: alert.level,
                locationID: alert.locationID ?? UUID()
            )
        }
    }
}

extension GeofenceManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier.hasPrefix(Self.regionPrefix),
              let id = UUID(uuidString: String(region.identifier.dropFirst(Self.regionPrefix.count))) else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self,
                  let location = self.locationsByID[id] ?? (try? self.locationRepository.fetch(id: id)) else {
                return
            }
            await self.processEntry(for: location)
        }
    }
}
