import MapKit
import SwiftUI
import UIKit

struct ReportDetailView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @State private var report: IncidentReport
    @State private var showFlagDialog = false
    @State private var showDeleteDialog = false
    @State private var actionMessage: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    init(container: AppContainer, appState: AppState, report: IncidentReport) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _report = State(initialValue: report)
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 14) {
                    hero
                    summaryCard
                    detailsCard
                    locationCard
                    actionsCard

                    if report.isFlagged {
                        InlineMessage(
                            style: .warning,
                            message: "This report has been flagged for review by the SafeZone community."
                        )
                    }

                    if let actionMessage {
                        InlineMessage(style: .success, message: actionMessage)
                    }

                    Text("Community reports are user-submitted. Verify conditions before travelling and follow official guidance during an emergency.")
                        .font(.szScaled(11))
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share report")
            }
        }
        .task {
            refresh()
        }
        .confirmationDialog(
            "Flag this report?",
            isPresented: $showFlagDialog,
            titleVisibility: .visible
        ) {
            Button("Flag as Misleading", role: .destructive) {
                flag()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Flagged reports are reviewed before they remain visible to the community.")
        }
        .confirmationDialog(
            "Delete this report?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Report", role: .destructive) {
                delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your report from the community map.")
        }
    }

    private var hero: some View {
        Group {
            if let photoData = report.photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [report.category.color.opacity(0.92), report.category.color.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 190, height: 190)
                        .offset(x: 110, y: -55)
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 120, height: 120)
                        .offset(x: -120, y: 60)
                    Image(systemName: report.category.iconName)
                        .font(.szScaled(52, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(height: 180)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 6) {
                Image(systemName: report.category.iconName)
                Text(report.category.title)
            }
            .font(.szScaled(11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(.black.opacity(0.32)))
            .padding(12)
        }
        .accessibilityLabel("\(report.category.title) report image")
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                TagPill(text: report.category.shortTitle, color: report.category.color)
                if report.isVerified {
                    TagPill(text: "Verified", icon: "checkmark.seal.fill", color: Theme.success)
                } else {
                    TagPill(text: "Unverified", icon: "clock.fill", color: Theme.warning)
                }
                if report.isMine {
                    TagPill(text: "Your Report", icon: "person.fill", color: Theme.brandTeal)
                }
                Spacer()
            }

            Text(report.title)
                .font(.szTitle(24))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(report.category.color.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Text(authorInitials)
                        .font(.szScaled(12, weight: .bold, design: .rounded))
                        .foregroundStyle(report.category.color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(report.authorName)
                        .font(.szScaled(13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(AppFormatters.timeAgo(report.createdAt))
                        .font(.szScaled(11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("\(report.upvotes)")
                }
                .font(.szScaled(12, weight: .bold))
                .foregroundStyle(Theme.brandTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.brandTeal.opacity(0.1)))
            }
        }
        .cardStyle()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(title: "What happened", subtitle: "Reported by a community member")
            Text(report.details)
                .font(.szBody(15))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Location", subtitle: report.address)

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: report.latitude, longitude: report.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            ) {
                Marker(report.title, coordinate: CLLocationCoordinate2D(latitude: report.latitude, longitude: report.longitude))
                    .tint(report.category.color)
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityLabel("Map showing the report location at \(report.address)")

            Button {
                if let url = mapsURL {
                    openURL(url)
                }
            } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle()
    }

    private var actionsCard: some View {
        VStack(spacing: 9) {
            Button {
                upvote()
            } label: {
                Label("Helpful • \(report.upvotes)", systemImage: "hand.thumbsup.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            if report.isMine {
                Button {
                    showDeleteDialog = true
                } label: {
                    Label("Delete Report", systemImage: "trash.fill")
                }
                .buttonStyle(SecondaryButtonStyle(tint: Theme.riskHigh))
            } else {
                Button {
                    showFlagDialog = true
                } label: {
                    Label("Flag as Misleading", systemImage: "flag.fill")
                }
                .buttonStyle(SecondaryButtonStyle(tint: Theme.warning))
            }
        }
        .cardStyle()
    }

    private var authorInitials: String {
        let parts = report.authorName.split(separator: " ").prefix(2).compactMap(\.first)
        let initials = String(parts).uppercased()
        return initials.isEmpty ? "SZ" : initials
    }

    private var mapsURL: URL? {
        URL(string: "http://maps.apple.com/?daddr=\(report.latitude),\(report.longitude)&dirflg=d")
    }

    private var shareText: String {
        "\(report.title) — \(report.category.title)\n\(report.address)\n\n\(report.details)\n\nShared from SafeZone."
    }

    private func refresh() {
        if let latest = try? container.incidentRepository.fetch(id: report.id) {
            report = latest
        }
    }

    private func upvote() {
        do {
            try container.incidentRepository.upvote(id: report.id)
            refresh()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            actionMessage = "Thanks — your upvote helps verify this report."
        } catch {
            actionMessage = nil
        }
    }

    private func flag() {
        do {
            try container.incidentRepository.flag(id: report.id)
            refresh()
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            actionMessage = "Report flagged. Thank you for helping keep the community informed."
        } catch {
            actionMessage = nil
        }
    }

    private func delete() {
        do {
            try container.incidentRepository.delete(id: report.id)
            dismiss()
        } catch {
            actionMessage = "The report could not be deleted. Please try again."
        }
    }
}
