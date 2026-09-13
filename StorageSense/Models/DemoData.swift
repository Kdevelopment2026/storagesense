import Foundation

/// Synthetic scan results and asset summaries for `#Preview`s and the
/// Simulator, so every screen is inspectable at a few realistic library
/// sizes without granting real Photos access. Never used on a device scan.
enum DemoData {

    enum LibrarySize {
        case small, medium, large
    }

    /// Launch argument that makes the scanner serve this demo library instead
    /// of PhotoKit — used for App Store screenshots and UI tests only.
    /// `xcrun simctl launch booted com.kayode.storagesense -storagesense-seed-demo`
    static let seedLaunchArgument = "-storagesense-seed-demo"

    static var isSeeded: Bool {
        CommandLine.arguments.contains(seedLaunchArgument)
    }

    /// Every category's assets, counts matching `totals(.medium)` closely
    /// enough for the detail screens to look right.
    static func allAssets() -> [AssetSummary] {
        totals(.medium).flatMap { total in
            assets(in: total.category, count: total.assetCount, totalBytes: total.byteCount)
        }
    }

    static func scanResult(_ size: LibrarySize = .medium) -> ScanResult {
        ScanResult(scannedAt: .now.addingTimeInterval(-120), categoryTotals: totals(size))
    }

    static func totals(_ size: LibrarySize = .medium) -> [CategoryTotal] {
        let gb: Int64 = 1_000_000_000
        switch size {
        case .small:
            return [
                CategoryTotal(category: .video, assetCount: 38, byteCount: Int64(2.4 * Double(gb))),
                CategoryTotal(category: .screenshot, assetCount: 210, byteCount: Int64(0.6 * Double(gb))),
                CategoryTotal(category: .livePhoto, assetCount: 120, byteCount: Int64(0.5 * Double(gb))),
                CategoryTotal(category: .standard, assetCount: 640, byteCount: Int64(0.9 * Double(gb))),
            ]
        case .medium:
            return [
                CategoryTotal(category: .video, assetCount: 1_214, byteCount: Int64(22.1 * Double(gb))),
                CategoryTotal(category: .livePhoto, assetCount: 3_870, byteCount: Int64(9.4 * Double(gb))),
                CategoryTotal(category: .screenshot, assetCount: 2_412, byteCount: Int64(6.8 * Double(gb))),
                CategoryTotal(category: .standard, assetCount: 5_930, byteCount: Int64(3.8 * Double(gb))),
                CategoryTotal(category: .burstDuplicate, assetCount: 940, byteCount: Int64(3.2 * Double(gb))),
                CategoryTotal(category: .largeFile, assetCount: 41, byteCount: Int64(2.9 * Double(gb))),
            ]
        case .large:
            return [
                CategoryTotal(category: .video, assetCount: 4_800, byteCount: Int64(131.0 * Double(gb))),
                CategoryTotal(category: .livePhoto, assetCount: 14_200, byteCount: Int64(38.5 * Double(gb))),
                CategoryTotal(category: .standard, assetCount: 21_000, byteCount: Int64(24.0 * Double(gb))),
                CategoryTotal(category: .screenshot, assetCount: 6_100, byteCount: Int64(12.3 * Double(gb))),
                CategoryTotal(category: .burstDuplicate, assetCount: 3_300, byteCount: Int64(9.1 * Double(gb))),
                CategoryTotal(category: .largeFile, assetCount: 160, byteCount: Int64(11.8 * Double(gb))),
            ]
        }
    }

    /// Fake assets for one category, sizes descending along a gentle power
    /// curve. When `totalBytes` is given the sizes are scaled so they add up
    /// to it, keeping detail headers consistent with the Home totals.
    static func assets(in category: PhotoCategory, count: Int = 24, totalBytes: Int64? = nil) -> [AssetSummary] {
        let weights = (0..<count).map { pow(Double($0 + 1), -0.7) }
        let scale: Double
        if let totalBytes {
            scale = Double(totalBytes) / weights.reduce(0, +)
        } else {
            scale = category == .video ? 1_900_000_000 : 48_000_000
        }
        return (0..<count).map { index in
            let bytes = max(Int64(weights[index] * scale), 1_000_000)
            return AssetSummary(
                id: "demo-\(category.rawValue)-\(index)",
                category: category,
                byteCount: bytes,
                creationDate: .now.addingTimeInterval(Double(-index) * 86_400 * 3),
                burstIdentifier: category == .burstDuplicate ? "burst-\(index / 3)" : nil
            )
        }
    }
}
