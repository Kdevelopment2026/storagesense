import SwiftUI

/// A brief first-launch intro: the ring draws in, the name fades up, and we
/// move on. Under Reduce Motion it hands off immediately.
struct SplashView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var ringProgress = 0.0

    var body: some View {
        VStack(spacing: StorageSenseTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [StorageSenseTheme.accent.opacity(0.28), .clear], center: .center, startRadius: 30, endRadius: 120))
                Circle()
                    .strokeBorder(StorageSenseTheme.ringTrack, lineWidth: 16)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(StorageSenseTheme.accent, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(8)
                Image(systemName: "photo.stack")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(StorageSenseTheme.textPrimary)
            }
            .frame(width: 180, height: 180)
            .accessibilityHidden(true)

            VStack(spacing: StorageSenseTheme.Spacing.sm) {
                Text("StorageSense")
                    .font(StorageSenseTheme.Font.display)
                    .foregroundStyle(StorageSenseTheme.textPrimary)
                Text("See what's filling your Photos library before you delete anything.")
                    .font(StorageSenseTheme.Font.secondary)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
        }
        .padding(StorageSenseTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("StorageSense. See what's filling your Photos library before you delete anything.")
        .task {
            if reduceMotion {
                isVisible = true
                ringProgress = 0.72
                onFinished()
            } else {
                withAnimation(.easeOut(duration: 0.7)) {
                    isVisible = true
                    ringProgress = 0.72
                }
                try? await Task.sleep(for: .seconds(1.1))
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
