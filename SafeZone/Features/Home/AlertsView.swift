import SwiftUI

struct AlertsView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState

    @State private var alerts: [AlertRecord] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 12) {
                    if alerts.isEmpty {
                        EmptyStateView(
                            icon: "bell.slash.fill",
                            title: "No alerts yet",
                            message: "Risk changes and geofence events for your saved locations will appear here."
                        )
                        .padding(.top, 20)
                    } else {
                        ForEach(alerts) { alert in
                            AlertRowCard(alert: alert)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            loadAlerts()
            appState.markAlertsRead()
            loadAlerts()
        }
    }

    private func loadAlerts() {
        guard let ownerID = appState.profile?.id else { return }
        alerts = (try? container.alertRepository.fetchRecent(ownerID: ownerID, limit: 50)) ?? []
    }
}
