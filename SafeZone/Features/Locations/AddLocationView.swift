import MapKit
import SwiftUI

struct AddLocationView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    var existingLocation: SavedLocation?
    var onSaved: () -> Void

    @StateObject private var viewModel: AddLocationViewModel
    @StateObject private var search = AddressSearchService()
    @State private var isResolvingAddress = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(
        container: AppContainer,
        appState: AppState,
        existingLocation: SavedLocation?,
        onSaved: @escaping () -> Void
    ) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        self.existingLocation = existingLocation
        self.onSaved = onSaved
        _viewModel = StateObject(
            wrappedValue: AddLocationViewModel(
                container: container,
                appState: appState,
                existingLocation: existingLocation
            )
        )
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 16) {
                    nameSection
                    addressSection
                    mapPreview
                    monitoringSection
                    radiusSection

                    if let errorMessage = viewModel.errorMessage {
                        InlineMessage(style: .error, message: errorMessage)
                    }

                    saveButton

                    if viewModel.isEditing {
                        Button("Delete Location", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .font(.szScaled(14, weight: .semibold))
                        .foregroundStyle(Theme.riskHigh)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Location" : "Add Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .confirmationDialog(
            "Delete \(existingLocation?.name ?? "location")?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Location", role: .destructive) {
                if viewModel.delete() {
                    onSaved()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also removes the geofence and alert history for this location.")
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location Name")
                .font(.szScaled(12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField("Home, Work, Amma's House…", text: $viewModel.name)
                .font(.szScaled(16, weight: .semibold))
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
                )
        }
        .padding(.top, 4)
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address / Pin Location")
                .font(.szScaled(12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textSecondary)
                TextField("Search address or place", text: $search.query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                if isResolvingAddress {
                    ProgressView().controlSize(.small)
                }
            }
            .font(.szScaled(15))
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
            )

            if !search.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(search.suggestions.enumerated()), id: \.offset) { index, suggestion in
                        Button {
                            Task { await resolve(suggestion) }
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Theme.brandTeal)
                                    .padding(.top, 1)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(suggestion.title)
                                        .font(.szScaled(13, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.szScaled(11))
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < search.suggestions.count - 1 {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.separator.opacity(0.4), lineWidth: 0.7)
                )
            }

            if !viewModel.address.isEmpty {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                    Text(viewModel.address)
                        .font(.szScaled(12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
            }

            Button {
                Task { await viewModel.useCurrentLocation() }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isUsingCurrentLocation {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text("Use Current GPS Location")
                }
                .font(.szScaled(13, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
            }
            .padding(.top, 2)
        }
    }

    private var mapPreview: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: viewModel.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )
            )
        ) {
            MapCircle(center: viewModel.coordinate, radius: viewModel.radius)
                .foregroundStyle(Theme.brandTeal.opacity(0.18))
            Marker(
                viewModel.name.isEmpty ? "Saved Location" : viewModel.name,
                coordinate: viewModel.coordinate
            )
            .tint(Theme.brandTeal)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.4), lineWidth: 0.8)
        )
        .allowsHitTesting(false)
        .accessibilityLabel("Map preview of the selected location and geofence radius")
    }

    private var monitoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Risk Monitoring", subtitle: "Choose which alerts this location can send")

            Toggle(isOn: $viewModel.isMonitoring) {
                settingLabel(icon: "location.circle.fill", title: "Geofence Monitoring", subtitle: "Alert when you enter this area")
            }
            .tint(Theme.brandTeal)

            Divider()

            Toggle(isOn: $viewModel.weatherAlerts) {
                settingLabel(icon: "cloud.bolt.rain.fill", title: "Weather Alerts", subtitle: "Rainfall, wind and storm warnings")
            }
            .tint(Theme.brandTeal)

            Toggle(isOn: $viewModel.riskLevelChanges) {
                settingLabel(icon: "chart.line.uptrend.xyaxis", title: "Risk Level Changes", subtitle: "When the risk level rises or falls")
            }
            .tint(Theme.brandTeal)

            Toggle(isOn: $viewModel.emergencyAlerts) {
                settingLabel(icon: "exclamationmark.octagon.fill", title: "Emergency Alerts", subtitle: "High-risk and emergency events")
            }
            .tint(Theme.brandTeal)
        }
        .cardStyle()
    }

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Geofence Radius")
                Spacer()
                Text(viewModel.radius >= 1000 ? String(format: "%.1f km", viewModel.radius / 1000) : "\(Int(viewModel.radius)) m")
                    .font(.szScaled(14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.brandTeal)
            }
            Slider(value: $viewModel.radius, in: 100...2_000, step: 50)
                .tint(Theme.brandTeal)
                .disabled(!viewModel.isMonitoring)
                .accessibilityValue("\(Int(viewModel.radius)) metres")
            Text("iOS allows up to 20 monitored regions. Larger radii use fewer precise boundaries.")
                .font(.szScaled(11))
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle(padding: 16)
    }

    private var saveButton: some View {
        Button {
            Task {
                if await viewModel.save() {
                    onSaved()
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                }
                Text(viewModel.isSaving ? "Saving…" : "Save Location")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.canSave)
        .padding(.top, 4)
    }

    private func settingLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.szScaled(14, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.szScaled(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.szScaled(11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        isResolvingAddress = true
        defer { isResolvingAddress = false }
        if let item = await search.resolve(completion) {
            viewModel.applyMapItem(item)
        }
        search.clear()
    }
}
