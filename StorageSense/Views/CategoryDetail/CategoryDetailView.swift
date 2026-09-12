import SwiftUI

/// Thumbnail grid for one category, with a running "selected to delete"
/// total. Nothing here deletes anything directly — selecting only queues
/// assets for the explicit confirm step in ReviewDeleteView
/// (see CLAUDE.md, golden rule 3). Assets always come fresh from the
/// scanner's current enumeration, never from a stored copy.
struct CategoryDetailView: View {
    let category: PhotoCategory
    var scanner: PhotoLibraryScanner
    /// Preview-only injection so the grid renders without PhotoKit.
    var previewAssets: [AssetSummary]? = nil

    enum SortOrder: String, CaseIterable, Identifiable {
        case largest = "Largest first"
        case newest = "Newest"
        case oldest = "Oldest"
        var id: String { rawValue }
    }

    @State private var assets: [AssetSummary] = []
    @State private var isLoading = true
    @State private var sortOrder: SortOrder = .largest
    @State private var selectedIdentifiers: Set<String> = []
    @State private var isPresentingReview = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var proStatus: ProStatus { .shared }

    private var sortedAssets: [AssetSummary] {
        switch sortOrder {
        case .largest: return assets.sorted { $0.byteCount > $1.byteCount }
        case .newest: return assets.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .oldest: return assets.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        }
    }

