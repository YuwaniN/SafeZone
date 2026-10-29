import SwiftUI

struct RiskDetailView: View {
    let location: WeatherLocation
    let weather: WeatherSnapshot
    let risk: RiskAssessment
    @ObservedObject var appState: AppState

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    weatherStats
                    situationReport
                    recommendedActions
                    disclaimer
                    actions
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Risk Alert")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(risk.level.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(location.address)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: risk.level.iconName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }

            HStack {
                RiskGauge(level: risk.level, score: risk.score, size: 82)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Indicative weather risk")
                        .font(.system(size: 11, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(AppFormatters.updated(risk.assessedAt))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(weather.source == .demo ? "Demo weather data" : "Live weather data")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.brandAqua)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.riskGradient(for: risk.level))
        )
        .shadow(color: risk.level.color.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    private var weatherStats: some View {
        HStack(spacing: 0) {
            WeatherMetric(icon: "thermometer.medium", title: "Temperature", value: weather.temperatureDisplay)
            WeatherMetric(icon: "cloud.rain.fill", title: "Rainfall (24h)", value: weather.rainfallDisplay)
            WeatherMetric(icon: "wind", title: "Wind", value: weather.windDisplay)
            WeatherMetric(icon: "humidity.fill", title: "Humidity", value: weather.humidityDisplay)
        }
        .cardStyle(padding: 16)
    }

    private var situationReport: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Situation Report")
            Text(risk.summary)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(spacing: 10) {
                ForEach(risk.factors) { factor in
                    HStack(spacing: 12) {
                        IconCircle(icon: factor.iconName, tint: impactColor(factor.impact), size: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(factor.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(factor.detail)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        TagPill(
                            text: factor.impact.rawValue.capitalized,
                            color: impactColor(factor.impact)
                        )
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .cardStyle()
    }

    private var recommendedActions: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(title: "Recommended Safety Actions")

            ForEach(Array(risk.recommendedActions.enumerated()), id: \.offset) { index, action in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(risk.level.color))
                    Text(action)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .cardStyle()
    }

    private var disclaimer: some View {
        InlineMessage(style: .info, message: AppConfig.dataDisclaimer)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
                appState.openTab(.map)
            } label: {
                Label("View Emergency Map", systemImage: "map.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            ShareLink(item: shareText) {
                Label("Share Alert", systemImage: "square.and.arrow.up")
                    .font(.szHeadline(16))
                    .foregroundStyle(Theme.brandTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.brandTeal.opacity(0.11))
                    )
            }

            Button {
                dismiss()
                appState.openTab(.guide)
            } label: {
                Label("Open Offline Emergency Guide", systemImage: "book.closed.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var shareText: String {
        var text = """
        SafeZone Risk Alert — \(location.name)
        \(risk.level.title) (\(risk.score)/100)
        \(risk.summary)

        Recommended actions:
        """
        for action in risk.recommendedActions {
            text += "\n• \(action)"
        }
        text += "\n\n\(AppConfig.dataDisclaimer)"
        return text
    }

    private func impactColor(_ impact: RiskFactor.Impact) -> Color {
        switch impact {
        case .low: return Theme.riskLow
        case .moderate: return Theme.brandTeal
        case .elevated: return Theme.riskMedium
        case .severe: return Theme.riskHigh
        }
    }
}
