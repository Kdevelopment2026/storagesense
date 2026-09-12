import SwiftUI

/// A plain-language explanation shown *before* the system Photos prompt,
/// so the request doesn't arrive out of nowhere. Never skip straight to the
/// system dialog — see CLAUDE.md build order, step 2.
struct PermissionView: View {
    var scanner: PhotoLibraryScanner
    @State private var isRequesting = false

    private let points: [(icon: String, text: String)] = [
        ("doc.text.magnifyingglass", "Reads sizes and types, not the photos themselves"),
        ("wifi.slash", "Works fully offline, no account"),
        ("arrow.uturn.backward", "Nothing is deleted without your review"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: StorageSenseTheme.Spacing.lg) {
                emblem
                    .padding(.top, StorageSenseTheme.Spacing.xl)
                    .revealOnAppear()

                VStack(spacing: StorageSenseTheme.Spacing.sm) {
                    Text("StorageSense reads your Photos library")
                        .font(StorageSenseTheme.Font.title)
                        .foregroundStyle(StorageSenseTheme.textPrimary)
                    Text("Everything happens on your phone. StorageSense looks at your photos and videos to show you what's using the space. Nothing is ever uploaded, and nothing leaves your device.")
                        .font(StorageSenseTheme.Font.body)
                        .foregroundStyle(StorageSenseTheme.textSecondary)
                }
                .multilineTextAlignment(.center)
                .revealOnAppear(delay: 0.08)

                VStack(spacing: StorageSenseTheme.Spacing.sm) {
                    ForEach(points, id: \.text) { point in
                        HStack(spacing: StorageSenseTheme.Spacing.sm + 4) {
                            Image(systemName: point.icon)
                                .foregroundStyle(StorageSenseTheme.accent)
                                .frame(width: 22)
                                .accessibilityHidden(true)
                            Text(point.text)
                                .font(StorageSenseTheme.Font.secondary)
                                .foregroundStyle(StorageSenseTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .surfaceCard(padding: 14)
                    }
                }
                .revealOnAppear(delay: 0.16)
            }
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: StorageSenseTheme.Spacing.sm) {
                Button {
                    Task {
                        isRequesting = true
                        _ = await scanner.requestAuthorization()
                        isRequesting = false
                    }
                } label: {
                    Text(isRequesting ? "Requesting…" : "Continue")
                }
                .buttonStyle(.primary)
                .disabled(isRequesting)

                Text("You'll see the standard iOS Photos prompt next. Limited access works too.")
                    .font(StorageSenseTheme.Font.caption)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            .padding(.vertical, StorageSenseTheme.Spacing.md)
        }
        .screenBackground()
    }

    private var emblem: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [StorageSenseTheme.accent.opacity(0.28), .clear], center: .center, startRadius: 10, endRadius: 70))
            Circle()
                .strokeBorder(StorageSenseTheme.ringTrack, lineWidth: 9)
                .frame(width: 88, height: 88)
            Circle()
                .trim(from: 0, to: 0.64)
                .stroke(StorageSenseTheme.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 88, height: 88)
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(StorageSenseTheme.textPrimary)
        }
        .frame(width: 130, height: 130)
        .accessibilityHidden(true)
    }
}

#Preview {
    PermissionView(scanner: PhotoLibraryScanner())
}
