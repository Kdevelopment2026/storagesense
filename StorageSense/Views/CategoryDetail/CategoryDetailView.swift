import SwiftUI
import Photos

/// Thumbnail grid for one category, with a running "selected to delete"
/// total. Nothing here deletes anything directly — selecting only queues
/// assets for the explicit confirm step in ReviewDeleteView
/// (see CLAUDE.md, golden rule 3).
struct CategoryDetailView: View {
    let category: PhotoCategory
    let assets: [AssetSummary]

    @State private var selectedIdentifiers: Set<String> = []
    @State private var isPresentingReview = false

    private var categoryAssets: [AssetSummary] {
        assets.filter { $0.category == category }
    }

    private var selectedByteCount: Int64 {
        categoryAssets
            .filter { selectedIdentifiers.contains($0.id) }
            .reduce(0) { $0 + $1.byteCount }
    }

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 4)]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.xs) {
                Text(category.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(StorageSenseTheme.Spacing.md)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(categoryAssets) { asset in
                        ThumbnailCell(
                            asset: asset,
                            isSelected: selectedIdentifiers.contains(asset.id)
                        )
                        .onTapGesture {
                            toggle(asset)
                        }
                        .accessibilityAddTraits(selectedIdentifiers.contains(asset.id) ? [.isSelected] : [])
                        .accessibilityLabel(Text("\(category.displayName) item, \(ByteFormatter.string(from: asset.byteCount))"))
                    }
                }
                .padding(.horizontal, 4)
            }

            if !selectedIdentifiers.isEmpty {
                Button {
                    isPresentingReview = true
                } label: {
                    Text("Review \(selectedIdentifiers.count) selected — \(ByteFormatter.string(from: selectedByteCount))")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(StorageSenseTheme.Spacing.md)
            }
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingReview) {
            ReviewDeleteView(
                assets: categoryAssets.filter { selectedIdentifiers.contains($0.id) },
                onDeleted: {
                    selectedIdentifiers.removeAll()
                    isPresentingReview = false
                }
            )
        }
    }

    private func toggle(_ asset: AssetSummary) {
        if selectedIdentifiers.contains(asset.id) {
            selectedIdentifiers.remove(asset.id)
        } else {
            selectedIdentifiers.insert(asset.id)
        }
    }
}

/// A single grid cell: fetches its own thumbnail on appear via PHImageManager
/// rather than the caller pre-loading everything up front, since a category
/// can contain thousands of assets.
private struct ThumbnailCell: View {
    let asset: AssetSummary
    let isSelected: Bool

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.quaternary)
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .tint)
                    .padding(4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
        )
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard thumbnail == nil,
              let phAsset = PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil).firstObject else { return }

        let options = PHImageRequestOptions()
        // .highQualityFormat guarantees exactly one completion callback —
        // .opportunistic can call back twice (a fast low-quality pass, then a
        // higher-quality one), which would double-resume the continuation
        // below and crash.
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let size = CGSize(width: 180, height: 180)
        thumbnail = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
