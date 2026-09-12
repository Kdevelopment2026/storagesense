import Foundation
import Photos

/// The core engine: enumerates the user's Photos library and categorises
/// every asset. This is the one place PhotoKit enumeration and
/// categorisation logic lives — views never call PhotoKit directly
/// (see CLAUDE.md).
///
/// Categorisation is priority-ordered so every asset lands in exactly one
/// category and the breakdown always sums to the library total:
///   1. Screenshot        — always a screenshot, regardless of size
///   2. Live Photo        — the live component is *why* it's big
///   3. Video (non-live)
///   4. Burst / duplicate — grouped by PhotoKit's own `burstIdentifier`
///   5. Selfie             — best-effort only, see note below
///   6. Large file         — any remaining still photo over the threshold
///   7. Standard            — everything else
@Observable
final class PhotoLibraryScanner {

    /// Anything over this size is called out on its own rather than hiding
    /// inside "Everything else."
    static let largeFileThresholdBytes: Int64 = 50 * 1_024 * 1_024 // 50MB

    private(set) var authorizationStatus: PHAuthorizationStatus

    init() {
        // Synchronous, non-prompting read of whatever the current status is —
        // safe to call before any explanation UI has been shown.
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Re-reads the current status without prompting — used when returning
    /// from Settings after the user changed permission there.
    @MainActor
    func refreshAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Requests (or reads the existing) Photos permission. Callers should
    /// show the Permission screen's explanation *before* triggering this —
    /// this only wraps the system call.
    @MainActor
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }

    /// Performs a full library scan off the main thread and returns the
    /// per-category totals plus the raw per-asset summaries (the latter used
    /// to populate Category Detail without a second full enumeration).
    func scan() async -> (totals: [CategoryTotal], assets: [AssetSummary]) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fetchOptions = PHFetchOptions()
                fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
                let result = PHAsset.fetchAssets(with: fetchOptions)

                var summaries: [AssetSummary] = []
                summaries.reserveCapacity(result.count)

                result.enumerateObjects { asset, _, _ in
                    let category = Self.category(for: asset)
                    let byteCount = Self.byteCount(for: asset)
                    summaries.append(
                        AssetSummary(
                            id: asset.localIdentifier,
                            category: category,
                            byteCount: byteCount,
                            creationDate: asset.creationDate,
                            burstIdentifier: asset.representsBurst ? asset.burstIdentifier : nil
                        )
                    )
                }

                let totals = Self.aggregate(summaries)
                continuation.resume(returning: (totals, summaries))
            }
        }
    }

    /// Assigns exactly one category per the priority order documented above.
    ///
    /// Note on selfies: PhotoKit's public API has no `isSelfie` flag. This
    /// falls back to an EXIF lens-facing heuristic on still photos, which is
    /// best-effort and won't catch every case (coverage depends on what the
    /// capturing app wrote to metadata). Verify against a real device library
    /// before relying on this for anything user-facing beyond a soft grouping
    /// — see CLAUDE.md build order, step 4.
    private static func category(for asset: PHAsset) -> PhotoCategory {
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            return .screenshot
        }
        if asset.mediaSubtypes.contains(.photoLive) {
            return .livePhoto
        }
        if asset.mediaType == .video {
            return .video
        }
        if asset.representsBurst {
            return .burstDuplicate
        }
        if isLikelySelfie(asset) {
            return .selfie
        }
        if byteCount(for: asset) >= largeFileThresholdBytes {
            return .largeFile
        }
        return .standard
    }

    /// Best-effort front-camera heuristic — see the categorisation note above.
    private static func isLikelySelfie(_ asset: PHAsset) -> Bool {
        // Deliberately conservative placeholder for v1: real implementation
        // reads EXIF lens-facing metadata via PHAssetResource / CGImageSource
        // and needs validation against real-device photos before it's trusted.
        // Returning false keeps unverified assets in "Standard" rather than
        // mis-labelling them.
        false
    }

    /// Sums the byte size of every resource backing an asset (an asset can
    /// have more than one resource — e.g. a Live Photo's still + video pair).
    private static func byteCount(for asset: PHAsset) -> Int64 {
        PHAssetResource.assetResources(for: asset).reduce(Int64(0)) { total, resource in
            guard let size = resource.value(forKey: "fileSize") as? Int64 else { return total }
            return total + size
        }
    }

    private static func aggregate(_ summaries: [AssetSummary]) -> [CategoryTotal] {
        var totals: [PhotoCategory: (count: Int, bytes: Int64)] = [:]
        for summary in summaries {
            var entry = totals[summary.category] ?? (0, 0)
            entry.count += 1
            entry.bytes += summary.byteCount
            totals[summary.category] = entry
        }
        return PhotoCategory.allCases.compactMap { category in
            guard let entry = totals[category], entry.count > 0 else { return nil }
            return CategoryTotal(category: category, assetCount: entry.count, byteCount: entry.bytes)
        }
    }
}
