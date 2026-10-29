import Foundation

@MainActor
final class AppSettings: ObservableObject {
    enum Key {
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let hasPromptedFaceID = "settings.hasPromptedFaceID"
        static let faceIDEnabled = "settings.faceIDEnabled"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let weatherAlerts = "settings.weatherAlerts"
        static let riskLevelAlerts = "settings.riskLevelAlerts"
        static let emergencyAlerts = "settings.emergencyAlerts"
        static let selectedLocationID = "settings.selectedLocationID"
        static let hasRequestedNotifications = "settings.hasRequestedNotifications"
        static let lastBackgroundDate = "settings.lastBackgroundDate"
    }

    private let defaults: UserDefaults

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }

    @Published var hasPromptedFaceID: Bool {
        didSet { defaults.set(hasPromptedFaceID, forKey: Key.hasPromptedFaceID) }
    }

    @Published var faceIDEnabled: Bool {
        didSet { defaults.set(faceIDEnabled, forKey: Key.faceIDEnabled) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled) }
    }

    @Published var weatherAlerts: Bool {
        didSet { defaults.set(weatherAlerts, forKey: Key.weatherAlerts) }
    }

    @Published var riskLevelAlerts: Bool {
        didSet { defaults.set(riskLevelAlerts, forKey: Key.riskLevelAlerts) }
    }

    @Published var emergencyAlerts: Bool {
        didSet { defaults.set(emergencyAlerts, forKey: Key.emergencyAlerts) }
    }

    @Published var hasRequestedNotifications: Bool {
        didSet { defaults.set(hasRequestedNotifications, forKey: Key.hasRequestedNotifications) }
    }

    @Published var selectedLocationID: String? {
        didSet { defaults.set(selectedLocationID, forKey: Key.selectedLocationID) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        hasPromptedFaceID = defaults.bool(forKey: Key.hasPromptedFaceID)
        faceIDEnabled = defaults.bool(forKey: Key.faceIDEnabled)
        notificationsEnabled = defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        weatherAlerts = defaults.object(forKey: Key.weatherAlerts) as? Bool ?? true
        riskLevelAlerts = defaults.object(forKey: Key.riskLevelAlerts) as? Bool ?? true
        emergencyAlerts = defaults.object(forKey: Key.emergencyAlerts) as? Bool ?? true
        hasRequestedNotifications = defaults.bool(forKey: Key.hasRequestedNotifications)
        selectedLocationID = defaults.string(forKey: Key.selectedLocationID)
    }

    func markBackgrounded(at date: Date = .now) {
        defaults.set(date, forKey: Key.lastBackgroundDate)
    }

    var lastBackgroundDate: Date? {
        defaults.object(forKey: Key.lastBackgroundDate) as? Date
    }

    func resetSessionPreferences() {
        faceIDEnabled = false
        selectedLocationID = nil
    }
}
