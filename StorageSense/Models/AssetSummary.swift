import Foundation

/// A lightweight, in-memory-only view of one Photos asset, used to populate
/// Category Detail. Deliberately never persisted — StorageSense always asks
/// PhotoKit fresh so it can never show a stale copy of the user's actual
/// photo library (see CLAUDE.md, Data model notes).
struct AssetSummary: Identifiable, Hashable {
    /// The underlying `PHAsset.localIdentifier`.
    let id: String
    let category: PhotoCategory
    let byteCount: Int64
    let creationDate: Date?
    /// Set when this asset was grouped as part of a burst/near-duplicate set.
    let burstIdentifier: String?
}
