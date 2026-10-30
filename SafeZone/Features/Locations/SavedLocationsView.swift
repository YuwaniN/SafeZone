import SwiftUI

struct SavedLocationsView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: SavedLocationsViewModel

    @State private var showAddLocation = false
    @State private var editingLocation: SavedLocation?
    @State private var locationToDelete: SavedLocation?

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _viewModel = StateObject(wrappedValue: SavedLocationsViewModel(container: container, appState: appState))
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    geofenceCard

                    if viewModel.isLoading && viewModel.locations.isEmpty {
                        LoadingCard(message: "Loading your saved locations…")
                    } else if viewModel.locations.isEmpty {
                        EmptyStateView(
                            icon: "mappin.slash",
                            title: "No saved locations",
                            message: "Add Home, Work or a relative's home to monitor weather risk and receive geofence alerts.",
                            actionTitle: "Add Location",
                            action: { showAddLocation = true }
                        )
                    } else {
                        ForEach(viewModel.locations) { location in
                            locationCard(location)
                        }

                        Button {
                            showAddLocation = true
                        } label: {
                            Label("Add New Location", systemImage: "plus.circle.fill")
                                .font(.szScaled(15, weight: .semibold))
                                .foregroundStyle(Theme.brandTeal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(
                                            Theme.brandTeal.opacity(0.35),
                                            style: StrokeStyle(lineWidth: 1.2, dash: [6, 4])
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    infoCard

                    if let errorMessage = viewModel.errorMessage {
                        InlineMessage(style: .error, message: errorMessage)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationTitle("Saved Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddLocation = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add location")
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showAddLocation) {
            NavigationStack {
                AddLocationView(
                    container: container,
                    appState: appState,
                    existingLocation: nil,
                    onSaved: { Task { await viewModel.refresh() } }
                )
            }
        }
        .sheet(item: $editingLocation) { location in
            NavigationStack {
                AddLocationView(
                    container: container,
                    appState: appState,
                    existingLocation: location,
                    onSaved: { Task { await viewModel.refresh() } }
                )
            }
        }
        .confirmationDialog(
            "Delete \(locationToDelete?.name ?? "location")?",
            isPresented: Binding(
                get: { locationToDelete != nil },
                set: { if !$0 { locationToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Location", role: .destructive) {
                if let locationToDelete {
                    viewModel.delete(locationToDelete)
                }
                locationToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                locationToDelete = nil
            }
        } message: {
            Text("This removes the location, its risk history and any active geofence monitoring.")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Monitor what matters")
                    .font(.szHeadline(18))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(viewModel.locations.count) locations • \(viewModel.monitoredCount) monitoring alerts")
                    .font(.szScaled(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            RiskBadge(level: .low, compact: true)
        }
        .padding(.top, 4)
    }

    private var geofenceCard: some View {
        NavigationLink {
            GeofenceMonitoringView(container: container, appState: appState)
        } label: {
            HStack(spacing: 13) {
                IconCircle(icon: "location.circle.fill", tint: Theme.brandTeal, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Geofence Monitoring")
                        .font(.szHeadline(16))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Alerts when you physically enter a risk zone")
                        .font(.szScaled(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.monitoredCount)")
                        .font(.szScaled(18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.brandTeal)
                    Text("active")
                        .font(.szScaled(10))
                        .foregroundStyle(Theme.textTertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.szScaled(12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func locationCard(_ location: SavedLocation) -> some View {
        VStack(spacing: 0) {
            Group {
                if let summary = viewModel.summary(for: location) {
                    NavigationLink {
                        RiskDetailView(
                            location: location.weatherLocation,
                            weather: summary.weather,
                            risk: summary.risk,
                            appState: appState
                        )
                    } label: {
                        cardHeader(location: location, summary: summary)
                    }
                    .buttonStyle(.plain)
                } else {
                    cardHeader(location: location, summary: nil)
                }
            }

            Divider()
                .padding(.vertical, 10)

            HStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { location.isMonitoring },
                    set: { newValue in
                        Task { await viewModel.setMonitoring(newValue, for: location) }
                    }
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.szScaled(12, weight: .semibold))
                            .foregroundStyle(Theme.brandTeal)
                        Text("Alerts")
                            .font(.szScaled(13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .tint(Theme.brandTeal)
                .accessibilityLabel("Alerts for \(location.name)")

                Spacer()

                Menu {
                    Button {
                        editingLocation = location
                    } label: {
                        Label("Edit Location", systemImage: "pencil")
                    }
                    Button {
                        locationToDelete = location
                    } label: {
                        Label("Delete Location", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.szScaled(21))
                        .foregroundStyle(Theme.textTertiary)
                }
                .accessibilityLabel("More options for \(location.name)")
            }
        }
        .cardStyle(padding: 16)
    }

    private func cardHeader(location: SavedLocation, summary: LocationRiskSummary?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconCircle(icon: "house.fill", tint: riskColor(summary?.risk.level), size: 46)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(location.name)
                        .font(.szHeadline(18))
                        .foregroundStyle(Theme.textPrimary)
                    if let level = summary?.risk.level {
                        RiskBadge(level: level, compact: true)
                    } else {
                        TagPill(text: "Loading", color: Theme.textTertiary)
                    }
                }
                Text(location.address)
                    .font(.szScaled(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    if let weather = summary?.weather {
                        Label("\(weather.temperatureDisplay) \(weather.conditionDescription)", systemImage: weather.condition.iconName)
                            .font(.szScaled(11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Label(location.radiusDisplay, systemImage: "circle.dashed")
                        .font(.szScaled(11, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.szScaled(12, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 6)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var infoCard: some View {
        InlineMessage(
            style: .info,
            message: "SafeZone checks saved locations in the background and alerts you when risk levels change. Geofences use up to 20 monitored regions."
        )
    }

    private func riskColor(_ level: RiskLevel?) -> Color {
        level?.color ?? Theme.brandTeal
    }
}