    private var totalBytes: Int64 { assets.reduce(0) { $0 + $1.byteCount } }
    private var selectedAssets: [AssetSummary] { assets.filter { selectedIdentifiers.contains($0.id) } }
    private var selectedByteCount: Int64 { selectedAssets.reduce(0) { $0 + $1.byteCount } }

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.md) {
                    header
                    if isLoading {
                        ProgressView()
                            .tint(StorageSenseTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, StorageSenseTheme.Spacing.xl)
                    } else if assets.isEmpty {
                        Text("Nothing in this category right now.")
                            .font(StorageSenseTheme.Font.secondary)
                            .foregroundStyle(StorageSenseTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, StorageSenseTheme.Spacing.xl)
                    } else {
                        sortPills
                        if category == .burstDuplicate {
                            duplicateGroups
                        } else {
                            grid(for: sortedAssets)
                        }
                    }
                }
                .padding(.horizontal, StorageSenseTheme.Spacing.lg)
                .padding(.bottom, StorageSenseTheme.Spacing.xl)
            }

            if !selectedIdentifiers.isEmpty {
                selectionFooter
                    .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(StorageSenseTheme.animation(reduceMotion: reduceMotion), value: selectedIdentifiers.isEmpty)
        .screenBackground()
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if proStatus.isUnlocked, !assets.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(selectedIdentifiers.count == assets.count ? "Deselect all" : "Select all") {
                        if selectedIdentifiers.count == assets.count {
                            selectedIdentifiers.removeAll()
                        } else {
                            selectedIdentifiers = Set(assets.map(\.id))
                        }
                    }
                    .font(StorageSenseTheme.Font.secondary)
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $isPresentingReview) {
            ReviewDeleteView(assets: selectedAssets) {
                let deleted = selectedIdentifiers
                assets.removeAll { deleted.contains($0.id) }
                selectedIdentifiers.removeAll()
                isPresentingReview = false
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: StorageSenseTheme.Spacing.sm) {
                Text(ByteFormatter.string(from: totalBytes))
                    .font(StorageSenseTheme.Font.display)
                    .foregroundStyle(StorageSenseTheme.textPrimary)
                Text("\(assets.count.formatted()) items")
                    .font(StorageSenseTheme.Font.secondary)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Text(category.explanation)
                .font(StorageSenseTheme.Font.secondary)
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, StorageSenseTheme.Spacing.sm)
    }

    private var sortPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: StorageSenseTheme.Spacing.sm) {
                ForEach(SortOrder.allCases) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        Text(order.rawValue)
                            .font(StorageSenseTheme.Font.caption.weight(.medium))
                            .foregroundStyle(sortOrder == order ? StorageSenseTheme.accent : StorageSenseTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: StorageSenseTheme.minimumTapTarget - 10)
                            .background(
                                Capsule().fill(sortOrder == order ? StorageSenseTheme.accent.opacity(0.14) : StorageSenseTheme.surface)
                            )
                            .overlay(
                                Capsule().strokeBorder(sortOrder == order ? StorageSenseTheme.accent.opacity(0.5) : StorageSenseTheme.surfaceBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(sortOrder == order ? .isSelected : [])
                }
            }
        }
        .accessibilityLabel("Sort order")
    }

    private func grid(for items: [AssetSummary]) -> some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(items) { asset in
                ThumbnailCell(asset: asset, isSelected: selectedIdentifiers.contains(asset.id))
                    .onTapGesture { toggle(asset) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(category.displayName) item, \(ByteFormatter.spoken(asset.byteCount))\(asset.creationDate.map { ", \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "")")
                    .accessibilityAddTraits(selectedIdentifiers.contains(asset.id) ? [.isButton, .isSelected] : [.isButton])
                    .accessibilityHint(selectedIdentifiers.contains(asset.id) ? "Deselects" : "Selects for review")
            }
        }
    }

    /// Bursts are shown as groups so the user can keep one and select the
    /// rest — "obvious duplicates" only, per DuplicateDetector's scope.
    private var duplicateGroups: some View {
        let groups = DuplicateDetector.groups(in: sortedAssets)
        let grouped = Set(groups.flatMap { $0.assets.map(\.id) })
        let loose = sortedAssets.filter { !grouped.contains($0.id) }
        return VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.lg) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
                    HStack {
                        Text("\(group.assets.count) shots taken together")
                            .font(StorageSenseTheme.Font.eyebrow)
                            .foregroundStyle(StorageSenseTheme.textSecondary)
                        Spacer()
                        Button("Keep largest, select rest") {
                            let keep = group.assets.max { $0.byteCount < $1.byteCount }?.id
                            for asset in group.assets where asset.id != keep {
                                selectedIdentifiers.insert(asset.id)
                            }
                        }
                        .font(StorageSenseTheme.Font.caption.weight(.medium))
                        .foregroundStyle(StorageSenseTheme.accent)
                        .frame(minHeight: StorageSenseTheme.minimumTapTarget - 12)
                    }
                    grid(for: group.assets)
                }
            }
            if !loose.isEmpty {
                Text("Not part of a burst")
                    .font(StorageSenseTheme.Font.eyebrow)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                grid(for: loose)
            }
        }
    }

    private var selectionFooter: some View {
        VStack(spacing: StorageSenseTheme.Spacing.sm) {
            HStack {
                Text("\(selectedIdentifiers.count) selected")
                    .font(StorageSenseTheme.Font.secondary)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                Spacer()
                Text(ByteFormatter.string(from: selectedByteCount))
                    .font(StorageSenseTheme.Font.stat)
                    .foregroundStyle(StorageSenseTheme.textPrimary)
            }
            .accessibilityElement(children: .combine)
            Button("Review \(selectedIdentifiers.count) \(selectedIdentifiers.count == 1 ? "item" : "items")") {
                isPresentingReview = true
            }
            .buttonStyle(.primary)
        }
        .padding(.horizontal, StorageSenseTheme.Spacing.lg)
        .padding(.top, StorageSenseTheme.Spacing.md)
        .padding(.bottom, StorageSenseTheme.Spacing.sm)
        .background(StorageSenseTheme.groundBottom.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle().fill(StorageSenseTheme.surfaceBorder).frame(height: 1)
        }
    }

    // MARK: Actions

    private func load() async {
        if let previewAssets {
            assets = previewAssets
        } else {
            assets = await scanner.assets(in: category)
        }
        isLoading = false
    }

    private func toggle(_ asset: AssetSummary) {
        if selectedIdentifiers.contains(asset.id) {
            selectedIdentifiers.remove(asset.id)
        } else {
            selectedIdentifiers.insert(asset.id)
        }
    }
}

#Preview("Videos") {
    NavigationStack {
        CategoryDetailView(category: .video, scanner: PhotoLibraryScanner(), previewAssets: DemoData.assets(in: .video))
    }
}

#Preview("Bursts") {
    NavigationStack {
        CategoryDetailView(category: .burstDuplicate, scanner: PhotoLibraryScanner(), previewAssets: DemoData.assets(in: .burstDuplicate, count: 9))
    }
}

#Preview("Empty") {
    NavigationStack {
        CategoryDetailView(category: .largeFile, scanner: PhotoLibraryScanner(), previewAssets: [])
    }
}
