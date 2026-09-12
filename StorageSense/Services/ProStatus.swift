import Foundation

/// The single gate for any paid feature. StorageSense's diagnostic —
/// scanning, the breakdown, plain-language explanations, and the biggest-win
/// ranking — is NEVER gated behind this, in any version, at any price point
/// (see CLAUDE.md, golden rule 2). Only bulk multi-select deletion and
/// deeper duplicate detection check this object.
@Observable
final class ProStatus {
    static let shared = ProStatus()

    /// v1: always true. No paywall, no feature gating, no StoreKit calls yet.
    var isUnlocked: Bool = true

    private init() {}
}
