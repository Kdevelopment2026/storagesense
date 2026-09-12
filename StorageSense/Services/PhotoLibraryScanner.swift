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
///   5. Large file         — any remaining still photo over the threshold
///   6. Standard            — everything else (including selfies, which v1
///                            deliberately does not try to detect — see
///                            `PhotoCategory.v1Cases`)
@Observable
final class PhotoLibraryScanner {

    /// Anything over this size is called out on its own rather than hiding
    /// inside "Everything else."
    static let largeFileThresholdBytes: Int64 = 50 * 1_024 * 1_024 // 50MB

    private(set) var authorizationStatus: PHAuthorizationStatus

    /// Live scan progress, 0…1, for the Home progress state. Updated on the
    /// main actor every `progressStride` assets so a 45,000-asset library
    /// doesn't flood the UI with observation changes.
    private(set) var progress: Double = 0
    private(set) var isScanning = false

    /// The per-asset summaries from the most recent scan, kept in memory for
    /// the session only so Category Detail can open instantly. Never
    /// persisted — if the app relaunches from a cached `ScanResult` this is
    /// empty and `assets(in:)` re-enumerates (see AssetSummary.swift).
    private(set) var lastAssets: [AssetSummary] = []

    private static let progressStride = 250

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
    @MainActor
    func scan() async -> (totals: [CategoryTotal], assets: [AssetSummary]) {
        isScanning = true
        progress = 0
        defer { isScanning = false }

        let summaries = await enumerateLibrary { [weak self] fraction in
            Task { @MainActor in self?.progress = fraction }
        }
        lastAssets = Self.applyDuplicateCategory(to: summaries)
        progress = 1
        return (Self.aggregate(lastAssets), lastAssets)
    }

    /// The assets in one category, always from the current session's
    /// enumeration — never a stored copy. Re-scans if nothing is cached yet
    /// (e.g. Home rendered from a persisted `ScanResult` on launch).
    @MainActor
    func assets(in category: PhotoCategory) async -> [AssetSummary] {
        if lastAssets.isEmpty {
            _ = await scan()
        }
        return lastAssets.filter { $0.category == category }
    }

    private func enumerateLibrary(onProgress: @escaping (Double) -> Void) async -> [AssetSummary] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fetchOptions = PHFetchOptions()
                fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
                let result = PHAsset.fetchAssets(with: fetchOptions)
                let total = max(result.count, 1)

                var summaries: [AssetSummary] = []
                summaries.reserveCapacity(result.count)

                // Batched with an autoreleasepool: PHAssetResource lookups
                // allocate per asset, and tens of thousands of them in one
                // pass would otherwise balloon memory before draining.
                var index = 0
                while index < result.count {
                    let end = min(index + Self.progressStride, result.count)
                    autoreleasepool {
                        for i in index..<end {
                            let asset = result.object(at: i)
                            let byteCount = Self.byteCount(for: asset)
                            summaries.append(
                                AssetSummary(
                                    id: asset.localIdentifier,
                                    category: Self.category(for: asset, byteCount: byteCount),
                                    byteCount: byteCount,
                                    creationDate: asset.creationDate,
                                    burstIdentifier: asset.representsBurst ? asset.burstIdentifier : nil
                                )
                            )
                        }
                    }
                    index = end
                    onProgress(Double(index) / Double(total))
                }

                continuation.resume(returning: summaries)
            }
        }
    }

    /// Assigns exactly one category per the priority order documented above.
    /// Pure and static so it can be unit-tested with synthetic inputs.
    static func category(for asset: PHAsset, byteCount: Int64) -> PhotoCategory {
        category(
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            isLivePhoto: asset.mediaSubtypes.contains(.photoLive),
            isVideo: asset.mediaType == .video,
            isBurst: asset.representsBurst,
            byteCount: byteCount
        )
    }

    static func category(isScreenshot: Bool, isLivePhoto: Bool, isVideo: Bool, isBurst: Bool, byteCount: Int64) -> PhotoCategory {
        if isScreenshot { return .screenshot }
        if isLivePhoto { return .livePhoto }
        if isVideo { return .video }
        if isBurst { return .burstDuplicate }
        if byteCount >= largeFileThresholdBytes { return .largeFile }
        return .standard
    }

    /// Sums the byte size of every resource backing an asset (an asset can
    /// have more than one resource — e.g. a Live Photo's still + video pair).
    /// Assets that live only in iCloud and aren't downloaded report 0 here,
    /// which is honest: they aren't using space on this device.
    private static func byteCount(for asset: PHAsset) -> Int64 {
        PHAssetResource.assetResources(for: asset).reduce(Int64(0)) { total, resource in
            guard let size = resource.value(forKey: "fileSize") as? NSNumber else { return total }
            return total + size.int64Value
        }
    }

    static func aggregate(_ summaries: [AssetSummary]) -> [CategoryTotal] {
        var totals: [PhotoCategory: (count: Int, bytes: Int64)] = [:]
        for summary in summaries {
            var entry = totals[summary.category] ?? (0, 0)
            entry.count += 1
            entry.bytes += summary.byteCount
            totals[summary.category] = entry
        }
        return PhotoCategory.v1Cases.compactMap { category in
            guard let entry = totals[category], entry.count > 0 else { return nil }
            return CategoryTotal(category: category, assetCount: entry.count, byteCount: entry.bytes)
        }
    }

    static func applyDuplicateCategory(to summaries: [AssetSummary]) -> [AssetSummary] {
        let duplicateCandidates = summaries.filter { $0.category == .standard || $0.category == .largeFile }
        let duplicateIDs = Set(DuplicateDetector.groups(in: duplicateCandidates).flatMap { group in
            group.assets.map(\.id)
        })
        return summaries.map { summary in
            guard duplicateIDs.contains(summary.id), summary.category == .standard || summary.category == .largeFile else {
                return summary
            }
            return AssetSummary(
                id: summary.id,
                category: .burstDuplicate,
                byteCount: summary.byteCount,
                creationDate: summary.creationDate,
                burstIdentifier: summary.burstIdentifier
            )
        }
    }
}
