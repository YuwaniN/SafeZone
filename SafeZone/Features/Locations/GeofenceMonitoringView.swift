import MapKit
import SwiftUI

struct GeofenceMonitoringView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: GeofenceMonitoringViewModel
    @ObservedObject private var geofenceManager: GeofenceManager
    @Environment(\.dismiss) private var dismiss

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _viewModel = StateObject(wrappedValue: GeofenceMonitoringViewModel(container: container, appState: appState))
        _geofenceManager = ObservedObject(wrappedValue: container.geofenceManager)
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 16) {
                    if let selected = viewModel.selectedLocation {
                        locationPicker(selected: selected)
                        mapCard(selected: selected)
                        statusCard(selected: selected)
                        recentAlerts
                        simulationCard(selected: selected)
                    } else {
                        EmptyStateView(
                            icon: "location.slash",
                            title: "No locations to monitor",
                            message: "Add a saved location and enable geofence monitoring to receive entry alerts.",
                            actionTitle: "Manage Saved Locations",
                            action: { dismiss() }
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        InlineMessage(style: .error, message: errorMessage)
                    }

                    footer
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Geofence Monitoring")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func locationPicker(selected: SavedLocation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Monitoring")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.textSecondary)
                Text(selected.name)
                    .font(.szHeadline(19))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Menu {
                ForEach(viewModel.locations) { location in
                    Button {
                        viewModel.select(location)
                    } label: {
                        Label(location.name, systemImage: location.id == selected.id ? "checkmark.circle.fill" : "circle")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Change")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.brandTeal.opacity(0.11)))
            }
            .accessibilityLabel("Change monitored location")
        }
        .padding(.top, 4)
    }

    private func mapCard(selected: SavedLocation) -> some View {
        ZStack(alignment: .topLeading) {
            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: selected.latitude, longitude: selected.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    )
                )
            ) {
                MapCircle(
                    center: CLLocationCoordinate2D(latitude: selected.latitude, longitude: selected.longitude),
                    radius: selected.radius
                )
                .foregroundStyle(Theme.brandTeal.opacity(0.18))
                .stroke(Theme.brandTeal.opacity(0.55), lineWidth: 1.5)

                Marker(
                    selected.name,
                    coordinate: CLLocationCoordinate2D(latitude: selected.latitude, longitude: selected.longitude)
                )
                .tint(Theme.brandTeal)
            }
            .id(selected.id)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack(spacing: 6) {
                Circle()
                    .fill(selected.isMonitoring ? Theme.success : Theme.riskMedium)
                    .frame(width: 7, height: 7)
                Text(selected.isMonitoring ? "MONITORING ACTIVE" : "MONITORING OFF")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(.ultraThinMaterial))
            .padding(12)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map showing \(selected.name) with a \(selected.radiusDisplay) monitored geofence")
    }

    private func statusCard(selected: SavedLocation) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                IconCircle(icon: "location.circle.fill", tint: Theme.brandTeal, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(selected.name)
                        .font(.szHeadline(16))
                    Text(selected.address)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                TagPill(
                    text: selected.isMonitoring ? "Monitored" : "Paused",
                    icon: selected.isMonitoring ? "location.fill" : "pause.fill",
                    color: selected.isMonitoring ? Theme.success : Theme.riskMedium
                )
            }

            Divider()

            HStack {
                statusItem(title: "Geofence Radius", value: selected.radiusDisplay, icon: "circle.dashed")
                Divider().frame(height: 32)
                statusItem(
                    title: "Monitoring Since",
                    value: AppFormatters.shortDate.string(from: selected.monitoringStartedAt),
                    icon: "clock.fill"
                )
            }

            HStack(spacing: 8) {
                Image(systemName: viewModel.isAlwaysAuthorized ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(viewModel.isAlwaysAuthorized ? Theme.success : Theme.riskMedium)
                Text(viewModel.authorizationDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if !viewModel.isAlwaysAuthorized {
                    Button("Enable") {
                        viewModel.requestAuthorization()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.brandTeal.opacity(0.06))
            )
        }
        .cardStyle()
    }

    private func statusItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentAlerts: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Recent Alerts", subtitle: "Geofence entry events")

            if viewModel.alerts.isEmpty {
                HStack(spacing: 10) {
                    IconCircle(icon: "bell.slash.fill", tint: Theme.textSecondary, size: 34)
                    Text("No geofence alerts yet. Use the simulator below to preview one.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.surface)
                )
            } else {
                ForEach(viewModel.alerts.prefix(4)) { alert in
                    AlertRowCard(alert: alert)
                }
            }
        }
    }

    private func simulationCard(selected: SavedLocation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Test Geofence Alerts",
                subtitle: "Core Location region monitoring is active for this location."
            )

            if let result = viewModel.lastResult {
                InlineMessage(
                    style: result.level == .high ? .error : (result.level == .medium ? .warning : .success),
                    message: result.message
                )
            }

            Button {
                Task { await viewModel.simulate(forceHighRisk: false) }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSimulating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "figure.walk.motion")
                    }
                    Text(viewModel.isSimulating ? "Checking risk…" : "Simulate Entering Risk Zone")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isSimulating)

            if AppConfig.isDemoMode {
                Button {
                    Task { await viewModel.simulate(forceHighRisk: true) }
                } label: {
                    Label("Preview High-Risk Alert (Demo)", systemImage: "exclamationmark.triangle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.isSimulating)
            }

            Text("In production, iOS wakes SafeZone when you enter the region. The simulator lets you test the same alert pipeline without moving.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var footer: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                Image(systemName: "map.fill")
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.textTertiary)
            Text("Powered by Core Location + MapKit")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
