import Foundation

enum WeatherCondition: String, Codable, CaseIterable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case heavyRain
    case thunderstorm
    case mist
    case unknown

    var title: String {
        switch self {
        case .clear: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .rain: return "Rain"
        case .heavyRain: return "Heavy Rain"
        case .thunderstorm: return "Thunderstorm"
        case .mist: return "Mist"
        case .unknown: return "Unknown"
        }
    }

    var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .mist: return "cloud.fog.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var isSevere: Bool {
        self == .heavyRain || self == .thunderstorm
    }

    init(openWeatherID: Int) {
        switch openWeatherID {
        case 200...232: self = .thunderstorm
        case 300...321, 500...501: self = .rain
        case 502...531: self = .heavyRain
        case 600...622: self = .rain
        case 701...781: self = .mist
        case 800: self = .clear
        case 801, 802: self = .partlyCloudy
        case 803, 804: self = .cloudy
        default: self = .unknown
        }
    }
}

struct ForecastPoint: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let date: Date
    let temperatureC: Double
    let condition: WeatherCondition
    let rainfallMM: Double
    let precipitationChance: Double

    init(
        id: UUID = UUID(),
        date: Date,
        temperatureC: Double,
        condition: WeatherCondition,
        rainfallMM: Double,
        precipitationChance: Double
    ) {
        self.id = id
        self.date = date
        self.temperatureC = temperatureC
        self.condition = condition
        self.rainfallMM = rainfallMM
        self.precipitationChance = precipitationChance
    }
}

struct WeatherSnapshot: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let temperatureC: Double
    let feelsLikeC: Double
    let humidity: Int
    let windKph: Double
    let rainfallMM: Double
    let dailyRainfallMM: Double
    let condition: WeatherCondition
    let conditionDescription: String
    let forecast: [ForecastPoint]
    let updatedAt: Date
    let source: Source

    enum Source: String, Codable, Sendable {
        case live
        case demo
        case cached
    }

    init(
        id: UUID = UUID(),
        temperatureC: Double,
        feelsLikeC: Double,
        humidity: Int,
        windKph: Double,
        rainfallMM: Double,
        dailyRainfallMM: Double,
        condition: WeatherCondition,
        conditionDescription: String,
        forecast: [ForecastPoint],
        updatedAt: Date = .now,
        source: Source = .live
    ) {
        self.id = id
        self.temperatureC = temperatureC
        self.feelsLikeC = feelsLikeC
        self.humidity = humidity
        self.windKph = windKph
        self.rainfallMM = rainfallMM
        self.dailyRainfallMM = dailyRainfallMM
        self.condition = condition
        self.conditionDescription = conditionDescription
        self.forecast = forecast
        self.updatedAt = updatedAt
        self.source = source
    }

    var temperatureDisplay: String {
        "\(Int(temperatureC.rounded()))°"
    }

    var rainfallDisplay: String {
        String(format: "%.1f mm", dailyRainfallMM)
    }

    var windDisplay: String {
        "\(Int(windKph.rounded())) km/h"
    }

    var humidityDisplay: String {
        "\(humidity)%"
    }

    var peakForecastRainfall: Double {
        forecast.prefix(4).map(\.rainfallMM).max() ?? rainfallMM
    }
}

struct WeatherLocation: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let savedLocationID: UUID?

    init(
        id: String,
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        savedLocationID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.savedLocationID = savedLocationID
    }

    init(savedLocation: SavedLocation) {
        self.init(
            id: savedLocation.id.uuidString,
            name: savedLocation.name,
            address: savedLocation.address,
            latitude: savedLocation.latitude,
            longitude: savedLocation.longitude,
            savedLocationID: savedLocation.id
        )
    }

    static let colombo = WeatherLocation(
        id: "colombo-default",
        name: "Colombo, Sri Lanka",
        address: "Colombo, Western Province",
        latitude: 6.9271,
        longitude: 79.8612
    )
}

enum WeatherError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case unauthorized
    case rateLimited
    case network(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an OpenWeatherMap API key to see live weather. Showing demo data instead."
        case .invalidResponse:
            return "The weather service returned an unexpected response."
        case .unauthorized:
            return "The weather API key was rejected. Check Config/Secrets.xcconfig."
        case .rateLimited:
            return "The weather service is busy. Please try again shortly."
        case .network(let message):
            return message
        case .decoding:
            return "Weather data could not be read."
        }
    }
}
