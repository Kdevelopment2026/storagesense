import SwiftUI

/// Three short pages on first launch, framing the app as a diagnostic (see
/// what's there first) rather than a cleaner. Scope is always "Photos
/// library" — never the whole phone (CLAUDE.md, golden rule 1).
struct OnboardingView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "See what's filling your Photos library",
            detail: "StorageSense scans your photos and videos on your phone and explains, in plain language, where the space is going.",
            icon: "chart.pie",
            color: StorageSenseTheme.accent
        ),
        OnboardingPage(
            title: "Biggest win first",
            detail: "Categories are ranked by how much space reviewing them would recover, so you start with the one that matters most.",
            icon: "sparkles",
            color: StorageSenseTheme.caution
        ),
        OnboardingPage(
            title: "Every decision stays yours",
            detail: "Nothing is deleted automatically. You review each selection, and anything you remove sits in Recently Deleted for 30 days.",
            icon: "checkmark.shield",
            color: StorageSenseTheme.success
        ),
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: StorageSenseTheme.Spacing.lg) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    pageView(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: StorageSenseTheme.Spacing.sm) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? StorageSenseTheme.accent : StorageSenseTheme.ringTrack)
                        .frame(width: index == page ? 24 : 8, height: 6)
                }
            }
            .animation(StorageSenseTheme.animation(reduceMotion: reduceMotion), value: page)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(page + 1) of \(pages.count)")

            VStack(spacing: StorageSenseTheme.Spacing.sm) {
                Button(isLastPage ? "Get started" : "Continue") {
                    if isLastPage {
                        onFinished()
                    } else {
                        withAnimation(StorageSenseTheme.animation(reduceMotion: reduceMotion)) { page += 1 }
                    }
                }
                .buttonStyle(.primary)

                if !isLastPage {
                    Button("Skip") { onFinished() }
                        .font(StorageSenseTheme.Font.secondary)
                        .foregroundStyle(StorageSenseTheme.textSecondary)
                        .frame(minHeight: StorageSenseTheme.minimumTapTarget)
                }
            }
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            .padding(.bottom, StorageSenseTheme.Spacing.md)
        }
        .screenBackground()
    }

    private func pageView(_ item: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card, style: .continuous)
                    .fill(StorageSenseTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card, style: .continuous).strokeBorder(StorageSenseTheme.surfaceBorder, lineWidth: 1))
                Circle()
                    .fill(RadialGradient(colors: [item.color.opacity(0.35), .clear], center: .center, startRadius: 10, endRadius: 110))
                Image(systemName: item.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(item.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .accessibilityHidden(true)

            Text(item.title)
                .font(StorageSenseTheme.Font.display)
                .foregroundStyle(StorageSenseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.detail)
                .font(StorageSenseTheme.Font.body)
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, StorageSenseTheme.Spacing.lg)
        .padding(.top, StorageSenseTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingPage {
    let title: String
    let detail: String
    let icon: String
    let color: Color
}

#Preview {
    OnboardingView(onFinished: {})
}
