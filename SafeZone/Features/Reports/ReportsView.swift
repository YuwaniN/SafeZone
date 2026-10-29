import SwiftUI
import UIKit

struct ReportsView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: ReportsViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    @State private var showCreateReport = false

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _viewModel = StateObject(wrappedValue: ReportsViewModel(container: container, appState: appState))
        _networkMonitor = ObservedObject(wrappedValue: container.networkMonitor)
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    searchBar
                    filterChips

                    if !networkMonitor.isConnected {
                        OfflineBanner()
                    }

                    if let errorMessage = viewModel.errorMessage {
                        InlineMessage(style: .error, message: errorMessage, actionTitle: "Retry") {
                            Task { await viewModel.load() }
                        }
                    }

                    if viewModel.isLoading {
                        LoadingCard(message: "Loading community reports…")
                    } else if viewModel.filteredReports.isEmpty {
                        EmptyStateView(
                            icon: "exclamationmark.bubble",
                            title: "No reports yet",
                            message: viewModel.searchText.isEmpty
                                ? "Be the first to share a hazard with your community."
                                : "No reports match your search. Try another keyword.",
                            actionTitle: "Create a Report"
                        ) {
                            showCreateReport = true
                        }
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.filteredReports) { report in
                                NavigationLink {
                                    ReportDetailView(container: container, appState: appState, report: report)
                                        .onDisappear {
                                            Task { await viewModel.load() }
                                        }
                                } label: {
                                    ReportCard(
                                        report: report,
                                        distance: viewModel.distance(for: report)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await viewModel.load()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showCreateReport, onDismiss: {
            Task { await viewModel.load() }
        }) {
            CreateReportView(container: container, appState: appState)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Community Reports")
                    .font(.szTitle(26))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(viewModel.reports.count) reports • \(viewModel.verifiedCount) verified near you")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                showCreateReport = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.aquaGradient))
                    .shadow(color: Theme.brandTeal.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .accessibilityLabel("Create a community report")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField("Search reports by title, road, or area", text: $viewModel.searchText)
                .font(.system(size: 14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
        )
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(IncidentFilter.allCases) { filter in
                    FilterChip(
                        title: filterTitle(filter),
                        icon: filterIcon(filter),
                        isSelected: viewModel.filter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel.filter = filter
                        }
                    }
                }
            }
        }
    }

    private func filterTitle(_ filter: IncidentFilter) -> String {
        switch filter {
        case .all: return "All Reports"
        case .nearby: return "Nearby (\(viewModel.nearbyCount))"
        case .verified: return "Verified"
        }
    }

    private func filterIcon(_ filter: IncidentFilter) -> String {
        switch filter {
        case .all: return "square.grid.2x2.fill"
        case .nearby: return "location.fill"
        case .verified: return "checkmark.seal.fill"
        }
    }
}

struct ReportCard: View {
    let report: IncidentReport
    let distance: Double

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let photoData = report.photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(report.category.color.opacity(0.12))
                    Image(systemName: report.category.iconName)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(report.category.color)
                }
                .frame(width: 64, height: 78)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    TagPill(text: report.category.shortTitle, color: report.category.color)
                    if report.isVerified {
                        TagPill(text: "Verified", icon: "checkmark.seal.fill", color: Theme.success)
                    }
                    if report.isMine {
                        TagPill(text: "Yours", icon: "person.fill", color: Theme.brandTeal)
                    }
                    Spacer()
                }

                Text(report.title)
                    .font(.szHeadline(15))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(report.address)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(AppFormatters.timeAgo(report.createdAt), systemImage: "clock")
                    Label(AppFormatters.distance(distance), systemImage: "location")
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("\(report.upvotes)")
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.35), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(report.title), \(report.category.title), \(AppFormatters.timeAgo(report.createdAt)), \(report.upvotes) upvotes")
    }
}
