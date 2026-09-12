import SwiftUI

/// The raised "chip" surface used for category tiles, reassurance copy and
/// grouped settings rows: a subtle fill with a hairline border so it holds up
/// on both the light and dark ground without a drop shadow.
struct SurfaceCard: ViewModifier {
    var cornerRadius: CGFloat = StorageSenseTheme.CornerRadius.chip
    var padding: CGFloat = StorageSenseTheme.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(StorageSenseTheme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(StorageSenseTheme.surfaceBorder, lineWidth: 1)
            )
    }
}

extension View {
    func surfaceCard(cornerRadius: CGFloat = StorageSenseTheme.CornerRadius.chip, padding: CGFloat = StorageSenseTheme.Spacing.md) -> some View {
        modifier(SurfaceCard(cornerRadius: cornerRadius, padding: padding))
    }
}
