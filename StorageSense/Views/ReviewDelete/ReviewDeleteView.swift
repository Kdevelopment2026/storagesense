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

    private var totalBytes: Int64 {
        assets.reduce(0) { $0 + $1.byteCount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: StorageSenseTheme.Spacing.lg) {
                VStack(spacing: StorageSenseTheme.Spacing.sm) {
                    Text("\(assets.count) items selected")
                        .font(.title2.bold())
                    Text("Freeing \(ByteFormatter.string(from: totalBytes))")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, StorageSenseTheme.Spacing.lg)

                Label(
                    "Deleted items move to Recently Deleted in the Photos app, where they stay for 30 days before being permanently removed. You can restore them from there any time before that.",
                    systemImage: "arrow.uturn.backward.circle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(StorageSenseTheme.Spacing.md)
                .background(StorageSenseTheme.cardBackground, in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card))
                .padding(.horizontal, StorageSenseTheme.Spacing.md)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, StorageSenseTheme.Spacing.md)
                }

                Spacer()

                Button(role: .destructive) {
                    Task { await performDelete() }
                } label: {
                    if isDeleting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Delete \(assets.count) items")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isDeleting)
                .padding(.horizontal, StorageSenseTheme.Spacing.md)
                .padding(.bottom, StorageSenseTheme.Spacing.md)
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isDeleting)
                }
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
            errorMessage = "Couldn't delete those items. Please try again."
        }
    }
}
