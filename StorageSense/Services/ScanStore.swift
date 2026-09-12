import Foundation
import SwiftData

/// The one place a scan is run *and* its summary cached, so Home and
/// Settings re-scan through the same path. Only the per-category summary is
/// persisted (CLAUDE.md, golden rule 6) — per-asset data stays in the
/// scanner's in-memory session cache.
enum ScanStore {

    @MainActor
    static func rescan(using scanner: PhotoLibraryScanner, in modelContext: ModelContext) async {
        let (totals, _) = await scanner.scan()
        cache(totals, in: modelContext)
    }

    /// Replaces whatever was cached with a fresh summary. StorageSense never
    /// needs scan history, only "what does the library look like right now."
    @MainActor
    static func cache(_ totals: [CategoryTotal], in modelContext: ModelContext) {
        let existing = (try? modelContext.fetch(FetchDescriptor<ScanResult>())) ?? []
        for old in existing {
            modelContext.delete(old)
        }
        modelContext.insert(ScanResult(scannedAt: .now, categoryTotals: totals))
        try? modelContext.save()
    }
}
