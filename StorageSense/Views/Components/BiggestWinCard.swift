import SwiftUI

/// The single clearest recommendation, surfaced on Home. Copy stays calm and
/// factual (CLAUDE.md, golden rule 10) and the card is never gated behind
/// ProStatus (golden rule 2).
struct BiggestWinCard: View {
    let recommendation: RecommendationEngine.Recommendation
    let shareOfLibrary: Double
    var action: () -> Void

    private var shareText: String? {
        guard shareOfLibrary > 0.005 else { return nil }
        return "\(shareOfLibrary.formatted(.percent.precision(.fractionLength(0)))) of your library"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            Label("Biggest win", systemImage: "sparkles")
                .font(StorageSenseTheme.Font.eyebrow)
                .foregroundStyle(StorageSenseTheme.accent)

            Text(recommendation.headline)
                .font(StorageSenseTheme.Font.title)
                .foregroundStyle(StorageSenseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text([shareText, recommendation.category.winHint].compactMap { $0 }.joined(separator: ". "))
                .font(StorageSenseTheme.Font.secondary)
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Text("Review \(recommendation.category.displayName.lowercased())")
            }
            .buttonStyle(.primary)
            .padding(.top, StorageSenseTheme.Spacing.xs)
        }
        .padding(StorageSenseTheme.Spacing.md + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StorageSenseTheme.winGradient, in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(StorageSenseTheme.accent.opacity(0.35), lineWidth: 1)
        )
    }
}

#Preview {
    let totals = DemoData.totals()
    let top = RecommendationEngine.topRecommendation(from: totals)!
    return BiggestWinCard(recommendation: top, shareOfLibrary: 0.459, action: {})
        .padding()
        .screenBackground()
}
