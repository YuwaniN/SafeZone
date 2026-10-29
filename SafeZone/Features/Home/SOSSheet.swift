import SwiftUI

struct SOSSheet: View {
    let container: AppContainer
    @ObservedObject var appState: AppState

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        emergencyContactSection
                        hotlinesSection
                        actions
                        disclaimer
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 26)
                }
            }
            .navigationTitle("Emergency SOS")
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

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x991B1B), Color(hex: 0xEF4444)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                Text("SOS")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text("Help is one tap away")
                .font(.szTitle(24))
                .foregroundStyle(Theme.textPrimary)
            Text("If life is in immediate danger, call 119. SafeZone hotlines connect you to Sri Lankan emergency services.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var emergencyContactSection: some View {
        if let profile = appState.profile,
           let name = profile.emergencyContactName,
           let phone = profile.emergencyContactPhone {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Your Emergency Contact")
                HStack(spacing: 12) {
                    IconCircle(icon: "person.crop.circle.badge.checkmark", tint: Theme.brandTeal, size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.szHeadline(15))
                        Text(phone)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button {
                        call(phone)
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.riskLow))
                    }
                    .accessibilityLabel("Call \(name)")
                }
            }
            .cardStyle(padding: 16)
        }
    }

    private var hotlinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Emergency Hotlines", subtitle: "Sri Lanka")

            VStack(spacing: 0) {
                ForEach(Array(EmergencyContact.sriLankaHotlines.enumerated()), id: \.element.id) { index, contact in
                    Button {
                        call(contact.number)
                    } label: {
                        HStack(spacing: 12) {
                            IconCircle(icon: contact.iconName, tint: Theme.riskHigh, size: 36)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(contact.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(contact.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text(contact.number)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.riskHigh)
                            Image(systemName: "phone.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.riskHigh)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call \(contact.name) on \(contact.number)")

                    if index < EmergencyContact.sriLankaHotlines.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .cardStyle(padding: 14)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
                appState.openTab(.map)
            } label: {
                Label("Open Emergency Map", systemImage: "map.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                dismiss()
                appState.openTab(.guide)
            } label: {
                Label("Open Offline Emergency Guide", systemImage: "book.closed.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var disclaimer: some View {
        Text("SafeZone is not an emergency dispatch service. Hotline numbers are provided for convenience and may change.")
            .font(.system(size: 11))
            .foregroundStyle(Theme.textTertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }

    private func call(_ number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }
        openURL(url)
    }
}
