import SwiftUI

struct OnboardingView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState

    @State private var currentPage = 0
    @State private var animateGlow = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "cloud.bolt.rain.fill",
            title: "Real-Time Weather Risk Alerts",
            subtitle: "Get instant notifications about rainfall, wind, floods and storm warnings for your area in Sri Lanka.",
            accent: Theme.brandAqua
        ),
        OnboardingPage(
            icon: "mappin.and.ellipse",
            title: "Save Your Important Locations",
            subtitle: "Monitor risk levels for Home, Work and other locations. Get personalised alerts for places that matter to you.",
            accent: Color(hex: 0x60A5FA)
        ),
        OnboardingPage(
            icon: "cross.case.fill",
            title: "Emergency Services at Hand",
            subtitle: "Find nearby hospitals, police stations, fire stations and shelters on an interactive map with directions.",
            accent: Color(hex: 0x34D399)
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Community-Powered Reports",
            subtitle: "Report and view real-time hazards like flooded roads, fallen trees and road blockages shared by people near you.",
            accent: Color(hex: 0xFBBF24)
        )
    ]

    var body: some View {
        ZStack {
            Theme.heroGradient
                .ignoresSafeArea()

            decorativeBackground

            VStack(spacing: 0) {
                header

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                footer
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.szScaled(19, weight: .bold))
                    .foregroundStyle(Theme.brandAqua)
                Text("SafeZone")
                    .font(.szScaled(21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("SafeZone")

            Spacer()

            Button("Skip") {
                appState.completeOnboarding()
            }
            .font(.szScaled(15, weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
            .accessibilityHint("Skip onboarding and continue to sign in")
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.14))
                    .frame(width: 188, height: 188)
                Circle()
                    .strokeBorder(page.accent.opacity(0.22), lineWidth: 1)
                    .frame(width: 236, height: 236)
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 132, height: 132)
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
                Image(systemName: page.icon)
                    .font(.szScaled(58, weight: .semibold))
                    .foregroundStyle(page.accent)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.szScaled(30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(page.subtitle)
                    .font(.szScaled(16))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.subtitle)")
    }

    private var footer: some View {
        VStack(spacing: 22) {
            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Theme.brandAqua : .white.opacity(0.25))
                        .frame(width: index == currentPage ? 24 : 7, height: 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    appState.completeOnboarding()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    Image(systemName: "arrow.right")
                        .font(.szScaled(14, weight: .bold))
                }
                .font(.szScaled(17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.brandNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(.white)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .accessibilityHint(currentPage == pages.count - 1 ? "Finish onboarding" : "Show next introduction screen")
        }
        .padding(.bottom, 30)
    }

    private var decorativeBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Theme.brandAqua.opacity(0.16))
                    .frame(width: 360, height: 360)
                    .blur(radius: 40)
                    .offset(x: geometry.size.width * 0.38, y: -geometry.size.height * 0.32)
                    .scaleEffect(animateGlow ? 1.15 : 0.9)
                Circle()
                    .fill(Theme.brandSky.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 50)
                    .offset(x: -geometry.size.width * 0.42, y: geometry.size.height * 0.30)
                    .scaleEffect(animateGlow ? 0.9 : 1.12)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
}
