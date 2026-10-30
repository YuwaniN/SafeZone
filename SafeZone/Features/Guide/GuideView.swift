import SwiftUI

struct GuideView: View {
    @StateObject private var viewModel: GuideViewModel
    @ScaledMetric(relativeTo: .body) private var hotlineCardWidth: CGFloat = 252
    @Environment(\.openURL) private var openURL

    init(container: AppContainer) {
        _viewModel = StateObject(wrappedValue: GuideViewModel(container: container))
    }

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    searchBar
                    hotlines
                    topicsSection
                    offlineNote
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Emergency Guide")
                    .font(.szTitle(26))
                    .foregroundStyle(Theme.textPrimary)
                Text("Step-by-step help that works without a connection")
                    .font(.szScaled(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            TagPill(text: "Offline", icon: "arrow.down.circle.fill", color: Theme.success)
                .padding(.top, 4)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.szScaled(14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField("Search flood, fire, first aid…", text: $viewModel.searchText)
                .font(.szScaled(14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
        )
    }

    private var hotlines: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Emergency Hotlines", subtitle: "Tap to call from anywhere in Sri Lanka")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(viewModel.contacts.prefix(6)) { contact in
                        Button {
                            if let url = contact.callURL {
                                openURL(url)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                IconCircle(icon: contact.iconName, tint: Theme.riskHigh, size: 36)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(contact.name)
                                        .font(.szScaled(12, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(contact.number)
                                        .font(.szScaled(15, weight: .bold, design: .rounded))
                                        .foregroundStyle(Theme.riskHigh)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "phone.fill")
                                    .font(.szScaled(12, weight: .semibold))
                                    .foregroundStyle(Theme.riskHigh)
                            }
                            .padding(11)
                            .frame(width: hotlineCardWidth, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(Theme.riskHigh.opacity(0.15), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Call \(contact.name) on \(contact.number)")
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: viewModel.isSearching ? "Search Results" : "Safety Guides",
                subtitle: viewModel.isSearching
                    ? "\(viewModel.topics.count) topics match your search"
                    : "\(viewModel.topics.count) essential guides available offline"
            )

            if viewModel.topics.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    title: "No guides found",
                    message: "Try a different keyword such as flood, fire, or first aid.",
                    actionTitle: "Clear Search"
                ) {
                    viewModel.searchText = ""
                }
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 160), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(viewModel.topics) { topic in
                        NavigationLink {
                            GuideTopicView(topic: topic)
                        } label: {
                            GuideTopicCard(topic: topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var offlineNote: some View {
        HStack(spacing: 9) {
            Image(systemName: "wifi.slash")
                .font(.szScaled(13, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
            Text("All guides are bundled with the app and remain available during outages.")
                .font(.szScaled(11))
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.brandTeal.opacity(0.07))
        )
    }
}

private struct GuideTopicCard: View {
    let topic: GuideTopic

    private var accent: Color {
        Color(hexString: topic.accentHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                IconCircle(icon: topic.iconName, tint: accent, size: 40)
                Spacer()
                if let badge = topic.badge {
                    TagPill(text: badge, color: accent)
                }
            }

            Text(topic.title)
                .font(.szHeadline(16))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.leading)

            Text(topic.subtitle)
                .font(.szScaled(11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Image(systemName: "list.bullet")
                Text("\(topic.sections.count) steps")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.szScaled(10, weight: .semibold))
            .foregroundStyle(accent)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accent.opacity(0.16), lineWidth: 0.9)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title). \(topic.subtitle). \(topic.sections.count) sections.")
    }
}
