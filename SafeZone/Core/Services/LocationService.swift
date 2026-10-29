import CoreLocation
import Foundation
import UIKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var isRequestingLocation = false

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var authorizationDescription: String {
        switch authorizationStatus {
        case .authorizedAlways: return "Always allowed"
        case .authorizedWhenInUse: return "While using the app"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    func requestWhenInUseAuthorization() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation(timeout: TimeInterval = 12) async -> CLLocation? {
        if let currentLocation, currentLocation.timestamp.timeIntervalSinceNow > -120 {
            return currentLocation
        }
        guard CLLocationManager.locationServicesEnabled(), !isDenied else { return nil }

        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try? await Task.sleep(for: .seconds(1))
            guard authorizationStatus != .notDetermined, !isDenied else { return nil }
        }

        guard isAuthorized else { return nil }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            isRequestingLocation = true
            manager.requestLocation()

            timeoutTask?.cancel()
            timeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(timeout))
                guard !Task.isCancelled else { return }
                self?.resume(with: nil)
            }
        }
    }

    func placeName(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return nil
        }
        let locality = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.name
        let country = placemark.country
        switch (locality, country) {
        case let (locality?, country?):
            return "\(locality), \(country)"
        case let (locality?, nil):
            return locality
        case let (nil, country?):
            return country
        default:
            return nil
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func resume(with location: CLLocation?) {
        guard let continuation else { return }
        self.continuation = nil
        isRequestingLocation = false
        timeoutTask?.cancel()
        timeoutTask = nil
        if let location {
            currentLocation = location
        }
        continuation.resume(returning: location)
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = manager.authorizationStatus
            if self.isAuthorized, self.continuation != nil {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            self?.resume(with: locations.last)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.resume(with: nil)
        }
    }
}
