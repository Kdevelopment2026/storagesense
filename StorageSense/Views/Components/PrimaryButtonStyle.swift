import SwiftUI

/// The single filled call-to-action style. `role: .destructive` buttons pick
/// up the danger colour so "Delete" never looks like "Continue".
struct PrimaryButtonStyle: ButtonStyle {
    var role: ButtonRole? = nil
    @Environment(\.isEnabled) private var isEnabled

    private var fill: Color {
        role == .destructive ? StorageSenseTheme.danger : StorageSenseTheme.accent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StorageSenseTheme.Font.heading)
            .foregroundStyle(StorageSenseTheme.onAccent)
            .frame(maxWidth: .infinity, minHeight: StorageSenseTheme.minimumTapTarget + 6)
            .padding(.horizontal, StorageSenseTheme.Spacing.md)
            .background(fill, in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : (isEnabled ? 1 : 0.5))
    }
}

/// The quiet counterpart: a surface-coloured button for "Keep everything",
/// "Cancel" and similar non-committal actions.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StorageSenseTheme.Font.heading)
            .foregroundStyle(StorageSenseTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: StorageSenseTheme.minimumTapTarget + 6)
            .padding(.horizontal, StorageSenseTheme.Spacing.md)
            .background(StorageSenseTheme.surface, in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.button, style: .continuous)
                    .strokeBorder(StorageSenseTheme.surfaceBorder, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var primaryDestructive: PrimaryButtonStyle { PrimaryButtonStyle(role: .destructive) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
