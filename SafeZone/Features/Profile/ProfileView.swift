import SwiftUI

struct ProfileView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: ProfileViewModel
    @ObservedObject private var settings: AppSettings
    @State private var showSignOutConfirmation = false
    @Environment(\.openURL) private var openURL

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _viewModel = StateObject(wrappedValue: ProfileViewModel(container: container, appState: appState))
        _settings = ObservedObject(wrappedValue: container.settings)
    }

    private var profile: UserProfile {
        appState.profile ?? .demo
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 14) {
                    profileHeader
                    statsCard

                    if let errorMessage = viewModel.errorMessage {
                        InlineMessage(style: .warning, message: errorMessage)
                    }

                    accountSection
                    securitySection
                    alertsSection
                    emergencyContactsSection
                    supportSection

                    if viewModel.isDemoMode {
                        demoCard
                    }

                    signOutButton
                    versionFooter
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.load()
        }
        .confirmationDialog(
            "Sign out of SafeZone?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again to receive alerts and view your saved locations.")
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.aquaGradient)
                    .frame(width: 66, height: 66)
                Text(profile.initials)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: Theme.brandTeal.opacity(0.25), radius: 10, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.displayName)
                    .font(.szTitle(22))
                    .foregroundStyle(Theme.textPrimary)
                Text(profile.email)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if viewModel.isDemoMode {
                        TagPill(text: "Demo Account", icon: "sparkles", color: Theme.brandTeal)
                    }
                    TagPill(text: "Protected", icon: "lock.shield.fill", color: Theme.success)
                }
            }

            Spacer(minLength: 4)

            NavigationLink {
                EditProfileView(container: container, appState: appState)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.brandTeal.opacity(0.1)))
            }
            .accessibilityLabel("Edit profile")
        }
        .cardStyle()
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat(value: "\(viewModel.savedLocationCount)", label: "Saved Places", icon: "mappin.and.ellipse")
            Divider().frame(height: 38)
            stat(value: "\(viewModel.monitoredLocationCount)", label: "Monitoring", icon: "location.circle.fill")
            Divider().frame(height: 38)
            stat(value: "\(viewModel.reportCount)", label: "My Reports", icon: "exclamationmark.bubble.fill")
        }
        .cardStyle(padding: 14)
    }

    private func stat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(title: "Account", subtitle: "Personal details and emergency contact")

            NavigationLink {
                EditProfileView(container: container, appState: appState)
            } label: {
                ProfileRow(
                    icon: "person.crop.circle.fill",
                    title: "Edit Profile",
                    subtitle: "Name, email and emergency contact",
                    tint: Theme.brandTeal
                ) {
                    chevron
                }
            }
            .buttonStyle(.plain)

            Divider()

            NavigationLink {
                SavedLocationsView(container: container, appState: appState)
            } label: {
                ProfileRow(
                    icon: "mappin.and.ellipse",
                    title: "Saved Locations",
                    subtitle: "\(viewModel.savedLocationCount) places • \(viewModel.monitoredLocationCount) monitored",
                    tint: Theme.brandSky
                ) {
                    chevron
                }
            }
            .buttonStyle(.plain)

            if let contactName = profile.emergencyContactName,
               let contactPhone = profile.emergencyContactPhone {
                Divider()
                ProfileRow(
                    icon: "phone.bubble.fill",
                    title: contactName,
                    subtitle: "Emergency contact • \(contactPhone)",
                    tint: Theme.success
                ) {
                    Button {
                        let digits = contactPhone.filter { $0.isNumber || $0 == "+" }
                        if let url = URL(string: "tel://\(digits)") {
                            openURL(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.success)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.success.opacity(0.12)))
                    }
                    .accessibilityLabel("Call emergency contact \(contactName)")
                }
            }
        }
        .cardStyle()
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Security", subtitle: "Protect access to your safety data")

            toggleRow(
                icon: "faceid",
                title: viewModel.biometricAvailability.kind.rawValue,
                subtitle: viewModel.biometricAvailability.isAvailable
                    ? "Unlock SafeZone with \(viewModel.biometricAvailability.kind.rawValue)"
                    : "Not available on this device",
                tint: Theme.brandTeal,
                isOn: faceIDBinding
            )
            .disabled(!viewModel.biometricAvailability.isAvailable || viewModel.isUpdatingBiometrics)

            if settings.faceIDEnabled {
                Divider()
                Button {
                    viewModel.lockNow()
                } label: {
                    ProfileRow(
                        icon: "lock.fill",
                        title: "Lock Now",
                        subtitle: "Require \(viewModel.biometricAvailability.kind.rawValue) to continue",
                        tint: Theme.riskMedium
                    ) {
                        chevron
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Alerts", subtitle: "Choose what SafeZone notifies you about")

            toggleRow(
                icon: "bell.badge.fill",
                title: "Push Notifications",
                subtitle: "Alerts, geofence entries and risk changes",
                tint: Theme.brandTeal,
                isOn: notificationsBinding
            )

            Divider()

            toggleRow(
                icon: "cloud.bolt.rain.fill",
                title: "Weather Alerts",
                subtitle: "Severe weather for saved locations",
                tint: Theme.brandSky,
                isOn: $settings.weatherAlerts
            )
            .disabled(!settings.notificationsEnabled)

            Divider()

            toggleRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Risk Level Changes",
                subtitle: "When a location moves to medium or high risk",
                tint: Theme.riskMedium,
                isOn: $settings.riskLevelAlerts
            )
            .disabled(!settings.notificationsEnabled)

            Divider()

            toggleRow(
                icon: "location.circle.fill",
                title: "Geofence Alerts",
                subtitle: "When you enter a monitored high-risk zone",
                tint: Theme.riskHigh,
                isOn: $settings.emergencyAlerts
            )
            .disabled(!settings.notificationsEnabled)
        }
        .cardStyle()
    }

    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Emergency Hotlines", subtitle: "Tap to call")

            ForEach(EmergencyContact.sriLankaHotlines.prefix(3)) { contact in
                Button {
                    if let url = contact.callURL {
                        openURL(url)
                    }
                } label: {
                    ProfileRow(
                        icon: contact.iconName,
                        title: contact.name,
                        subtitle: contact.subtitle,
                        tint: Theme.riskHigh
                    ) {
                        Text(contact.number)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.riskHigh)
                    }
                }
                .buttonStyle(.plain)

                if contact.id != EmergencyContact.sriLankaHotlines.prefix(3).last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(title: "Support", subtitle: "About SafeZone and how your data is handled")

            NavigationLink {
                AboutView()
            } label: {
                ProfileRow(
                    icon: "info.circle.fill",
                    title: "About SafeZone",
                    subtitle: viewModel.appVersion,
                    tint: Theme.brandTeal
                ) {
                    chevron
                }
            }
            .buttonStyle(.plain)

            Divider()

            ProfileRow(
                icon: "lock.doc.fill",
                title: "Privacy",
                subtitle: "Your data stays on this device",
                tint: Theme.success
            ) {
                TagPill(text: "On-device", color: Theme.success)
            }
        }
        .cardStyle()
    }

    private var demoCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
            VStack(alignment: .leading, spacing: 3) {
                Text("Demo Mode Active")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Weather data is simulated to match the prototype. Add an OpenWeatherMap API key to use live conditions.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Theme.brandTeal.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Theme.brandTeal.opacity(0.16), lineWidth: 0.8)
        )
    }

    private var signOutButton: some View {
        Button {
            showSignOutConfirmation = true
        } label: {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
        }
        .buttonStyle(SecondaryButtonStyle(tint: Theme.riskHigh))
        .padding(.top, 4)
    }

    private var versionFooter: some View {
        VStack(spacing: 3) {
            Text("SafeZone • \(viewModel.appVersion)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Text("Disaster alerts and emergency response for Sri Lanka")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.textTertiary)
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 11) {
            IconCircle(icon: icon, tint: tint, size: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.brandTeal)
        }
        .padding(.vertical, 3)
    }

    private var faceIDBinding: Binding<Bool> {
        Binding(
            get: { settings.faceIDEnabled },
            set: { newValue in
                Task { await viewModel.setFaceIDEnabled(newValue) }
            }
        )
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                Task { await viewModel.setNotificationsEnabled(newValue) }
            }
        )
    }
}

private struct ProfileRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let trailing: () -> Trailing

    init(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 11) {
            IconCircle(icon: icon, tint: tint, size: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            trailing()
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}
