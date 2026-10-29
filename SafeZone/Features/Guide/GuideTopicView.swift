import SwiftUI

struct GuideTopicView: View {
    let topic: GuideTopic
    @Environment(\.openURL) private var openURL

    private var accent: Color {
        Color(hexString: topic.accentHex)
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(spacing: 14) {
                    hero

                    ForEach(Array(topic.sections.enumerated()), id: \.element.id) { index, section in
                        sectionCard(section, index: index)
                    }

                    if !topic.contacts.isEmpty {
                        contactsCard
                    }

                    offlineFooter
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [accent, accent.opacity(0.62)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: 230, y: -60)
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 110, height: 110)
                .offset(x: 120, y: 70)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: topic.iconName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(.white.opacity(0.18)))
                    Spacer()
                    if let badge = topic.badge {
                        Text(badge.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.white.opacity(0.2)))
                    }
                }

                Text(topic.title)
                    .font(.szTitle(27))
                    .foregroundStyle(.white)

                Text(topic.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .frame(minHeight: 190)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: accent.opacity(0.25), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }

    private func sectionCard(_ section: GuideSection, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accent.opacity(0.12)))

                Text(section.title)
                    .font(.szHeadline(18))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(section.body)
                .font(.szBody(14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if !section.steps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(section.steps.enumerated()), id: \.offset) { stepIndex, step in
                        HStack(alignment: .top, spacing: 9) {
                            Text("\(stepIndex + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(accent)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(accent.opacity(0.12)))
                            Text(step)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 1)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .cardStyle()
    }

    private var contactsCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Who to Call", subtitle: "Tap a number to call")

            ForEach(topic.contacts) { contact in
                Button {
                    if let url = contact.callURL {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 11) {
                        IconCircle(icon: contact.iconName, tint: accent, size: 38)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(contact.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(contact.subtitle)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(contact.number)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(accent)
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Call \(contact.name) on \(contact.number)")

                if contact.id != topic.contacts.last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var offlineFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.success)
            Text("This guide is stored on your device and works offline.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Theme.success.opacity(0.08))
        )
    }
}
