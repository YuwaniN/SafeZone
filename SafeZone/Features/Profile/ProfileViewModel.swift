import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var savedLocationCount = 0
    @Published private(set) var reportCount = 0
    @Published private(set) var monitoredLocationCount = 0
    @Published private(set) var isUpdatingBiometrics = false
    @Published var errorMessage: String?

    private let container: AppContainer
    private let appState: AppState

    init(container: AppContainer, appState: AppState) {
        self.container = container
        self.appState = appState
    }

    var profile: UserProfile? {
        appState.profile
    }

    var biometricAvailability: BiometricAvailability {
        container.biometricService.availability()
    }

    var isDemoMode: Bool {
        AppConfig.isDemoMode
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    func load() {
        guard let profile else {
            savedLocationCount = 0
            reportCount = 0
            monitoredLocationCount = 0
            return
        }
        let locations = (try? container.savedLocationRepository.fetchAll(ownerID: profile.id)) ?? []
        savedLocationCount = locations.count
        monitoredLocationCount = locations.filter(\.isMonitoring).count
        let reports = (try? container.incidentRepository.fetchAll()) ?? []
        reportCount = reports.filter(\.isMine).count
    }

    func setFaceIDEnabled(_ enabled: Bool) async {
        guard enabled else {
            appState.settings.faceIDEnabled = false
            return
        }

        isUpdatingBiometrics = true
        defer { isUpdatingBiometrics = false }

        let result = await container.biometricService.authenticate(
            reason: "Enable \(biometricAvailability.kind.rawValue) to protect SafeZone."
        )
        switch result {
        case .success:
            appState.settings.faceIDEnabled = true
            errorMessage = nil
        case .failure(let error):
            appState.settings.faceIDEnabled = false
            errorMessage = error.localizedDescription
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        guard enabled else {
            appState.settings.notificationsEnabled = false
            container.notificationService.clearBadge()
            return
        }

        let granted = await container.notificationService.requestAuthorization()
        appState.settings.notificationsEnabled = granted
        appState.settings.hasRequestedNotifications = true
        if !granted {
            errorMessage = "Notifications are disabled. Enable them in Settings to receive alerts."
        } else {
            errorMessage = nil
            appState.refreshUnreadBadge()
        }
    }

    func signOut() {
        appState.signOut()
    }

    func lockNow() {
        appState.lock()
    }
}
