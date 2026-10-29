import SwiftUI

struct MainTabView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .onAppear {
            Task { await appState.requestNotificationPermissionIfNeeded() }
            appState.refreshUnreadBadge()
        }
    }

    private var compactLayout: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                HomeView(container: container, appState: appState)
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.iconName)
            }
            .tag(AppTab.home)

            NavigationStack {
                EmergencyMapView(container: container, appState: appState)
            }
            .tabItem {
                Label(AppTab.map.title, systemImage: AppTab.map.iconName)
            }
            .tag(AppTab.map)

            NavigationStack {
                ReportsView(container: container, appState: appState)
            }
            .tabItem {
                Label(AppTab.reports.title, systemImage: AppTab.reports.iconName)
            }
            .tag(AppTab.reports)

            NavigationStack {
                GuideView(container: container)
            }
            .tabItem {
                Label(AppTab.guide.title, systemImage: AppTab.guide.iconName)
            }
            .tag(AppTab.guide)

            NavigationStack {
                ProfileView(container: container, appState: appState)
            }
            .tabItem {
                Label(AppTab.profile.title, systemImage: AppTab.profile.iconName)
            }
            .tag(AppTab.profile)
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List(
                selection: Binding(
                    get: { appState.selectedTab },
                    set: { if let tab = $0 { appState.selectedTab = tab } }
                )
            ) {
                Section {
                    ForEach(AppTab.allCases) { tab in
                        Label(tab.title, systemImage: tab.iconName)
                            .tag(tab)
                    }
                } header: {
                    Text("SafeZone")
                        .font(.szHeadline(13))
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("SafeZone")
            .safeAreaInset(edge: .bottom) {
                if AppConfig.isDemoMode {
                    Label("Demo Data", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.bottom, 10)
                }
            }
        } detail: {
            NavigationStack {
                detailContent
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedTab {
        case .home:
            HomeView(container: container, appState: appState)
        case .map:
            EmergencyMapView(container: container, appState: appState)
        case .reports:
            ReportsView(container: container, appState: appState)
        case .guide:
            GuideView(container: container)
        case .profile:
            ProfileView(container: container, appState: appState)
        }
    }
}
