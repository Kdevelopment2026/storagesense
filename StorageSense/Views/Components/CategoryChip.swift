import SwiftUI

/// One category on Home: a glowing colour dot, the name, the byte total and
/// the item count — always all four, so the chart's colour is never the only
/// signal (CLAUDE.md, golden rule 9).
struct CategoryChip: View {
    let recommendation: RecommendationEngine.Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            HStack(spacing: StorageSenseTheme.Spacing.sm) {
                Circle()
                    .fill(StorageSenseTheme.color(for: recommendation.category))
                    .frame(width: 9, height: 9)
                    .shadow(color: StorageSenseTheme.color(for: recommendation.category).opacity(0.7), radius: 5)
                Text(recommendation.category.displayName)
                    .font(StorageSenseTheme.Font.caption)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            Text(ByteFormatter.string(from: recommendation.byteCount))
                .font(StorageSenseTheme.Font.stat)
                .foregroundStyle(StorageSenseTheme.textPrimary)
            Text("\(recommendation.assetCount.formatted()) items")
                .font(StorageSenseTheme.Font.caption)
                .foregroundStyle(StorageSenseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: StorageSenseTheme.minimumTapTarget, alignment: .leading)
        .surfaceCard(padding: 14)
        .contentShape(RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.chip))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recommendation.category.displayName), \(recommendation.assetCount) items, \(ByteFormatter.spoken(recommendation.byteCount))")
        .accessibilityHint("Opens the category for review")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack {
        ForEach(RecommendationEngine.rankedRecommendations(from: DemoData.totals()).prefix(2), id: \.category) {
            CategoryChip(recommendation: $0)
        }
    }
    .padding()
    .screenBackground()
}
