import SwiftUI

/// A plain-language explanation shown *before* the system Photos prompt,
/// so the request doesn't arrive out of nowhere. Never skip straight to the
/// system dialog — see CLAUDE.md build order, step 2.
struct PermissionView: View {
    var scanner: PhotoLibraryScanner
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: StorageSenseTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("StorageSense reads your Photos library")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Everything happens on your phone. StorageSense looks at your Photos library to show you what's using the space — nothing is ever uploaded, and nothing leaves your device.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, StorageSenseTheme.Spacing.lg)

            Spacer()

            Button {
                Task {
                    isRequesting = true
                    _ = await scanner.requestAuthorization()
                    isRequesting = false
                }
            } label: {
                Text(isRequesting ? "Requesting…" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequesting)
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            .padding(.bottom, StorageSenseTheme.Spacing.lg)
        }
    }
}

/// Shown when Photos access has been denied or restricted. The app can't do
/// anything without this permission, so this screen's only job is a clear,
/// calm path back to Settings — no guilt-tripping (see CLAUDE.md, golden
/// rule 10).
struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: StorageSenseTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "lock.photo")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Photos access is off")
                .font(.title2.bold())

            Text("StorageSense can't scan your library without Photos access. You can turn it on any time in Settings.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, StorageSenseTheme.Spacing.lg)

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            .padding(.bottom, StorageSenseTheme.Spacing.lg)
        }
    }
}

#Preview("Permission") {
    PermissionView(scanner: PhotoLibraryScanner())
}

#Preview("Denied") {
    PermissionDeniedView()
}
