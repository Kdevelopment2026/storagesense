import SwiftUI

/// A gentle fade-and-rise when a section first appears. Fully skipped under
/// Reduce Motion — the content simply shows (CLAUDE.md, golden rule 9).
struct RevealOnAppear: ViewModifier {
    var delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible || reduceMotion ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 12)
            .onAppear {
                withAnimation(StorageSenseTheme.animation(.easeOut(duration: 0.45).delay(delay), reduceMotion: reduceMotion)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func revealOnAppear(delay: Double = 0) -> some View {
        modifier(RevealOnAppear(delay: delay))
    }
}
