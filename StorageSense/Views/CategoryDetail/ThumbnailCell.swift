import SwiftUI
import Photos

/// A single grid cell: fetches its own thumbnail on appear via PHImageManager
/// rather than the caller pre-loading everything up front, since a category
/// can contain thousands of assets. Demo identifiers (previews) render a
/// tinted placeholder instead of hitting PhotoKit.
struct ThumbnailCell: View {
    let asset: AssetSummary
    let isSelected: Bool

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // A square placeholder sized by the grid; the image is drawn as an
            // overlay so `.fill` scaling can't push the cell wider than its column.
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(StorageSenseTheme.color(for: asset.category).opacity(0.18))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.thumbnail, style: .continuous))

            Circle()
                .fill(isSelected ? StorageSenseTheme.accent : StorageSenseTheme.groundBottom.opacity(0.55))
                .overlay(Circle().strokeBorder(isSelected ? StorageSenseTheme.accent : Color.white.opacity(0.7), lineWidth: 1))
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(StorageSenseTheme.onAccent)
                    }
                }
                .frame(width: 22, height: 22)
                .padding(6)
        }
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 3) {
                if asset.category == .video || asset.category == .livePhoto {
                    Image(systemName: asset.category == .video ? "video.fill" : "livephoto")
                        .font(.system(size: 9))
                }
                Text(ByteFormatter.string(from: asset.byteCount))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 4))
            .padding(6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.thumbnail, style: .continuous)
                .strokeBorder(isSelected ? StorageSenseTheme.accent : StorageSenseTheme.surfaceBorder, lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard thumbnail == nil, !asset.id.hasPrefix("demo-"),
              let phAsset = PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil).firstObject else { return }

        let options = PHImageRequestOptions()
        // .highQualityFormat guarantees exactly one completion callback —
        // .opportunistic can call back twice (a fast low-quality pass, then a
        // higher-quality one), which would double-resume the continuation
        // below and crash.
        options.deliveryMode = .highQualityFormat
        // Offline-first (golden rule 5): never pull originals from iCloud
        // just to draw a thumbnail; PhotoKit still serves the local preview.
        options.isNetworkAccessAllowed = false

        let size = CGSize(width: 220, height: 220)
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

#Preview {
    HStack {
        ThumbnailCell(asset: DemoData.assets(in: .video, count: 1)[0], isSelected: true)
        ThumbnailCell(asset: DemoData.assets(in: .screenshot, count: 1)[0], isSelected: false)
    }
    .padding()
    .screenBackground()
}
