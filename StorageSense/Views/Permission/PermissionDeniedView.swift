import SwiftUI

/// Shown when Photos access has been denied or restricted. The app can't do
/// anything without this permission, so this screen's only job is a clear,
/// calm path back to Settings — no guilt-tripping (see CLAUDE.md, golden
/// rule 10).
struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: StorageSenseTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "lock.rectangle.stack")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .accessibilityHidden(true)

            VStack(spacing: StorageSenseTheme.Spacing.sm) {
                Text("Photos access is off")
                    .font(StorageSenseTheme.Font.title)
                    .foregroundStyle(StorageSenseTheme.textPrimary)
                Text("StorageSense can't scan your library without Photos access. You can turn it on any time in Settings.")
                    .font(StorageSenseTheme.Font.body)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.primary)
            .padding(.bottom, StorageSenseTheme.Spacing.lg)
        }
        .padding(.horizontal, StorageSenseTheme.Spacing.lg)
        .screenBackground()
    }
}

#Preview {
    PermissionDeniedView()
}
