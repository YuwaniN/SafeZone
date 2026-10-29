import CoreLocation
import Foundation
import MapKit

final class EmergencyServicesService {
    func services(
        near center: CLLocationCoordinate2D,
        category: EmergencyServiceCategory
    ) async -> [EmergencyService] {
        let searchResults = await searchMapItems(center: center, query: category.searchQuery)
        var services = searchResults.map { item in
            makeService(from: item, category: category, center: center)
        }

        if category == .shelter {
            services.append(contentsOf: EmergencyService.fallbackServices
                .filter { $0.category == .shelter }
                .map { withDistance($0, center: center) })
        }

        if services.isEmpty {
            services = EmergencyService.fallbackServices
                .filter { $0.category == category }
                .map { withDistance($0, center: center) }
        }

        return deduplicated(services).sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
    }

    func allServices(near center: CLLocationCoordinate2D) async -> [EmergencyService] {
        var all: [EmergencyService] = []
        for category in EmergencyServiceCategory.allCases {
            all.append(contentsOf: await services(near: center, category: category))
        }
        return deduplicated(all).sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
    }

    private func searchMapItems(center: CLLocationCoordinate2D, query: String) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: 18_000,
            longitudinalMeters: 18_000
        )
        request.resultTypes = [.pointOfInterest]

        let search = MKLocalSearch(request: request)
        return await withCheckedContinuation { continuation in
            search.start { response, _ in
                continuation.resume(returning: response?.mapItems ?? [])
            }
        }
    }

    private func makeService(
        from item: MKMapItem,
        category: EmergencyServiceCategory,
        center: CLLocationCoordinate2D
    ) -> EmergencyService {
        let placemark = item.placemark
        let addressParts = [
            placemark.thoroughfare,
            placemark.locality
        ].compactMap { $0 }
        let address = addressParts.isEmpty ? (item.name ?? category.singularTitle) : addressParts.joined(separator: ", ")
        let location = CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return EmergencyService(
            name: item.name ?? category.singularTitle,
            category: category,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            address: address,
            phoneNumber: item.phoneNumber,
            distanceMeters: location.distance(from: centerLocation)
        )
    }

    private func withDistance(_ service: EmergencyService, center: CLLocationCoordinate2D) -> EmergencyService {
        let location = CLLocation(latitude: service.latitude, longitude: service.longitude)
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return EmergencyService(
            id: service.id,
            name: service.name,
            category: service.category,
            latitude: service.latitude,
            longitude: service.longitude,
            address: service.address,
            phoneNumber: service.phoneNumber,
            distanceMeters: location.distance(from: centerLocation),
            isOpen: service.isOpen
        )
    }

    private func deduplicated(_ services: [EmergencyService]) -> [EmergencyService] {
        var seen: Set<String> = []
        return services.filter { service in
            let key = service.name.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}
