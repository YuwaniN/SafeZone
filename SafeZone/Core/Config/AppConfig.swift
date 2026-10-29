import Foundation

enum AppConfig {
    static let appName = "SafeZone"
    static let demoEmail = "demo@safezone.lk"
    static let demoPassword = "SafeZone123"
    static let demoUserID = "11111111-1111-1111-1111-111111111111"
    static let supportEmail = "support@safezone.lk"

    static var openWeatherAPIKey: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String else {
            return ""
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.contains("$(") || trimmed.lowercased().contains("your_openweathermap") {
            return ""
        }
        return trimmed
    }

    static var isLiveWeatherEnabled: Bool {
        !openWeatherAPIKey.isEmpty
    }

    static var isFirebaseConfigured: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    static var isDemoMode: Bool {
        !isLiveWeatherEnabled
    }

    static let weatherAttributionURL = URL(string: "https://openweathermap.org/")!
    static let dataDisclaimer = "SafeZone risk scores are indicative weather assessments, not official flood predictions or evacuation warnings. Always follow guidance from the Disaster Management Centre and local authorities."
}
