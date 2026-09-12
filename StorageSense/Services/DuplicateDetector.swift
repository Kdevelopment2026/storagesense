import Foundation
import Photos

/// Groups obvious duplicates — deliberately scoped to what PhotoKit already
/// tells us for free, not exhaustive AI similarity matching (that ceiling is
/// intentional, see README → Roadmap and CLAUDE.md → Out of scope).
///
/// v1 groups by PhotoKit's own `burstIdentifier` (assets the camera itself
/// captured as a burst) plus a simple creation-time-proximity fallback
/// (multiple stills within a couple of seconds of each other), which catches
/// rapid manual repeats that the system didn't tag as a formal burst.
enum DuplicateDetector {

    static let proximityWindow: TimeInterval = 2.0

    struct DuplicateGroup: Identifiable {
        var id: String
        var assets: [AssetSummary]
    }

    static func groups(in assets: [AssetSummary]) -> [DuplicateGroup] {
        var byBurst: [String: [AssetSummary]] = [:]
        var ungrouped: [AssetSummary] = []

        for asset in assets {
            if let burstID = asset.burstIdentifier {
                byBurst[burstID, default: []].append(asset)
            } else {
                ungrouped.append(asset)
            }
        }

        var groups = byBurst.map { DuplicateGroup(id: $0.key, assets: $0.value) }
        groups.append(contentsOf: proximityGroups(in: ungrouped))
        // Only report groups that actually contain more than one asset —
        // a "group" of one isn't a duplicate of anything.
        return groups.filter { $0.assets.count > 1 }
    }

    private static func proximityGroups(in assets: [AssetSummary]) -> [DuplicateGroup] {
        let sorted = assets
            .filter { $0.creationDate != nil }
            .sorted { $0.creationDate! < $1.creationDate! }

        var groups: [DuplicateGroup] = []
        var current: [AssetSummary] = []

        for asset in sorted {
            guard let last = current.last, let lastDate = last.creationDate, let date = asset.creationDate else {
                current = [asset]
                continue
            }
            if date.timeIntervalSince(lastDate) <= proximityWindow {
                current.append(asset)
            } else {
                if current.count > 1 {
                    groups.append(DuplicateGroup(id: "proximity-\(groups.count)", assets: current))
                }
                current = [asset]
            }
        }
        if current.count > 1 {
            groups.append(DuplicateGroup(id: "proximity-\(groups.count)", assets: current))
        }
        return groups
    }
}
