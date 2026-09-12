import Foundation

/// The single gate for any paid feature. StorageSense's diagnostic —
/// scanning, the breakdown, plain-language explanations, and the biggest-win
/// ranking — is NEVER gated behind this, in any version, at any price point
/// (see CLAUDE.md, golden rule 2). Only bulk multi-select ("Select all")
/// and deeper duplicate detection check this object.
///
/// StoreKit 2 is deliberately not wired yet: the seam is `restorePurchases()`
/// and `isUnlocked`, so a future one-time unlock can be dropped in here
/// without any view changing (golden rule 8).
@Observable
final class ProStatus {
    static let shared = ProStatus()

    /// v1: always true. No paywall, no feature gating, no StoreKit calls yet.
    private(set) var isUnlocked: Bool = true

    private init() {}

    /// v1 no-op. When StoreKit 2 lands this becomes
    /// `for await result in Transaction.currentEntitlements { … }`.
    func restorePurchases() async {
        isUnlocked = true
    }
}
