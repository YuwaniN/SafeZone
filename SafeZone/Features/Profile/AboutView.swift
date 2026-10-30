import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 14) {
                    hero
                    featuresCard
                    dataCard
                    technologyCard
                    footer
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: Theme.brandTeal.opacity(0.3), radius: 14, x: 0, y: 7)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.szScaled(38, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("SafeZone")
                .font(.szTitle(30))
                .foregroundStyle(Theme.textPrimary)

            Text("Disaster alerts and emergency response for Sri Lanka")
                .font(.szScaled(13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                TagPill(text: "Sri Lanka", icon: "mappin.and.ellipse", color: Theme.brandTeal)
                TagPill(text: "Offline Ready", icon: "wifi.slash", color: Theme.success)
            }

            Text(appVersion)
                .font(.szScaled(10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 22)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What SafeZone Does", subtitle: "Safety tools built for real emergencies")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                feature(icon: "chart.line.uptrend.xyaxis", title: "Risk Scoring", detail: "Weather-based risk for every saved place", tint: Theme.riskMedium)
                feature(icon: "location.circle.fill", title: "Geofencing", detail: "Alerts when you enter a high-risk zone", tint: Theme.riskHigh)
                feature(icon: "map.fill", title: "Emergency Map", detail: "Hospitals, police, fire and shelters", tint: Theme.brandSky)
                feature(icon: "exclamationmark.bubble.fill", title: "Reports", detail: "Share hazards with your community", tint: Theme.warning)
                feature(icon: "book.closed.fill", title: "Offline Guide", detail: "Step-by-step safety instructions", tint: Theme.success)
                feature(icon: "faceid", title: "Face ID", detail: "Protect access to your safety data", tint: Theme.brandTeal)
            }
        }
        .cardStyle()
    }

    private func feature(icon: String, title: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            IconCircle(icon: icon, tint: tint, size: 34)
            Text(title)
                .font(.szScaled(12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(detail)
                .font(.szScaled(10))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(tint.opacity(0.07))
        )
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(title: "Your Data", subtitle: "Privacy by design")

            bullet("Accounts, saved locations, alerts and reports are stored on this device using Core Data.")
            bullet("Weather data is requested from OpenWeatherMap only when an API key is configured. Otherwise SafeZone uses bundled demo conditions.")
            bullet("No advertising SDKs, analytics trackers or third-party crash reporters are included.")
            bullet("Community reports in this build stay on your device and are not uploaded to a server.")
        }
        .cardStyle()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.szScaled(11, weight: .semibold))
                .foregroundStyle(Theme.success)
                .padding(.top, 2)
            Text(text)
                .font(.szScaled(12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var technologyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Built With", subtitle: "Apple frameworks and open data")

            HStack(spacing: 6) {
                TagPill(text: "SwiftUI", color: Theme.brandTeal)
                TagPill(text: "MapKit", color: Theme.brandSky)
                TagPill(text: "Core Data", color: Theme.brandTeal)
                TagPill(text: "Core Location", color: Theme.brandSky)
            }
            HStack(spacing: 6) {
                TagPill(text: "LocalAuthentication", color: Theme.success)
                TagPill(text: "UserNotifications", color: Theme.warning)
                TagPill(text: "Swift Testing", color: Theme.riskMedium)
            }
        }
        .cardStyle()
    }

    private var footer: some View {
        VStack(spacing: 3) {
            Text("Built for COBSCCOMP25.1P coursework")
                .font(.szScaled(10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Text("Emergency numbers: 117 (DMC) • 119 (Police) • 1990 (Ambulance) • 110 (Fire)")
                .font(.szScaled(9))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}
