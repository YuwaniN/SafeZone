import Foundation

final class DemoWeatherService: WeatherProviding {
    func fetchWeather(for location: WeatherLocation) async throws -> WeatherSnapshot {
        try? await Task.sleep(for: .milliseconds(450))
        return snapshot(for: location)
    }

    func snapshot(for location: WeatherLocation) -> WeatherSnapshot {
        let key = "\(location.name) \(location.address)".lowercased()

        if key.contains("kolonnawa") {
            return makeSnapshot(
                location: location,
                temperature: 27,
                feelsLike: 31,
                humidity: 91,
                wind: 48,
                rainfall: 14.2,
                dailyRainfall: 96.4,
                condition: .heavyRain,
                description: "Heavy Rain",
                forecastRain: [17.2, 18.6, 15.4, 12.1, 9.6, 7.2, 4.8, 2.1],
                baseCondition: .heavyRain
            )
        }

        if key.contains("galle road") || key.contains("colombo 03") {
            return makeSnapshot(
                location: location,
                temperature: 24,
                feelsLike: 26,
                humidity: 70,
                wind: 8,
                rainfall: 0,
                dailyRainfall: 2.4,
                condition: .clear,
                description: "Sunny",
                forecastRain: [0, 0, 0.1, 0.3, 0.2, 0.1, 0, 0],
                baseCondition: .clear
            )
        }

        if key.contains("orion") || key.contains("colombo 09") {
            return makeSnapshot(
                location: location,
                temperature: 26,
                feelsLike: 29,
                humidity: 78,
                wind: 22,
                rainfall: 3.1,
                dailyRainfall: 18.4,
                condition: .cloudy,
                description: "Cloudy",
                forecastRain: [4.2, 5.8, 7.9, 6.1, 4.4, 2.2, 1.0, 0.4],
                baseCondition: .rain
            )
        }

        if key.contains("colombo") {
            return makeSnapshot(
                location: location,
                temperature: 28,
                feelsLike: 32,
                humidity: 78,
                wind: 18,
                rainfall: 3.6,
                dailyRainfall: 45.0,
                condition: .partlyCloudy,
                description: "Partly Cloudy",
                forecastRain: [3.2, 5.4, 7.9, 7.1, 4.2, 2.0, 1.1, 0.6],
                baseCondition: .rain
            )
        }

        return generatedSnapshot(for: location)
    }

    func highRiskSnapshot(for location: WeatherLocation) -> WeatherSnapshot {
        makeSnapshot(
            location: location,
            temperature: 27,
            feelsLike: 31,
            humidity: 93,
            wind: 52,
            rainfall: 16.8,
            dailyRainfall: 104.2,
            condition: .thunderstorm,
            description: "Thunderstorm",
            forecastRain: [18.4, 20.2, 17.6, 14.2, 10.1, 7.8, 5.2, 2.4],
            baseCondition: .thunderstorm
        )
    }

    private func generatedSnapshot(for location: WeatherLocation) -> WeatherSnapshot {
        let seed = abs(Int((location.latitude * 1000).rounded()) + Int((location.longitude * 1000).rounded()))
        switch seed % 3 {
        case 0:
            return makeSnapshot(
                location: location,
                temperature: 27,
                feelsLike: 30,
                humidity: 72,
                wind: 12,
                rainfall: 1.2,
                dailyRainfall: 8.6,
                condition: .partlyCloudy,
                description: "Partly Cloudy",
                forecastRain: [1.0, 1.4, 1.8, 1.2, 0.8, 0.4, 0.2, 0.1],
                baseCondition: .partlyCloudy
            )
        case 1:
            return makeSnapshot(
                location: location,
                temperature: 25,
                feelsLike: 28,
                humidity: 84,
                wind: 24,
                rainfall: 4.4,
                dailyRainfall: 22.8,
                condition: .rain,
                description: "Light Rain",
                forecastRain: [4.8, 6.2, 8.2, 6.6, 4.2, 2.6, 1.4, 0.6],
                baseCondition: .rain
            )
        default:
            return makeSnapshot(
                location: location,
                temperature: 29,
                feelsLike: 33,
                humidity: 68,
                wind: 15,
                rainfall: 0.8,
                dailyRainfall: 4.2,
                condition: .clear,
                description: "Sunny",
                forecastRain: [0.6, 0.8, 2.0, 1.4, 0.9, 0.4, 0.2, 0],
                baseCondition: .clear
            )
        }
    }

    private func makeSnapshot(
        location: WeatherLocation,
        temperature: Double,
        feelsLike: Double,
        humidity: Int,
        wind: Double,
        rainfall: Double,
        dailyRainfall: Double,
        condition: WeatherCondition,
        description: String,
        forecastRain: [Double],
        baseCondition: WeatherCondition
    ) -> WeatherSnapshot {
        let now = Date()
        let points = forecastRain.enumerated().map { index, rain in
            let date = Calendar.current.date(byAdding: .hour, value: (index + 1) * 3, to: now) ?? now
            let pointCondition: WeatherCondition
            switch rain {
            case 0: pointCondition = baseCondition == .clear ? .clear : .partlyCloudy
            case ..<2.5: pointCondition = .cloudy
            case ..<7.5: pointCondition = .rain
            default: pointCondition = baseCondition == .thunderstorm ? .thunderstorm : .heavyRain
            }
            return ForecastPoint(
                date: date,
                temperatureC: temperature + Double((index % 3) - 1) * 0.8,
                condition: pointCondition,
                rainfallMM: rain,
                precipitationChance: min(98, 20 + rain * 9)
            )
        }

        return WeatherSnapshot(
            temperatureC: temperature,
            feelsLikeC: feelsLike,
            humidity: humidity,
            windKph: wind,
            rainfallMM: rainfall,
            dailyRainfallMM: dailyRainfall,
            condition: condition,
            conditionDescription: description,
            forecast: points,
            updatedAt: now,
            source: .demo
        )
    }
}
