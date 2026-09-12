import SwiftUI

/// StorageSense's visual language — the "Observatory" direction chosen from
/// the five Pencil concepts in `design/`: a calm, dark-first surface with a
/// luminous segmented ring, category chips and a single accent colour.
/// Every token has a light and dark variant in the asset catalogue so text
/// contrast holds in both schemes and the user's Appearance choice is
/// honoured rather than forced.
///
/// Category colours are distinct for chart legibility but never used as the
/// *only* signal — every chart segment is always paired with a text label and
/// byte value (see CLAUDE.md, golden rule 9).
enum StorageSenseTheme {

    // MARK: Surfaces & text

    static let ground = Color("Ground")
    static let groundBottom = Color("GroundBottom")
    static let surface = Color("Surface")
    static let surfaceBorder = Color("SurfaceBorder")
    static let ringTrack = Color("RingTrack")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accent = Color("AccentColor")
    static let onAccent = Color("OnAccent")
    static let winCardTop = Color("WinCardTop")
    static let winCardBottom = Color("WinCardBottom")
    static let danger = Color("Danger")
    static let success = Color("Success")
    static let caution = Color("Caution")

    /// The vertical ground gradient behind every screen.
    static var groundGradient: LinearGradient {
        LinearGradient(colors: [ground, groundBottom], startPoint: .top, endPoint: .bottom)
    }

    /// The gradient used on the biggest-win card and the calculator result.
    static var winGradient: LinearGradient {
        LinearGradient(colors: [winCardTop, winCardBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Categories

    static func color(for category: PhotoCategory) -> Color {
        switch category {
        case .video: return Color("CategoryVideo")
        case .livePhoto: return Color("CategoryLivePhoto")
        case .screenshot: return Color("CategoryScreenshot")
        case .standard: return Color("CategoryStandard")
        case .burstDuplicate: return Color("CategoryBurst")
        case .largeFile: return Color("CategoryLargeFile")
        case .selfie: return Color("CategoryStandard")
        }
    }

    // MARK: Spacing & shape

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum CornerRadius {
        static let chip: CGFloat = 14
        static let card: CGFloat = 18
        static let button: CGFloat = 12
        static let thumbnail: CGFloat = 8
    }

    /// Minimum tap target size, per CLAUDE.md golden rule 9.
    static let minimumTapTarget: CGFloat = 44

    // MARK: Type

    /// Every style maps onto a system text style so Dynamic Type scales it;
    /// only weight and design are customised.
    enum Font {
        static let display = SwiftUI.Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = SwiftUI.Font.title2.weight(.semibold)
        static let heading = SwiftUI.Font.headline
        static let stat = SwiftUI.Font.system(.title3, design: .rounded).weight(.semibold)
        static let body = SwiftUI.Font.body
        static let secondary = SwiftUI.Font.subheadline
        static let caption = SwiftUI.Font.caption
        static let eyebrow = SwiftUI.Font.caption.weight(.semibold)
    }

    // MARK: Motion

    /// The animation to use, or `nil` when Reduce Motion is on so the change
    /// applies instantly.
    static func animation(_ animation: Animation = .easeOut(duration: 0.35), reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
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
