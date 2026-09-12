import SwiftUI

/// Applies the Observatory ground gradient behind a screen and keeps the
/// navigation bar visually part of it. Every top-level screen uses this so
/// the app reads as one surface rather than a stack of system-grey forms.
struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(StorageSenseTheme.groundGradient.ignoresSafeArea())
            .toolbarBackground(StorageSenseTheme.ground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(StorageSenseTheme.accent)
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}
