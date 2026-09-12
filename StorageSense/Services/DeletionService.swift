import Foundation
import Photos

/// The only place StorageSense ever mutates the Photos library. Deletion
/// always goes through `PHPhotoLibrary.performChanges`, which moves assets to
/// Recently Deleted (Apple's own 30-day undo) rather than deleting them
/// outright — never build a custom "trash" system on top of this
/// (see CLAUDE.md, golden rule 3).
enum DeletionService {

    enum DeletionError: Error {
        case libraryChangeFailed(Error)
    }

    /// Deletes the given assets (by local identifier) after the user has
    /// explicitly reviewed and confirmed them in ReviewDeleteView. Never call
    /// this from anywhere else.
    static func delete(assetIdentifiers: [String]) async throws {
        guard !assetIdentifiers.isEmpty else { return }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(fetchResult)
            } completionHandler: { success, error in
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: DeletionError.libraryChangeFailed(error ?? NSError(domain: "StorageSense", code: -1)))
                }
            }
        }
    }
}
