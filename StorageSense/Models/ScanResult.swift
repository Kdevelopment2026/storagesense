import Foundation
import SwiftData

/// A cached summary of the last full library scan, keyed by category. This
/// is the only thing StorageSense persists — never individual asset data
/// (see AssetSummary.swift) — so Home can render instantly on launch instead
/// of re-enumerating the whole Photos library every time.
@Model
final class ScanResult {
    var id: UUID
    var scannedAt: Date
    /// One row per category. Stored as a plain array rather than a dictionary
    /// because SwiftData doesn't model dictionaries of value types cleanly.
    var categoryTotals: [CategoryTotal]

    init(scannedAt: Date = .now, categoryTotals: [CategoryTotal] = []) {
        self.id = UUID()
        self.scannedAt = scannedAt
        self.categoryTotals = categoryTotals
    }

    var totalByteCount: Int64 {
        categoryTotals.reduce(0) { $0 + $1.byteCount }
    }
}

/// A single category's totals from one scan. `Codable` so it can be stored
/// as a transformable/JSON-encoded array property on `ScanResult`.
struct CategoryTotal: Codable, Identifiable, Hashable {
    var id: String { category.rawValue }
    var category: PhotoCategory
    var assetCount: Int
    var byteCount: Int64
}
