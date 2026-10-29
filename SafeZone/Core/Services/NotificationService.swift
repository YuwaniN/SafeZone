import Foundation
import UIKit
import UserNotifications

extension Notification.Name {
    static let safeZoneNotificationTapped = Notification.Name("safeZoneNotificationTapped")
}

@MainActor
final class NotificationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        Task { await refreshAuthorizationStatus() }
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func scheduleRiskAlert(
        title: String,
        body: String,
        level: RiskLevel,
        locationID: UUID?,
        timeInterval: TimeInterval = 1
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "SAFEZONE_RISK"
        content.userInfo = [
            "level": level.rawValue,
            "locationID": locationID?.uuidString ?? ""
        ]
        content.interruptionLevel = level == .high ? .timeSensitive : .active

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(timeInterval, 1),
            repeats: false
        )
        let identifier = "safezone.risk.\(locationID?.uuidString ?? UUID().uuidString).\(Int(Date().timeIntervalSince1970))"
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func scheduleGeofenceAlert(
        title: String,
        body: String,
        level: RiskLevel,
        locationID: UUID
    ) {
        scheduleRiskAlert(
            title: title,
            body: body,
            level: level,
            locationID: locationID,
            timeInterval: 1
        )
    }

    func scheduleTestNotification() {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "SafeZone Test Alert"
        content.body = "Notifications are working. You'll be alerted when risk changes at your saved locations."
        content.sound = .default
        content.interruptionLevel = .active
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        center.add(UNNotificationRequest(identifier: "safezone.test.\(UUID().uuidString)", content: content, trigger: trigger))
    }

    func updateBadge(count: Int) {
        Task {
            try? await center.setBadgeCount(max(count, 0))
        }
    }

    func clearBadge() {
        updateBadge(count: 0)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        NotificationCenter.default.post(
            name: .safeZoneNotificationTapped,
            object: response.notification.request.content.userInfo
        )
    }
}
