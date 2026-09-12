import SwiftUI

/// The final confirmation before anything is deleted. Always states plainly
/// that deleted items land in Recently Deleted, not gone forever — the
/// safety net is Apple's own, and the copy should say so
/// (see CLAUDE.md, golden rule 3).
struct ReviewDeleteView: View {
    let assets: [AssetSummary]
    var onDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var totalBytes: Int64 { assets.reduce(0) { $0 + $1.byteCount } }
    private var itemWord: String { assets.count == 1 ? "item" : "items" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: StorageSenseTheme.Spacing.lg) {
                    VStack(spacing: StorageSenseTheme.Spacing.xs) {
                        Text("\(assets.count) \(itemWord) selected")
                            .font(StorageSenseTheme.Font.secondary)
                            .foregroundStyle(StorageSenseTheme.textSecondary)
                        Text(ByteFormatter.string(from: totalBytes))
                            .font(StorageSenseTheme.Font.display)
                            .foregroundStyle(StorageSenseTheme.textPrimary)
                        Text("would be freed from your Photos library")
                            .font(StorageSenseTheme.Font.secondary)
                            .foregroundStyle(StorageSenseTheme.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, StorageSenseTheme.Spacing.md)
                    .accessibilityElement(children: .combine)

                    thumbnailStrip

                    VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
                        Label("Not gone forever", systemImage: "arrow.uturn.backward")
                            .font(StorageSenseTheme.Font.heading)
                            .foregroundStyle(StorageSenseTheme.success)
                        Text("Deleted items move to Recently Deleted in the Photos app, where they stay for 30 days before being permanently removed. You can restore them from there any time before that.")
                            .font(StorageSenseTheme.Font.secondary)
                            .foregroundStyle(StorageSenseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surfaceCard()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(StorageSenseTheme.Font.secondary)
                            .foregroundStyle(StorageSenseTheme.danger)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: StorageSenseTheme.Spacing.sm) {
                    Button {
                        Task { await performDelete() }
                    } label: {
                        if isDeleting {
                            ProgressView().tint(StorageSenseTheme.onAccent)
                        } else {
                            Text("Delete \(assets.count) \(itemWord)")
                        }
                    }
                    .buttonStyle(.primaryDestructive)
                    .disabled(isDeleting)
                    .accessibilityHint("Moves the selected items to Recently Deleted in Photos")

                    Button("Keep everything") { dismiss() }
                        .buttonStyle(.secondary)
                        .disabled(isDeleting)
                }
                .padding(.horizontal, StorageSenseTheme.Spacing.lg)
                .padding(.vertical, StorageSenseTheme.Spacing.md)
                .background(StorageSenseTheme.groundBottom.opacity(0.96))
            }
            .screenBackground()
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: StorageSenseTheme.minimumTapTarget, height: StorageSenseTheme.minimumTapTarget)
                    }
                    .accessibilityLabel("Cancel")
                    .disabled(isDeleting)
                }
            }
        }
    }

    private var thumbnailStrip: some View {
        let shown = Array(assets.sorted { $0.byteCount > $1.byteCount }.prefix(3))
        let remaining = assets.count - shown.count
        return HStack(spacing: 6) {
            ForEach(shown) { asset in
                ThumbnailCell(asset: asset, isSelected: false)
                    .frame(width: 100, height: 100)
                    .accessibilityHidden(true)
            }
            if remaining > 0 {
                Text("+\(remaining)")
                    .font(StorageSenseTheme.Font.stat)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                    .frame(width: 60, height: 100)
                    .surfaceCard(cornerRadius: StorageSenseTheme.CornerRadius.thumbnail, padding: 0)
                    .accessibilityLabel("and \(remaining) more")
            }
        }
    }

    private func performDelete() async {
        isDeleting = true
        errorMessage = nil
        do {
            try await DeletionService.delete(assetIdentifiers: assets.map(\.id))
            isDeleting = false
            onDeleted()
        } catch {
            isDeleting = false
            errorMessage = "Couldn't move those items to Recently Deleted. Nothing was changed — please try again."
        }
    }
}

#Preview("Three items") {
    ReviewDeleteView(assets: Array(DemoData.assets(in: .video, count: 3)), onDeleted: {})
}

#Preview("Many items") {
    ReviewDeleteView(assets: DemoData.assets(in: .screenshot, count: 48), onDeleted: {})
}
