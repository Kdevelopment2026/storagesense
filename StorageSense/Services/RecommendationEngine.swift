import Foundation

/// Ranks categories by recoverable space and produces the "biggest win"
/// copy shown on Home. Pure and dependency-free so it's fully unit-testable
/// without touching PhotoKit (see StorageSenseTests).
enum RecommendationEngine {

    struct Recommendation {
        var category: PhotoCategory
        var byteCount: Int64
        var assetCount: Int
        var headline: String
    }

    /// Returns categories ordered from biggest recoverable win to smallest.
    /// Categories with zero assets are excluded.
    static func rankedRecommendations(from totals: [CategoryTotal]) -> [Recommendation] {
        totals
            .filter { $0.assetCount > 0 }
            .sorted { $0.byteCount > $1.byteCount }
            .map { total in
                Recommendation(
                    category: total.category,
                    byteCount: total.byteCount,
                    assetCount: total.assetCount,
                    headline: headline(for: total)
                )
            }
    }

    /// The single top recommendation surfaced on Home, or `nil` for an empty
    /// library.
    static func topRecommendation(from totals: [CategoryTotal]) -> Recommendation? {
        rankedRecommendations(from: totals).first
    }

    private static func headline(for total: CategoryTotal) -> String {
        let size = ByteFormatter.string(from: total.byteCount)
        let itemWord = total.assetCount == 1 ? "item" : "items"
        return "\(total.category.displayName): \(total.assetCount) \(itemWord), \(size)"
    }
}

/// A single shared byte-formatting helper so every screen renders sizes
/// identically.
enum ByteFormatter {
    static func string(from byteCount: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }
}
