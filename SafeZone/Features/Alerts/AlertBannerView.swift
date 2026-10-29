import SwiftUI

struct AlertBannerOverlay: View {
    @ObservedObject var alertCenter: AlertCenter
    @ObservedObject var appState: AppState
    @State private var showDetails = false

    var body: some View {
        Group {
            if let banner = alertCenter.banner {
                AlertBannerView(
                    banner: banner,
                    onDetails: { showDetails = true },
                    onDismiss: { alertCenter.dismiss() }
                )
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
                .sheet(isPresented: $showDetails) {
                    AlertDetailSheet(banner: banner, appState: appState)
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: alertCenter.banner)
    }
}

struct AlertBannerView: View {
    let banner: AlertBanner
    var onDetails: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: banner.level.iconName)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.8))
                Text(banner.locationName)
                    .font(.szHeadline(16))
                    .foregroundStyle(.white)
                Text(banner.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)

                HStack(spacing: 14) {
                    Button("View Details", action: onDetails)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.18)))

                    Button("Dismiss", action: onDismiss)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.white.opacity(0.14)))
            }
            .accessibilityLabel("Dismiss alert")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.riskGradient(for: banner.level))
        )
        .shadow(color: banner.level.color.opacity(0.35), radius: 18, x: 0, y: 8)
        .accessibilityElement(children: .contain)
    }
}

struct AlertDetailSheet: View {
    let banner: AlertBanner
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        hero
                        messageCard
                        actions
                        disclaimer
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 26)
                }
            }
            .navigationTitle("Risk Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: banner.level.iconName)
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.white)
            Text(banner.level.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(banner.locationName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.riskGradient(for: banner.level))
        )
    }

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Situation Update")
                .font(.szHeadline(17))
            Text(banner.message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
                appState.container.alertCenter.dismiss()
                appState.openTab(.map)
            } label: {
                Label("View Emergency Map", systemImage: "map.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                dismiss()
                appState.container.alertCenter.dismiss()
                appState.openTab(.guide)
            } label: {
                Label("Open Offline Emergency Guide", systemImage: "book.closed.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var disclaimer: some View {
        InlineMessage(style: .info, message: AppConfig.dataDisclaimer)
    }
}
