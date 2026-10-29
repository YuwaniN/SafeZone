import SwiftUI

struct HomeView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: HomeViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor

    @State private var showSOS = false
    @State private var showAlerts = false
    @State private var showSavedLocations = false

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _viewModel = StateObject(wrappedValue: HomeViewModel(container: container, appState: appState))
        _networkMonitor = ObservedObject(wrappedValue: container.networkMonitor)
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    if !networkMonitor.isConnected || viewModel.isStale {
                        OfflineBanner(
                            message: viewModel.isStale
                                ? "Showing cached weather. Reconnect to refresh."
                                : "You're offline. Showing saved data."
                        )
                    }

                    if let errorMessage = viewModel.errorMessage, viewModel.weather != nil {
                        InlineMessage(
                            style: .warning,
                            message: errorMessage,
                            actionTitle: "Retry",
                            action: { Task { await viewModel.refresh() } }
                        )
                    }

                    if viewModel.isLoading && viewModel.weather == nil {
                        LoadingCard(message: "Checking local weather risk…")
                    } else if viewModel.weather == nil {
                        ErrorStateView(
                            title: "Weather Unavailable",
                            message: viewModel.errorMessage ?? "We couldn't load weather for this location.",
                            retry: { Task { await viewModel.refresh() } }
                        )
                    } else {
                        weatherCard
                        riskCard
                        forecastCard
                    }

                    quickActions
                    recentAlertsSection
                    sosButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 30)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showSOS) {
            SOSSheet(container: container, appState: appState)
        }
        .sheet(isPresented: $showAlerts) {
            NavigationStack {
                AlertsView(container: container, appState: appState)
            }
        }
        .navigationDestination(isPresented: $showSavedLocations) {
            SavedLocationsView(container: container, appState: appState)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(viewModel.greeting), \(viewModel.profileName)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                locationMenu

                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(viewModel.selectedLocation.address)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.textTertiary)
            }

            Spacer(minLength: 6)

            Button {
                showAlerts = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Theme.surface))
                        .overlay(Circle().strokeBorder(Theme.separator.opacity(0.4), lineWidth: 0.8))
                    if appState.unreadAlertCount > 0 {
                        Text("\(min(appState.unreadAlertCount, 9))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Theme.riskHigh))
                            .offset(x: 2, y: -1)
                    }
                }
            }
            .accessibilityLabel("Alerts\(appState.unreadAlertCount > 0 ? ", \(appState.unreadAlertCount) unread" : "")")

            ZStack {
                Circle()
                    .fill(Theme.aquaGradient)
                    .frame(width: 42, height: 42)
                Text(appState.profile?.initials ?? "SZ")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
        }
        .padding(.top, 8)
    }

    private var locationMenu: some View {
        Menu {
            Button {
                Task { await viewModel.useCurrentLocation() }
            } label: {
                Label("Use Current Location", systemImage: "location.fill")
            }

            if !viewModel.savedLocations.isEmpty {
                Section("Saved Locations") {
                    ForEach(viewModel.savedLocations) { location in
                        Button {
                            Task { await viewModel.selectLocation(location) }
                        } label: {
                            Label(location.name, systemImage: "mappin.circle.fill")
                        }
                    }
                }
            }

            Section {
                Button {
                    Task { await viewModel.selectColombo() }
                } label: {
                    Label("Colombo, Sri Lanka", systemImage: "building.2.fill")
                }
                Button {
                    showSavedLocations = true
                } label: {
                    Label("Manage Saved Locations", systemImage: "slider.horizontal.3")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.brandTeal)
                Text(viewModel.selectedLocation.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if viewModel.isLocating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .accessibilityLabel("Selected location: \(viewModel.selectedLocation.name)")
        .accessibilityHint("Change the location to monitor")
    }

    @ViewBuilder
    private var weatherCard: some View {
        if let weather = viewModel.weather {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.heroGradient)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 210, height: 210)
                    .offset(x: 70, y: -80)
                    .accessibilityHidden(true)
                Circle()
                    .fill(Theme.brandAqua.opacity(0.10))
                    .frame(width: 140, height: 140)
                    .offset(x: 20, y: 120)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Current Weather")
                            .font(.system(size: 12, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.65))
                        Spacer()
                        if weather.source == .demo {
                            TagPill(text: "Demo", icon: "sparkles", color: Theme.brandAqua)
                        } else {
                            TagPill(text: "Live", icon: "dot.radiowaves.left.and.right", color: Theme.brandAqua)
                        }
                    }

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(weather.temperatureDisplay)
                                .font(.system(size: 68, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .accessibilityLabel("\(Int(weather.temperatureC.rounded())) degrees Celsius")
                            Text(weather.conditionDescription)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Feels like \(Int(weather.feelsLikeC.rounded()))°")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: weather.condition.iconName)
                            .font(.system(size: 78, weight: .regular))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
                            .accessibilityHidden(true)
                    }

                    Rectangle()
                        .fill(.white.opacity(0.14))
                        .frame(height: 0.8)

                    HStack(spacing: 0) {
                        WeatherMetric(
                            icon: "cloud.rain.fill",
                            title: "Rain Today",
                            value: weather.rainfallDisplay,
                            light: true
                        )
                        WeatherMetric(
                            icon: "wind",
                            title: "Wind",
                            value: weather.windDisplay,
                            light: true
                        )
                        WeatherMetric(
                            icon: "humidity.fill",
                            title: "Humidity",
                            value: weather.humidityDisplay,
                            light: true
                        )
                    }
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Theme.brandNavy.opacity(0.25), radius: 22, x: 0, y: 12)
        }
    }

    @ViewBuilder
    private var riskCard: some View {
        if let weather = viewModel.weather, let risk = viewModel.risk {
            HStack(alignment: .center, spacing: 18) {
                RiskGauge(level: risk.level, score: risk.score, size: 104)

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("Local Risk Analysis")
                            .font(.system(size: 11, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        RiskBadge(level: risk.level, compact: true)
                    }

                    Text(risk.level.title)
                        .font(.szHeadline(21))
                        .foregroundStyle(risk.level.color)

                    Text(risk.summary)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(2)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    NavigationLink {
                        RiskDetailView(
                            location: viewModel.selectedLocation,
                            weather: weather,
                            risk: risk,
                            appState: appState
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Text("View Risk Details")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.brandTeal)
                    }
                    .accessibilityHint("Opens the full risk assessment and safety actions")
                }
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private var forecastCard: some View {
        if let weather = viewModel.weather, !weather.forecast.isEmpty {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Text("Next 12 Hours")
                        .font(.szHeadline(16))
                    Spacer()
                    Text("Colombo forecast")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }

                HStack(spacing: 0) {
                    ForEach(weather.forecast.prefix(4)) { point in
                        VStack(spacing: 7) {
                            Text(AppFormatters.hour.string(from: point.date))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                            Image(systemName: point.condition.iconName)
                                .font(.system(size: 21, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(point.condition.tint)
                            Text("\(Int(point.temperatureC.rounded()))°")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(Int(point.precipitationChance.rounded()))%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(AppFormatters.hour.string(from: point.date)), \(point.condition.title), \(Int(point.temperatureC.rounded())) degrees, \(Int(point.precipitationChance.rounded())) percent chance of rain")
                    }
                }
            }
            .cardStyle(padding: 16)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions", subtitle: "Everything you need in an emergency")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                spacing: 12
            ) {
                NavigationLink {
                    SavedLocationsView(container: container, appState: appState)
                } label: {
                    QuickActionCard(
                        icon: "mappin.and.ellipse",
                        title: "Saved Locations",
                        subtitle: "\(viewModel.savedLocations.count) monitored",
                        tint: Theme.brandTeal
                    )
                }
                .buttonStyle(.plain)

                Button {
                    appState.openTab(.map)
                } label: {
                    QuickActionCard(
                        icon: "map.fill",
                        title: "Emergency Map",
                        subtitle: "Hospitals & shelters",
                        tint: Color(hex: 0x2563EB)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    appState.openTab(.reports)
                } label: {
                    QuickActionCard(
                        icon: "exclamationmark.bubble.fill",
                        title: "Reports",
                        subtitle: "Community hazards",
                        tint: Color(hex: 0xD97706)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    appState.openTab(.guide)
                } label: {
                    QuickActionCard(
                        icon: "book.closed.fill",
                        title: "Offline Guide",
                        subtitle: "Works without data",
                        tint: Color(hex: 0x15803D)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Recent Alerts",
                subtitle: "Risk changes and geofence events",
                actionTitle: viewModel.recentAlerts.isEmpty ? nil : "See All",
                action: viewModel.recentAlerts.isEmpty ? nil : { showAlerts = true }
            )

            if viewModel.recentAlerts.isEmpty {
                HStack(spacing: 12) {
                    IconCircle(icon: "bell.slash.fill", tint: Theme.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No alerts yet")
                            .font(.szHeadline(15))
                        Text("We'll notify you when risk changes at your saved locations.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
                .cardStyle(padding: 14)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentAlerts.prefix(3)) { alert in
                        AlertRowCard(alert: alert)
                    }
                }
            }
        }
    }

    private var sosButton: some View {
        Button {
            showSOS = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Text("SOS")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Emergency SOS")
                        .font(.szHeadline(18))
                        .foregroundStyle(.white)
                    Text("Call hotlines or open the emergency map")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x991B1B), Color(hex: 0xEF4444)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Theme.riskHigh.opacity(0.32), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens emergency contacts and map shortcuts")
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(icon: icon, tint: tint, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.35), lineWidth: 0.7)
        )
        .accessibilityElement(children: .combine)
    }
}

struct AlertRowCard: View {
    let alert: AlertRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconCircle(icon: alert.level.iconName, tint: alert.level.color, size: 38)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(alert.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    if !alert.isRead {
                        Circle()
                            .fill(Theme.riskHigh)
                            .frame(width: 6, height: 6)
                            .accessibilityLabel("Unread")
                    }
                    Spacer(minLength: 0)
                    Text(AppFormatters.timeAgo(alert.createdAt))
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
                Text(alert.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.35), lineWidth: 0.7)
        )
        .accessibilityElement(children: .combine)
    }
}
