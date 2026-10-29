import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Flow: Equatable {
        case onboarding
        case biometricSetup
        case authentication
        case locked
        case main
    }

    @Published private(set) var flow: Flow = .onboarding
    @Published private(set) var profile: UserProfile?
    @Published var selectedTab: AppTab = .home
    @Published private(set) var unreadAlertCount = 0

    let container: AppContainer
    let settings: AppSettings

    private var hasBootstrapped = false

    init(container: AppContainer) {
        self.container = container
        settings = container.settings

        #if DEBUG
        if let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--tab=") }),
           let tab = AppTab(rawValue: String(argument.dropFirst("--tab=".count))) {
            selectedTab = tab
        }
        #endif
    }

    var isAuthenticated: Bool {
        profile != nil
    }

    var isDemoMode: Bool {
        AppConfig.isDemoMode
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true

        await container.notificationService.refreshAuthorizationStatus()

        if !settings.hasCompletedOnboarding {
            flow = .onboarding
            return
        }

        if let profile = container.authService.restoreSession() {
            self.profile = profile
            startGeofencing()
            refreshUnreadBadge()
            flow = settings.faceIDEnabled ? .locked : .main
        } else {
            flow = .authentication
        }
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        if container.biometricService.availability().isAvailable && !settings.hasPromptedFaceID {
            flow = .biometricSetup
        } else if container.authService.restoreSession() != nil {
            profile = container.authService.currentUser
            startGeofencing()
            flow = .main
        } else {
            flow = .authentication
        }
    }

    func finishBiometricSetup(enabled: Bool) {
        settings.hasPromptedFaceID = true
        settings.faceIDEnabled = enabled
        if profile != nil || container.authService.currentUser != nil {
            profile = container.authService.currentUser
            startGeofencing()
            flow = .main
        } else {
            flow = .authentication
        }
    }

    func signIn(email: String, password: String) async throws {
        let profile = try await container.authService.login(email: email, password: password)
        self.profile = profile
        startGeofencing()
        refreshUnreadBadge()

        if container.biometricService.availability().isAvailable && !settings.hasPromptedFaceID {
            flow = .biometricSetup
        } else {
            flow = .main
        }
        Task { await requestNotificationPermissionIfNeeded() }
    }

    func register(
        name: String,
        email: String,
        password: String,
        emergencyContactName: String?,
        emergencyContactPhone: String?
    ) async throws {
        let profile = try await container.authService.register(
            name: name,
            email: email,
            password: password,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone
        )
        self.profile = profile
        startGeofencing()
        refreshUnreadBadge()

        if container.biometricService.availability().isAvailable && !settings.hasPromptedFaceID {
            flow = .biometricSetup
        } else {
            flow = .main
        }
        Task { await requestNotificationPermissionIfNeeded() }
    }

    func updateProfile(_ profile: UserProfile) async throws {
        let updated = try await container.authService.updateProfile(profile)
        self.profile = updated
    }

    func signOut() {
        container.authService.logout()
        container.geofenceManager.stopAll()
        container.alertCenter.dismiss()
        container.notificationService.clearBadge()
        settings.resetSessionPreferences()
        profile = nil
        unreadAlertCount = 0
        selectedTab = .home
        flow = .authentication
    }

    func lock() {
        guard profile != nil, settings.faceIDEnabled else { return }
        flow = .locked
    }

    func unlock() {
        flow = .main
    }

    func startGeofencing() {
        guard let profile else { return }
        do {
            let locations = try container.savedLocationRepository.fetchAll(ownerID: profile.id)
            container.geofenceManager.start(ownerID: profile.id, locations: locations)
        } catch {
            assertionFailure("Failed to load locations for geofencing: \(error)")
        }
    }

    func syncGeofences() {
        startGeofencing()
    }

    func refreshUnreadBadge() {
        guard let profile else {
            unreadAlertCount = 0
            container.notificationService.clearBadge()
            return
        }
        let count = (try? container.alertRepository.unreadCount(ownerID: profile.id)) ?? 0
        unreadAlertCount = count
        container.notificationService.updateBadge(count: count)
    }

    func markAlertsRead() {
        guard let profile else { return }
        try? container.alertRepository.markAllRead(ownerID: profile.id)
        refreshUnreadBadge()
    }

    func requestNotificationPermissionIfNeeded() async {
        guard settings.notificationsEnabled, !settings.hasRequestedNotifications else { return }
        settings.hasRequestedNotifications = true
        let granted = await container.notificationService.requestAuthorization()
        if !granted {
            settings.notificationsEnabled = false
        }
    }

    func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        selectedTab = .home
        _ = userInfo
    }

    func openTab(_ tab: AppTab) {
        selectedTab = tab
    }
}
