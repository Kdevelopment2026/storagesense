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
            return "Video is the single biggest driver of Photos storage for most people — a few minutes of 4K video can outweigh thousands of photos."
        case .livePhoto:
            return "Live Photos take roughly 2–3x the space of a regular photo, because each one also stores a short video clip you may never watch."
        case .burstDuplicate:
            return "Burst shots and near-identical repeats — usually you only wanted one of these, not all of them."
        case .selfie:
            return "Front-camera shots, grouped so you can review them together rather than one at a time."
        case .largeFile:
            return "Individually oversized photos or videos — often a single long recording or a high-resolution export."
        case .standard:
            return "Everything that doesn't fall into a more specific category above."
        }
    }
}
