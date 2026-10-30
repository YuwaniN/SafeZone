import MapKit
import SwiftUI

struct EmergencyMapView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: EmergencyMapViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _viewModel = StateObject(wrappedValue: EmergencyMapViewModel(container: container, appState: appState))
        _networkMonitor = ObservedObject(wrappedValue: container.networkMonitor)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.selectedIncident) { incident in
            NavigationStack {
                ReportDetailView(container: container, appState: appState, report: incident)
            }
        }
    }

    private var compactLayout: some View {
        ZStack(alignment: .top) {
            baseMap
            topOverlay
            if viewModel.isLoading || viewModel.isLocating {
                LoadingCard(
                    message: viewModel.isLocating ? "Finding your location…" : "Finding nearby services…"
                )
                .padding(.horizontal, 48)
                .frame(maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomPanel
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                baseMap
                centerPill
                    .padding(16)
                if viewModel.isLoading || viewModel.isLocating {
                    LoadingCard(
                        message: viewModel.isLocating ? "Finding your location…" : "Finding nearby services…"
                    )
                    .padding(.horizontal, 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            sidebar
                .frame(width: 380)
        }
    }

    private var baseMap: some View {
        Map(position: $viewModel.cameraPosition) {
            UserAnnotation()

            ForEach(viewModel.savedLocations) { location in
                MapCircle(
                    center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                    radius: location.radius
                )
                .foregroundStyle(viewModel.risk(for: location).color.opacity(0.13))
                .stroke(viewModel.risk(for: location).color.opacity(0.45), lineWidth: 1.2)

                Annotation(
                    location.name,
                    coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                ) {
                    SavedLocationPin(name: location.name, color: viewModel.risk(for: location).color)
                }
            }

            ForEach(viewModel.mapServices) { service in
                Annotation(
                    service.name,
                    coordinate: CLLocationCoordinate2D(latitude: service.latitude, longitude: service.longitude)
                ) {
                    Button {
                        viewModel.select(service)
                    } label: {
                        MapServicePin(service: service)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(service.name), \(service.category.singularTitle)")
                }
            }

            ForEach(viewModel.visibleIncidents) { incident in
                Annotation(
                    incident.title,
                    coordinate: CLLocationCoordinate2D(latitude: incident.latitude, longitude: incident.longitude)
                ) {
                    Button {
                        viewModel.select(incident)
                    } label: {
                        MapIncidentPin(incident: incident)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(incident.category.title): \(incident.title)")
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .bottomTrailing) {
            recenterButton
                .padding(16)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var topOverlay: some View {
        VStack(spacing: 10) {
            searchBar
            filterChips
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.szScaled(14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                TextField("Search services or reports", text: $viewModel.searchText)
                    .font(.szScaled(14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(Capsule().fill(.regularMaterial))
            .overlay(Capsule().strokeBorder(Theme.separator.opacity(0.35), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)

            Button {
                Task { await viewModel.recenterToUser() }
            } label: {
                Image(systemName: viewModel.isLocating ? "location.fill" : "location")
                    .font(.szScaled(15, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.regularMaterial))
                    .overlay(Circle().strokeBorder(Theme.separator.opacity(0.35), lineWidth: 0.8))
            }
            .accessibilityLabel("Use current location")
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapFilter.allCases) { filter in
                    FilterChip(
                        title: filter.title,
                        icon: filter.iconName,
                        isSelected: viewModel.filter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel.filter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var centerPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "location.fill")
                .font(.szScaled(10, weight: .bold))
            Text(viewModel.centerName)
                .font(.szScaled(12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.regularMaterial))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    private var recenterButton: some View {
        Button {
            viewModel.recenter()
        } label: {
            Image(systemName: "scope")
                .font(.szScaled(16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 42, height: 42)
                .background(Circle().fill(.regularMaterial))
                .overlay(Circle().strokeBorder(Theme.separator.opacity(0.35), lineWidth: 0.8))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Recenter map")
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Emergency Map")
                    .font(.szTitle(26))
                    .foregroundStyle(Theme.textPrimary)
                Text("Near \(viewModel.centerName)")
                    .font(.szScaled(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 6)

            searchBar
            filterChips

            if !networkMonitor.isConnected {
                OfflineBanner()
            }

            if let service = viewModel.selectedService {
                ScrollView {
                    selectedServiceCard(service)
                        .padding(.top, 2)
                }
            } else {
                listContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Theme.background)
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 9) {
                if viewModel.isLocationDenied {
                    InlineMessage(
                        style: .warning,
                        message: "Location access is off. Showing services near \(viewModel.centerName).",
                        actionTitle: "Settings"
                    ) {
                        viewModel.openSettings()
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    InlineMessage(style: .error, message: errorMessage, actionTitle: "Retry") {
                        Task { await viewModel.refresh() }
                    }
                }

                if viewModel.filter == .incidents {
                    incidentList
                } else {
                    serviceList
                }
            }
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var serviceList: some View {
        let items = viewModel.visibleServices
        if items.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No services found",
                message: viewModel.searchText.isEmpty
                    ? "Nearby emergency services could not be loaded right now."
                    : "Try a different search term or clear the filters."
            )
            .padding(.top, 6)
        } else {
            ForEach(items) { service in
                MapServiceRow(service: service) {
                    viewModel.select(service)
                }
            }
        }
    }

    @ViewBuilder
    private var incidentList: some View {
        let items = viewModel.visibleIncidents
        if items.isEmpty {
            EmptyStateView(
                icon: "exclamationmark.bubble",
                title: "No reports found",
                message: "No community reports match this search. Be the first to add one."
            )
            .padding(.top, 6)
        } else {
            ForEach(items) { incident in
                MapIncidentRow(
                    incident: incident,
                    distance: viewModel.distance(for: incident)
                ) {
                    viewModel.select(incident)
                }
            }
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        VStack(spacing: 9) {
            if let service = viewModel.selectedService {
                selectedServiceCard(service)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                nearbyPanel
            }

            if viewModel.isLocationDenied {
                InlineMessage(
                    style: .warning,
                    message: "Location access is off. Showing services near \(viewModel.centerName).",
                    actionTitle: "Settings"
                ) {
                    viewModel.openSettings()
                }
            }

            if let errorMessage = viewModel.errorMessage {
                InlineMessage(style: .error, message: errorMessage, actionTitle: "Retry") {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            Theme.background
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 18, x: 0, y: -4)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.selectedService)
    }

    private var nearbyPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.filter == .incidents ? "Community Reports" : "Nearby Services")
                        .font(.szHeadline(17))
                        .foregroundStyle(Theme.textPrimary)
                    Text(resultsSubtitle)
                        .font(.szScaled(11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.szScaled(13, weight: .semibold))
                        .foregroundStyle(Theme.brandTeal)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Theme.brandTeal.opacity(0.1)))
                }
                .accessibilityLabel("Refresh nearby results")
            }

            if viewModel.filter == .incidents {
                if viewModel.visibleIncidents.isEmpty {
                    compactEmpty(message: "No community reports match this search.")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(viewModel.visibleIncidents.prefix(6)) { incident in
                                IncidentCompactCard(
                                    incident: incident,
                                    distance: viewModel.distance(for: incident)
                                ) {
                                    viewModel.select(incident)
                                }
                            }
                        }
                        .padding(.bottom, 2)
                    }
                }
            } else {
                if viewModel.visibleServices.isEmpty {
                    compactEmpty(message: "No emergency services match this search.")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(viewModel.visibleServices.prefix(8)) { service in
                                ServiceCompactCard(service: service) {
                                    viewModel.select(service)
                                }
                            }
                        }
                        .padding(.bottom, 2)
                    }
                }
            }
        }
    }

    private func compactEmpty(message: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textTertiary)
            Text(message)
                .font(.szScaled(12))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private func selectedServiceCard(_ service: EmergencyService) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                IconCircle(icon: service.category.iconName, tint: service.category.color, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(service.name)
                            .font(.szHeadline(16))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                        if let isOpen = service.isOpen {
                            TagPill(
                                text: isOpen ? "Open" : "Closed",
                                color: isOpen ? Theme.success : Theme.riskHigh
                            )
                        }
                    }
                    Text(serviceSubtitle(service))
                        .font(.szScaled(11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text(service.address)
                        .font(.szScaled(11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Button {
                    viewModel.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.szScaled(18))
                        .foregroundStyle(Theme.textTertiary)
                }
                .accessibilityLabel("Close service details")
            }

            HStack(spacing: 9) {
                if let callURL = service.callURL {
                    Button {
                        openURL(callURL)
                    } label: {
                        Label("Call", systemImage: "phone.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                if let mapsURL = service.mapsURL {
                    Button {
                        openURL(mapsURL)
                    } label: {
                        Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .cardStyle(padding: 14)
    }

    private func serviceSubtitle(_ service: EmergencyService) -> String {
        var parts = [service.category.singularTitle]
        if let distance = service.distanceDisplay {
            parts.append(distance)
        }
        return parts.joined(separator: " • ")
    }

    private var resultCount: Int {
        viewModel.filter == .incidents ? viewModel.visibleIncidents.count : viewModel.visibleServices.count
    }

    private var resultsSubtitle: String {
        if viewModel.filter == .incidents {
            return "\(resultCount) reports near \(viewModel.centerName)"
        }
        if viewModel.mapServices.count < resultCount {
            return "\(resultCount) results • \(viewModel.mapServices.count) on map"
        }
        return "\(resultCount) results near \(viewModel.centerName)"
    }
}

private struct MapServicePin: View {
    let service: EmergencyService

    var body: some View {
        ZStack {
            Circle()
                .fill(service.category.color)
                .frame(width: 34, height: 34)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            Image(systemName: service.category.iconName)
                .font(.szScaled(14, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct MapIncidentPin: View {
    let incident: IncidentReport

    var body: some View {
        ZStack {
            Circle()
                .fill(incident.category.color)
                .frame(width: 32, height: 32)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            Image(systemName: incident.category.iconName)
                .font(.szScaled(13, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct SavedLocationPin: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.white, lineWidth: 2)
                    )
                Image(systemName: "house.fill")
                    .font(.szScaled(12, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(name)
                .font(.szScaled(9, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule().fill(.regularMaterial))
        }
    }
}

private struct MapServiceRow: View {
    let service: EmergencyService
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                IconCircle(icon: service.category.iconName, tint: service.category.color, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name)
                        .font(.szHeadline(14))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(service.category.singularTitle)
                        .font(.szScaled(11, weight: .medium))
                        .foregroundStyle(service.category.color)
                    Text(service.address)
                        .font(.szScaled(11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 4) {
                    if let distance = service.distanceDisplay {
                        Text(distance)
                            .font(.szScaled(11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.szScaled(10, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Theme.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows service details")
    }
}

private struct MapIncidentRow: View {
    let incident: IncidentReport
    let distance: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 11) {
                IconCircle(icon: incident.category.iconName, tint: incident.category.color, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        TagPill(text: incident.category.shortTitle, color: incident.category.color)
                        if incident.isVerified {
                            TagPill(text: "Verified", icon: "checkmark.seal.fill", color: Theme.success)
                        }
                    }
                    Text(incident.title)
                        .font(.szHeadline(14))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    Text("\(AppFormatters.timeAgo(incident.createdAt)) • \(AppFormatters.distance(distance))")
                        .font(.szScaled(11))
                        .foregroundStyle(Theme.textSecondary)
                    Text(incident.address)
                        .font(.szScaled(11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.szScaled(9))
                    Text("\(incident.upvotes)")
                        .font(.szScaled(11, weight: .semibold))
                }
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Theme.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the community report")
    }
}

private struct ServiceCompactCard: View {
    let service: EmergencyService
    let action: () -> Void
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 156
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 108

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    IconCircle(icon: service.category.iconName, tint: service.category.color, size: 34)
                    Spacer()
                    if let distance = service.distanceDisplay {
                        Text(distance)
                            .font(.szScaled(10, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Text(service.name)
                    .font(.szHeadline(13))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(service.category.singularTitle)
                    .font(.szScaled(10, weight: .semibold))
                    .foregroundStyle(service.category.color)
            }
            .padding(11)
            .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.4), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct IncidentCompactCard: View {
    let incident: IncidentReport
    let distance: Double
    let action: () -> Void
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 190
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 108

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    TagPill(text: incident.category.shortTitle, color: incident.category.color)
                    Spacer()
                    Text(AppFormatters.distance(distance))
                        .font(.szScaled(10, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                Text(incident.title)
                    .font(.szHeadline(13))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(AppFormatters.timeAgo(incident.createdAt))
                    .font(.szScaled(10))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(11)
            .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.4), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}
