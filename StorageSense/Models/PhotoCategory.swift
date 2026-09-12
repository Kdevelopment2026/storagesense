import Foundation

/// The fixed set of categories StorageSense breaks a Photos library into.
/// Scope is deliberately limited to what PhotoKit can actually see — the
/// Photos & Videos library, nothing else on the device (see CLAUDE.md,
/// golden rule 1).
enum PhotoCategory: String, CaseIterable, Identifiable, Codable {
    case screenshot
    case video
    case livePhoto
    case burstDuplicate
    case selfie
    case largeFile
    case standard

    /// The categories v1 actually shows. `.selfie` is excluded: PhotoKit has
    /// no public "is this a selfie" flag and the EXIF lens-facing heuristic
    /// hasn't been validated on a real device, so rather than ship it
    /// silently broken the category stays out of the UI (CLAUDE.md,
    /// definition of done). The scanner never assigns it either, so selfies
    /// land in "Everything else" — the safe default.
    static let v1Cases: [PhotoCategory] = [.video, .livePhoto, .screenshot, .burstDuplicate, .largeFile, .standard]

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .screenshot: return "Screenshots"
        case .video: return "Videos"
        case .livePhoto: return "Live Photos"
        case .burstDuplicate: return "Bursts & duplicates"
        case .selfie: return "Selfies"
        case .largeFile: return "Large files"
        case .standard: return "Everything else"
        }
    }

    var systemImageName: String {
        switch self {
        case .screenshot: return "camera.viewfinder"
        case .video: return "video.fill"
        case .livePhoto: return "livephoto"
        case .burstDuplicate: return "square.stack.3d.up.fill"
        case .selfie: return "person.crop.square.fill"
        case .largeFile: return "arrow.up.left.and.arrow.down.right"
        case .standard: return "photo.fill"
        }
    }

    /// The plain-language explanation shown wherever this category appears.
    /// Calm and factual, never judgmental — see CLAUDE.md, golden rule 10.
    var explanation: String {
        switch self {
        case .screenshot:
            return "Screenshots are easy to take and easy to forget. Most people never look at these again after the day they were taken."
        case .video:
            return "Video is the single biggest driver of Photos storage for most people. A few minutes of 4K video can outweigh thousands of photos."
        case .livePhoto:
            return "Live Photos take roughly two to three times the space of a regular photo, because each one also stores a short video clip you may never watch."
        case .burstDuplicate:
            return "Burst shots and near-identical repeats taken seconds apart. Usually you only wanted one of these, not all of them."
        case .selfie:
            return "Front-camera shots, grouped so you can review them together rather than one at a time."
        case .largeFile:
            return "Individually oversized photos or videos. Often a single long recording or a high-resolution export."
        case .standard:
            return "Everything that doesn't fall into a more specific category above."
        }
    }

    /// One short line for the biggest-win card — why this category is worth
    /// looking at first.
    var winHint: String {
        switch self {
        case .screenshot: return "Quick to review, and rarely missed once gone."
        case .video: return "Reviewing the longest recordings first recovers the most space."
        case .livePhoto: return "Each one carries a short video clip alongside the still."
        case .burstDuplicate: return "Keeping one shot from each burst frees the rest."
        case .selfie: return "Grouped together so you can review them in one pass."
        case .largeFile: return "A handful of files, each carrying a lot of weight."
        case .standard: return "The long tail of everyday photos."
        }
    }
}
