import SwiftUI

struct RootView: View {
    let container: AppContainer
    @StateObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer) {
        self.container = container
        _appState = StateObject(wrappedValue: AppState(container: container))
    }

    var body: some View {
        ZStack {
            switch appState.flow {
            case .onboarding:
                OnboardingView(container: container, appState: appState)
                    .transition(.opacity)
            case .biometricSetup:
                FaceIDSetupView(container: container, appState: appState)
                    .transition(.opacity)
            case .authentication:
                AuthFlowView(container: container, appState: appState)
                    .transition(.opacity)
            case .locked:
                AppLockView(container: container, appState: appState)
                    .transition(.opacity)
            case .main:
                MainTabView(container: container, appState: appState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.flow)
        .overlay(alignment: .top) {
            if appState.flow == .main {
                AlertBannerOverlay(alertCenter: container.alertCenter, appState: appState)
            }
        }
        .task {
            await appState.bootstrap()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
        .onReceive(NotificationCenter.default.publisher(for: .safeZoneNotificationTapped)) { notification in
            if let userInfo = notification.object as? [AnyHashable: Any] {
                appState.handleNotificationTap(userInfo)
            }
        }
        .tint(Theme.brandTeal)
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            container.settings.markBackgrounded()
        case .active:
            if appState.flow == .main,
               container.settings.faceIDEnabled,
               let lastBackground = container.settings.lastBackgroundDate,
               Date().timeIntervalSince(lastBackground) > 15 {
                appState.lock()
            }
            Task { await container.notificationService.refreshAuthorizationStatus() }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
