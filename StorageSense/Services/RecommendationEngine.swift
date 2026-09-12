import Foundation

/// Ranks categories by recoverable space and produces the "biggest win"
/// copy shown on Home. Pure and dependency-free so it's fully unit-testable
/// without touching PhotoKit (see StorageSenseTests).
enum RecommendationEngine {

    struct Recommendation: Equatable {
        var category: PhotoCategory
        var byteCount: Int64
        var assetCount: Int
        var headline: String
    }

    /// Returns categories ordered from biggest recoverable win to smallest.
    /// Categories with zero assets are excluded; ties are broken by asset
    /// count (more items = quicker win) and then by the fixed v1 display
    /// order so the result is stable.
    static func rankedRecommendations(from totals: [CategoryTotal]) -> [Recommendation] {
        totals
            .filter { $0.assetCount > 0 && PhotoCategory.v1Cases.contains($0.category) }
            .sorted { lhs, rhs in
                if lhs.byteCount != rhs.byteCount { return lhs.byteCount > rhs.byteCount }
                if lhs.assetCount != rhs.assetCount { return lhs.assetCount > rhs.assetCount }
                return displayIndex(lhs.category) < displayIndex(rhs.category)
            }
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

    /// What fraction of the whole library one category accounts for, 0…1.
    static func share(of category: PhotoCategory, in totals: [CategoryTotal]) -> Double {
        let total = totals.reduce(Int64(0)) { $0 + $1.byteCount }
        guard total > 0, let match = totals.first(where: { $0.category == category }) else { return 0 }
        return Double(match.byteCount) / Double(total)
    }

    private static func headline(for total: CategoryTotal) -> String {
        let size = ByteFormatter.string(from: total.byteCount)
        let itemWord = total.assetCount == 1 ? "item" : "items"
        return "\(total.category.displayName): \(total.assetCount.formatted()) \(itemWord), \(size)"
    }

    private static func displayIndex(_ category: PhotoCategory) -> Int {
        PhotoCategory.v1Cases.firstIndex(of: category) ?? PhotoCategory.v1Cases.count
    }
}

/// A single shared byte-formatting helper so every screen renders sizes
/// identically.
enum ByteFormatter {
    static func string(from byteCount: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }

    /// Long-form for VoiceOver ("1.2 gigabytes" rather than "1.2 GB").
    static func spoken(_ byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false
        let short = formatter.string(fromByteCount: byteCount)
        return short
            .replacingOccurrences(of: " KB", with: " kilobytes")
            .replacingOccurrences(of: " MB", with: " megabytes")
            .replacingOccurrences(of: " GB", with: " gigabytes")
            .replacingOccurrences(of: " TB", with: " terabytes")
            .replacingOccurrences(of: " bytes", with: " bytes")
    }
}
