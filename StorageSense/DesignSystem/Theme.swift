import SwiftUI

/// StorageSense's visual language: calm and factual, matching a diagnostic
/// tool rather than a gamified cleaner. Category colours are distinct for
/// chart legibility but never used as the *only* signal — every chart
/// segment is always paired with a text label and byte value
/// (see CLAUDE.md, golden rule 9).
enum StorageSenseTheme {

    static func color(for category: PhotoCategory) -> Color {
        switch category {
        case .screenshot: return Color(red: 0.35, green: 0.55, blue: 0.85)
        case .video: return Color(red: 0.20, green: 0.62, blue: 0.58)
        case .livePhoto: return Color(red: 0.85, green: 0.55, blue: 0.25)
        case .burstDuplicate: return Color(red: 0.62, green: 0.42, blue: 0.78)
        case .selfie: return Color(red: 0.80, green: 0.40, blue: 0.55)
        case .largeFile: return Color(red: 0.78, green: 0.32, blue: 0.32)
        case .standard: return Color(red: 0.55, green: 0.57, blue: 0.60)
        }
    }

    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum CornerRadius {
        static let card: CGFloat = 18
    }
}

/// Shared appearance setting, read by both the app root (to apply it) and
/// Settings (to let the user change it).
enum AppearanceOption: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
