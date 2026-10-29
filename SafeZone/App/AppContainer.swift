import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let persistence: PersistenceController
    let settings: AppSettings
    let authService: AuthService
    let savedLocationRepository: SavedLocationRepository
    let incidentRepository: IncidentRepository
    let alertRepository: AlertRepository
    let riskSnapshotRepository: RiskSnapshotRepository
    let weatherRepository: WeatherRepository
    let notificationService: NotificationService
    let biometricService: BiometricService
    let locationService: LocationService
    let geofenceManager: GeofenceManager
    let alertCenter: AlertCenter
    let emergencyServices: EmergencyServicesService
    let guideRepository: GuideRepository
    let networkMonitor: NetworkMonitor

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        settings = AppSettings()
        authService = LocalAuthService(persistence: persistence)
        savedLocationRepository = CoreDataSavedLocationRepository(persistence: persistence)
        incidentRepository = CoreDataIncidentRepository(persistence: persistence)
        alertRepository = CoreDataAlertRepository(persistence: persistence)
        riskSnapshotRepository = CoreDataRiskSnapshotRepository(persistence: persistence)

        let provider: WeatherProviding = AppConfig.isLiveWeatherEnabled
            ? OpenWeatherService(apiKey: AppConfig.openWeatherAPIKey)
            : DemoWeatherService()
        weatherRepository = WeatherRepository(provider: provider, snapshots: riskSnapshotRepository)

        notificationService = NotificationService()
        biometricService = BiometricService()
        locationService = LocationService()
        alertCenter = AlertCenter()
        geofenceManager = GeofenceManager(
            locationRepository: savedLocationRepository,
            weatherRepository: weatherRepository,
            notificationService: notificationService,
            alertRepository: alertRepository,
            alertCenter: alertCenter,
            settings: settings
        )
        emergencyServices = EmergencyServicesService()
        guideRepository = GuideRepository()
        networkMonitor = NetworkMonitor()
    }

    var guideContent: GuideContent {
        guideRepository.loadGuide()
    }
}
