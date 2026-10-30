import SwiftUI
import UIKit

struct EditProfileView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var contactName: String
    @State private var contactPhone: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case contactName
        case contactPhone
    }

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        let profile = appState.profile
        _displayName = State(initialValue: profile?.displayName ?? "")
        _contactName = State(initialValue: profile?.emergencyContactName ?? "")
        _contactPhone = State(initialValue: profile?.emergencyContactPhone ?? "")
    }

    private var profile: UserProfile? {
        appState.profile
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 14) {
                    avatarCard
                    detailsCard
                    emergencyContactCard
                    saveButton

                    if let errorMessage {
                        InlineMessage(style: .error, message: errorMessage)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var avatarCard: some View {
        VStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(Theme.aquaGradient)
                    .frame(width: 76, height: 76)
                Text(initials)
                    .font(.szScaled(25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: Theme.brandTeal.opacity(0.25), radius: 10, x: 0, y: 5)

            Text(profile?.email ?? "")
                .font(.szScaled(12))
                .foregroundStyle(Theme.textSecondary)
            TagPill(text: "Member since \(memberSince)", icon: "calendar", color: Theme.brandTeal)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Personal Details", subtitle: "This name appears on your reports")

            fieldLabel("Display Name")
            TextField("Your name", text: $displayName)
                .textContentType(.name)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .contactName }
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
                .background(fieldBackground)

            fieldLabel("Email")
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.szScaled(12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                Text(profile?.email ?? "—")
                    .font(.szScaled(14))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                TagPill(text: "Read-only", color: Theme.textTertiary)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(fieldBackground)
        }
        .cardStyle()
    }

    private var emergencyContactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Emergency Contact",
                subtitle: "Optional — someone we can show in an emergency"
            )

            fieldLabel("Contact Name")
            TextField("e.g. Amara Perera", text: $contactName)
                .textContentType(.name)
                .focused($focusedField, equals: .contactName)
                .submitLabel(.next)
                .onSubmit { focusedField = .contactPhone }
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
                .background(fieldBackground)

            fieldLabel("Contact Phone")
            TextField("e.g. +94 77 123 4567", text: $contactPhone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .focused($focusedField, equals: .contactPhone)
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
                .background(fieldBackground)
        }
        .cardStyle()
    }

    private var saveButton: some View {
        Button {
            focusedField = nil
            Task { await save() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isSaving ? "Saving…" : "Save Changes")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(Theme.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
            )
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.szScaled(11, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(Theme.textSecondary)
    }

    private var initials: String {
        let parts = displayName.split(separator: " ").prefix(2).compactMap(\.first)
        let value = String(parts).uppercased()
        return value.isEmpty ? (profile?.initials ?? "SZ") : value
    }

    private var memberSince: String {
        guard let createdAt = profile?.createdAt else { return "—" }
        return AppFormatters.shortDate.string(from: createdAt)
    }

    private func save() async {
        guard var updated = appState.profile else {
            errorMessage = "Your profile could not be loaded."
            return
        }
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter your name."
            return
        }

        isSaving = true
        defer { isSaving = false }

        updated.displayName = trimmedName
        updated.emergencyContactName = contactName.nilIfBlank
        updated.emergencyContactPhone = contactPhone.nilIfBlank

        do {
            try await appState.updateProfile(updated)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
