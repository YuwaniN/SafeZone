import Foundation

protocol WeatherProviding {
    func fetchWeather(for location: WeatherLocation) async throws -> WeatherSnapshot
}

final class OpenWeatherService: WeatherProviding {
    private let session: URLSession
    private let apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func fetchWeather(for location: WeatherLocation) async throws -> WeatherSnapshot {
        guard !apiKey.isEmpty else { throw WeatherError.missingAPIKey }

        async let current = fetchCurrent(for: location)
        async let forecast = fetchForecast(for: location)
        let currentResponse = try await current
        let forecastResponse = try await forecast

        let forecastPoints = forecastResponse.list.prefix(8).map { item in
            ForecastPoint(
                date: Date(timeIntervalSince1970: item.dt),
                temperatureC: item.main.temp,
                condition: WeatherCondition(openWeatherID: item.weather.first?.id ?? 800),
                rainfallMM: (item.rain?.threeHour ?? 0) / 3,
                precipitationChance: (item.pop ?? 0) * 100
            )
        }

        let currentRain: Double
        if let oneHour = currentResponse.rain?.oneHour {
            currentRain = oneHour
        } else if let threeHour = currentResponse.rain?.threeHour {
            currentRain = threeHour / 3
        } else {
            currentRain = 0
        }
        let dailyRain = forecastResponse.list.prefix(8).reduce(0) { partial, item in
            partial + (item.rain?.threeHour ?? 0)
        }
        let conditionID = currentResponse.weather.first?.id ?? 800
        let condition = WeatherCondition(openWeatherID: conditionID)
        let description = currentResponse.weather.first?.description.capitalized ?? condition.title

        return WeatherSnapshot(
            temperatureC: currentResponse.main.temp,
            feelsLikeC: currentResponse.main.feels_like,
            humidity: currentResponse.main.humidity,
            windKph: currentResponse.wind.speed * 3.6,
            rainfallMM: currentRain,
            dailyRainfallMM: dailyRain,
            condition: condition,
            conditionDescription: description,
            forecast: forecastPoints,
            updatedAt: Date(timeIntervalSince1970: currentResponse.dt),
            source: .live
        )
    }

    private func fetchCurrent(for location: WeatherLocation) async throws -> CurrentWeatherResponse {
        let url = try makeURL(
            path: "/data/2.5/weather",
            latitude: location.latitude,
            longitude: location.longitude
        )
        return try await decode(CurrentWeatherResponse.self, from: url)
    }

    private func fetchForecast(for location: WeatherLocation) async throws -> ForecastResponse {
        let url = try makeURL(
            path: "/data/2.5/forecast",
            latitude: location.latitude,
            longitude: location.longitude
        )
        return try await decode(ForecastResponse.self, from: url)
    }

    private func makeURL(path: String, latitude: Double, longitude: Double) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openweathermap.org"
        components.path = path
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        guard let url = components.url else { throw WeatherError.invalidResponse }
        return url
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw WeatherError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 401, 403: throw WeatherError.unauthorized
            case 429: throw WeatherError.rateLimited
            default: throw WeatherError.invalidResponse
            }
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw WeatherError.decoding
        }
    }
}

private struct CurrentWeatherResponse: Decodable {
    struct Main: Decodable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
    }

    struct Weather: Decodable {
        let id: Int
        let description: String
    }

    struct Wind: Decodable {
        let speed: Double
    }

    struct Rain: Decodable {
        let oneHour: Double?
        let threeHour: Double?

        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
            case threeHour = "3h"
        }
    }

    let main: Main
    let weather: [Weather]
    let wind: Wind
    let rain: Rain?
    let dt: TimeInterval
}

private struct ForecastResponse: Decodable {
    struct Item: Decodable {
        struct Main: Decodable {
            let temp: Double
        }

        struct Weather: Decodable {
            let id: Int
        }

        struct Wind: Decodable {
            let speed: Double
        }

        struct Rain: Decodable {
            let threeHour: Double?

            enum CodingKeys: String, CodingKey {
                case threeHour = "3h"
            }
        }

        let dt: TimeInterval
        let main: Main
        let weather: [Weather]
        let wind: Wind
        let rain: Rain?
        let pop: Double?
    }

    let list: [Item]
}
