import Foundation

struct RiskScoringEngine: Sendable {
    struct Thresholds: Sendable {
        var moderateRainfall: Double = 2.5
        var heavyRainfall: Double = 7.5
        var extremeRainfall: Double = 15
        var moderateWind: Double = 20
        var strongWind: Double = 40
        var damagingWind: Double = 60
    }

    var thresholds = Thresholds()

    func assess(weather: WeatherSnapshot, now: Date = .now) -> RiskAssessment {
        let rainfall = max(weather.rainfallMM, 0)
        let wind = max(weather.windKph, 0)
        let forecastRain = max(weather.peakForecastRainfall, 0)

        let rainfallScore = scoreRainfall(rainfall)
        let windScore = scoreWind(wind)
        let forecastScore = scoreForecast(forecastRain)
        let total = min(100, rainfallScore + windScore + forecastScore)
        let level = level(for: total)

        let factors = [
            RiskFactor(
                title: "Rainfall",
                detail: String(format: "%.1f mm/h now", rainfall),
                iconName: "cloud.rain.fill",
                impact: impact(for: rainfallScore, ranges: (10, 25, 40))
            ),
            RiskFactor(
                title: "Wind",
                detail: "\(Int(wind.rounded())) km/h",
                iconName: "wind",
                impact: impact(for: windScore, ranges: (5, 15, 22))
            ),
            RiskFactor(
                title: "Forecast",
                detail: String(format: "Up to %.1f mm/h in 12h", forecastRain),
                iconName: "chart.line.uptrend.xyaxis",
                impact: impact(for: forecastScore, ranges: (5, 14, 22))
            )
        ]

        return RiskAssessment(
            level: level,
            score: total,
            summary: summary(level: level, rainfall: rainfall, wind: wind, forecastRain: forecastRain),
            recommendedActions: actions(for: level),
            factors: factors,
            assessedAt: now
        )
    }

    func scoreRainfall(_ value: Double) -> Int {
        switch value {
        case ..<thresholds.moderateRainfall: return 0
        case ..<thresholds.heavyRainfall: return 20
        case ..<thresholds.extremeRainfall: return 35
        default: return 50
        }
    }

    func scoreWind(_ value: Double) -> Int {
        switch value {
        case ..<thresholds.moderateWind: return 0
        case ..<thresholds.strongWind: return 10
        case ..<thresholds.damagingWind: return 20
        default: return 25
        }
    }

    func scoreForecast(_ value: Double) -> Int {
        switch value {
        case ..<thresholds.moderateRainfall: return 0
        case ..<thresholds.heavyRainfall: return 10
        case ..<thresholds.extremeRainfall: return 18
        default: return 25
        }
    }

    func level(for score: Int) -> RiskLevel {
        if score >= 60 { return .high }
        if score >= 30 { return .medium }
        return .low
    }

    private func impact(for score: Int, ranges: (Int, Int, Int)) -> RiskFactor.Impact {
        if score >= ranges.2 { return .severe }
        if score >= ranges.1 { return .elevated }
        if score >= ranges.0 { return .moderate }
        return .low
    }

    private func summary(level: RiskLevel, rainfall: Double, wind: Double, forecastRain: Double) -> String {
        let rainText = String(format: "%.1f mm/h", rainfall)
        let forecastText = String(format: "%.1f mm/h", forecastRain)
        switch level {
        case .low:
            return "Conditions are currently calm. Rainfall is \(rainText), winds are \(Int(wind.rounded())) km/h, and the near-term forecast shows no significant deterioration."
        case .medium:
            return "Elevated weather risk due to sustained rainfall. Rainfall is \(rainText), winds are \(Int(wind.rounded())) km/h, and forecast rainfall could reach \(forecastText) over the next 12 hours."
        case .high:
            return "Severe weather risk. Rainfall is \(rainText), winds are \(Int(wind.rounded())) km/h, and forecast rainfall could reach \(forecastText) over the next 12 hours. Low-lying areas may flood quickly."
        }
    }

    private func actions(for level: RiskLevel) -> [String] {
        switch level {
        case .low:
            return [
                "Continue normal activities",
                "Keep monitoring official weather updates",
                "Check on neighbours who may need help"
            ]
        case .medium:
            return [
                "Prepare emergency supplies and drinking water",
                "Charge phones and power banks",
                "Monitor DMC and Met Department announcements",
                "Avoid low-lying roads if rain intensifies"
            ]
        case .high:
            return [
                "Move to higher ground if in a flood-prone area",
                "Prepare to evacuate and keep documents safe",
                "Avoid crossing flooded roads",
                "Follow official DMC announcements",
                "Check on elderly neighbours and family"
            ]
        }
    }
}
