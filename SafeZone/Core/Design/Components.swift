import SwiftUI

struct ScreenBackground<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            content
        }
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.cardPadding
    var radius: CGFloat = Theme.cornerRadius

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.35), lineWidth: 0.7)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = Theme.cardPadding, radius: CGFloat = Theme.cornerRadius) -> some View {
        modifier(CardModifier(padding: padding, radius: radius))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.brandTeal
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.szHeadline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isDestructive ? AnyShapeStyle(Theme.riskHigh) : AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            )
            .shadow(color: (isDestructive ? Theme.riskHigh : tint).opacity(0.28), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.brandTeal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.szHeadline(16))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.11))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct RiskBadge: View {
    let level: RiskLevel
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: level.iconName)
                .font(.system(size: compact ? 9 : 11, weight: .bold))
            Text(compact ? level.shortTitle : level.title)
                .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                .textCase(compact ? .uppercase : nil)
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(
            Capsule().fill(level.softColor)
        )
        .overlay(
            Capsule().strokeBorder(level.color.opacity(0.25), lineWidth: 0.8)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(level.accessibilityDescription)
    }
}

struct RiskGauge: View {
    let level: RiskLevel
    let score: Int
    var size: CGFloat = 108

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        min(max(Double(score) / 100.0, 0.04), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(level.color.opacity(0.16), lineWidth: 10)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(colors: level.gradientColors, center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(score)")
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(level.color)
                    .contentTransition(.numericText())
                Text("/ 100")
                    .font(.system(size: size * 0.11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: score) { _, _ in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Risk score \(score) out of 100, \(level.title)")
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.szHeadline(19))
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct WeatherMetric: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = Theme.brandTeal
    var light = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(light ? Color.white.opacity(0.9) : tint)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(light ? .white : Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(light ? Color.white.opacity(0.7) : Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(Theme.aquaGradient) : AnyShapeStyle(Theme.surface))
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.clear : Theme.separator.opacity(0.5),
                    lineWidth: 0.8
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Theme.brandTeal)
                .frame(width: 76, height: 76)
                .background(Circle().fill(Theme.brandTeal.opacity(0.12)))
                .accessibilityHidden(true)
            Text(title)
                .font(.szHeadline(18))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 240)
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .accessibilityElement(children: .contain)
    }
}

struct InlineMessage: View {
    enum Style {
        case error
        case info
        case success
        case warning

        var icon: String {
            switch self {
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .error: return Theme.riskHigh
            case .info: return Theme.brandTeal
            case .success: return Theme.success
            case .warning: return Theme.warning
            }
        }
    }

    let style: Style
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(style.color)
                .accessibilityHidden(true)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(style.color)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(style.color.opacity(0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style.color.opacity(0.18), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
    }
}

struct OfflineBanner: View {
    var message = "You're offline. Showing saved data."

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12, weight: .bold))
            Text(message)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Theme.warning.opacity(0.14))
        )
        .overlay(Capsule().strokeBorder(Theme.warning.opacity(0.3), lineWidth: 0.8))
        .accessibilityElement(children: .combine)
    }
}

struct TagPill: View {
    let text: String
    var icon: String?
    var color: Color = Theme.brandTeal

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.12)))
    }
}

struct IconCircle: View {
    let icon: String
    var tint: Color = Theme.brandTeal
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(Circle().fill(tint.opacity(0.12)))
            .accessibilityHidden(true)
    }
}

struct LoadingCard: View {
    var message = "Loading…"

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Theme.brandTeal)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(16)
        .cardStyle(padding: 0)
        .accessibilityElement(children: .combine)
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryTitle = "Try Again"
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Theme.riskMedium)
            Text(title)
                .font(.szHeadline(17))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button(retryTitle, action: retry)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 220)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct DividerLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Theme.separator.opacity(0.6))
                .frame(height: 0.8)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .fixedSize()
            Rectangle()
                .fill(Theme.separator.opacity(0.6))
                .frame(height: 0.8)
        }
        .accessibilityHidden(true)
    }
}
