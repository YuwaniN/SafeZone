import SwiftUI
import UIKit

enum Theme {
    static let brandNavy = Color(hex: 0x07263B)
    static let brandDeep = Color(hex: 0x0B3B4D)
    static let brandTeal = Color(hex: 0x0E7490)
    static let brandAqua = Color(hex: 0x22D3EE)
    static let brandSky = Color(hex: 0x38BDF8)
    static let riskLow = Color(hex: 0x16A34A)
    static let riskMedium = Color(hex: 0xD97706)
    static let riskHigh = Color(hex: 0xDC2626)
    static let warning = Color(hex: 0xF59E0B)
    static let success = Color(hex: 0x10B981)

    static let cornerRadius: CGFloat = 22
    static let smallRadius: CGFloat = 14
    static let cardPadding: CGFloat = 18

    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.035, green: 0.075, blue: 0.102, alpha: 1)
            : UIColor(red: 0.945, green: 0.969, blue: 0.980, alpha: 1)
    })

    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.125, blue: 0.157, alpha: 1)
            : UIColor.white
    })

    static let surfaceElevated = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.098, green: 0.165, blue: 0.204, alpha: 1)
            : UIColor(red: 0.984, green: 0.992, blue: 0.996, alpha: 1)
    })

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    static let separator = Color(uiColor: .separator)

    static let heroGradient = LinearGradient(
        colors: [brandNavy, brandDeep, brandTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let aquaGradient = LinearGradient(
        colors: [brandTeal, brandAqua],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.024, green: 0.059, blue: 0.082, alpha: 1)
                    : UIColor(red: 0.910, green: 0.957, blue: 0.976, alpha: 1)
            }),
            background
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func riskGradient(for level: RiskLevel) -> LinearGradient {
        LinearGradient(
            colors: level.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(hex: UInt(value))
    }
}

extension Font {
    static func szTitle(_ size: CGFloat = 28) -> Font {
        szScaled(size, weight: .bold, design: .rounded)
    }

    static func szHeadline(_ size: CGFloat = 18) -> Font {
        szScaled(size, weight: .semibold, design: .rounded)
    }

    static func szBody(_ size: CGFloat = 15) -> Font {
        szScaled(size, weight: .regular, design: .default)
    }

    static func szScaled(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        let textStyle: UIFont.TextStyle
        if size < 11.5 {
            textStyle = .caption2
        } else if size < 13 {
            textStyle = .caption1
        } else if size < 14.5 {
            textStyle = .footnote
        } else if size < 16.5 {
            textStyle = .subheadline
        } else if size < 19 {
            textStyle = .body
        } else if size < 23 {
            textStyle = .title3
        } else if size < 27 {
            textStyle = .title2
        } else if size < 33 {
            textStyle = .title1
        } else {
            textStyle = .largeTitle
        }
        let scaled = UIFontMetrics(forTextStyle: textStyle).scaledValue(for: size)
        return .system(size: min(scaled, size * 1.5), weight: weight, design: design)
    }
}

extension RiskLevel {
    var color: Color {
        switch self {
        case .low: return Theme.riskLow
        case .medium: return Theme.riskMedium
        case .high: return Theme.riskHigh
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .low: return [Color(hex: 0x047857), Color(hex: 0x34D399)]
        case .medium: return [Color(hex: 0xB45309), Color(hex: 0xFBBF24)]
        case .high: return [Color(hex: 0x991B1B), Color(hex: 0xF87171)]
        }
    }

    var softColor: Color {
        color.opacity(0.13)
    }

    var accessibilityDescription: String {
        switch self {
        case .low: return "Low weather risk"
        case .medium: return "Medium weather risk"
        case .high: return "High weather risk"
        }
    }
}

extension IncidentCategory {
    var color: Color {
        switch self {
        case .floodedRoad: return Color(hex: 0x2563EB)
        case .roadBlockage: return Color(hex: 0xD97706)
        case .fallenTree: return Color(hex: 0x15803D)
        case .stormDamage: return Color(hex: 0x7C3AED)
        case .other: return Color(hex: 0x64748B)
        }
    }

    var softColor: Color { color.opacity(0.14) }
}

extension EmergencyServiceCategory {
    var color: Color {
        switch self {
        case .hospital: return Color(hex: 0xDC2626)
        case .police: return Color(hex: 0x1D4ED8)
        case .fire: return Color(hex: 0xEA580C)
        case .shelter: return Color(hex: 0x15803D)
        }
    }
}

extension WeatherCondition {
    var tint: Color {
        switch self {
        case .clear: return Color(hex: 0xF59E0B)
        case .partlyCloudy: return Color(hex: 0x38BDF8)
        case .cloudy: return Color(hex: 0x94A3B8)
        case .rain, .heavyRain: return Color(hex: 0x3B82F6)
        case .thunderstorm: return Color(hex: 0x7C3AED)
        case .mist: return Color(hex: 0x64748B)
        case .unknown: return Theme.textSecondary
        }
    }
}

extension AlertKind {
    var iconName: String {
        switch self {
        case .riskChange: return "chart.line.uptrend.xyaxis"
        case .geofence: return "location.circle.fill"
        case .emergency: return "exclamationmark.octagon.fill"
        }
    }
}
