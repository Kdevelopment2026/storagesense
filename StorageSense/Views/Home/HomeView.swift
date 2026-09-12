import SwiftUI
import SwiftData
import Photos

/// The whole diagnostic in one screen: the breakdown ring, one chip per
/// category, and the single biggest-win recommendation. Never gated behind
/// ProStatus — see CLAUDE.md, golden rule 2.
struct HomeView: View {
    var scanner: PhotoLibraryScanner

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanResult.scannedAt, order: .reverse) private var scanResults: [ScanResult]
    @State private var selectedCategory: PhotoCategory?

    private var latestScan: ScanResult? { scanResults.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.lg) {
                header

                if scanner.authorizationStatus == .limited {
                    limitedAccessNote
                }

                if let scan = latestScan, !scanner.isScanning {
                    BreakdownRing(totals: scan.categoryTotals)
                        .revealOnAppear()
                    categoryGrid(for: scan)
                        .revealOnAppear(delay: 0.08)
                    if let top = RecommendationEngine.topRecommendation(from: scan.categoryTotals) {
                        BiggestWinCard(
                            recommendation: top,
                            shareOfLibrary: RecommendationEngine.share(of: top.category, in: scan.categoryTotals)
                        ) {
                            selectedCategory = top.category
                        }
                        .revealOnAppear(delay: 0.16)
                    }
                    lastScannedFooter(scan)
                } else if scanner.isScanning {
                    scanningState
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            .padding(.bottom, StorageSenseTheme.Spacing.xl)
        }
        .screenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(scanner: scanner)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(StorageSenseTheme.textSecondary)
                        .frame(width: StorageSenseTheme.minimumTapTarget, height: StorageSenseTheme.minimumTapTarget)
                }
                .accessibilityLabel("Settings")
            }
        }
        .navigationDestination(item: $selectedCategory) { category in
            CategoryDetailView(category: category, scanner: scanner)
        }
        .task {
            if latestScan == nil {
                await ScanStore.rescan(using: scanner, in: modelContext)
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.xs) {
            Text("Your Photos library")
                .font(StorageSenseTheme.Font.title)
                .foregroundStyle(StorageSenseTheme.textPrimary)
            Text(subtitle)
                .font(StorageSenseTheme.Font.secondary)
                .foregroundStyle(StorageSenseTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        if scanner.isScanning { return "Scanning on-device…" }
        if let scan = latestScan {
            return "Scanned \(scan.scannedAt.formatted(.relative(presentation: .named))) · on-device"
        }
        return "Nothing leaves your phone"
    }

    private var limitedAccessNote: some View {
        HStack(alignment: .top, spacing: StorageSenseTheme.Spacing.sm) {
            Image(systemName: "photo.badge.checkmark")
                .foregroundStyle(StorageSenseTheme.caution)
                .accessibilityHidden(true)
            Text("You've shared a selection of photos, not the whole library. The breakdown covers only what you've shared — you can change this in Settings.")
                .font(StorageSenseTheme.Font.caption)
                .foregroundStyle(StorageSenseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .surfaceCard(padding: 14)
    }

    private func categoryGrid(for scan: ScanResult) -> some View {
        let ranked = RecommendationEngine.rankedRecommendations(from: scan.categoryTotals)
        let columns = [GridItem(.flexible(), spacing: StorageSenseTheme.Spacing.sm), GridItem(.flexible(), spacing: StorageSenseTheme.Spacing.sm)]
        return LazyVGrid(columns: columns, spacing: StorageSenseTheme.Spacing.sm) {
            ForEach(ranked, id: \.category) { recommendation in
                Button {
                    selectedCategory = recommendation.category
                } label: {
                    CategoryChip(recommendation: recommendation)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func lastScannedFooter(_ scan: ScanResult) -> some View {
        HStack(alignment: .top) {
            Text("Sizes are measured on this device. Items stored only in iCloud count as 0.")
                .font(StorageSenseTheme.Font.caption)
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                Task { await ScanStore.rescan(using: scanner, in: modelContext) }
            } label: {
                Label("Re-scan", systemImage: "arrow.clockwise")
                    .font(StorageSenseTheme.Font.eyebrow)
                    .foregroundStyle(StorageSenseTheme.accent)
                    .frame(minHeight: StorageSenseTheme.minimumTapTarget)
            }
            .accessibilityLabel("Re-scan Photos library")
        }
    }

    private var scanningState: some View {
        VStack(spacing: StorageSenseTheme.Spacing.md) {
            ProgressView(value: scanner.progress)
                .tint(StorageSenseTheme.accent)
            Text("Reading sizes and types, not the photos themselves.")
                .font(StorageSenseTheme.Font.secondary)
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, StorageSenseTheme.Spacing.xl * 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning your Photos library, \(Int(scanner.progress * 100)) percent")
    }

    private var emptyState: some View {
        VStack(spacing: StorageSenseTheme.Spacing.md) {
            Text("No scan yet")
                .font(StorageSenseTheme.Font.heading)
                .foregroundStyle(StorageSenseTheme.textPrimary)
            Button("Scan my Photos library") {
                Task { await ScanStore.rescan(using: scanner, in: modelContext) }
            }
            .buttonStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, StorageSenseTheme.Spacing.xl)
    }
}

#Preview("Medium library") {
    HomePreviewHost(size: .medium)
}

#Preview("Small library") {
    HomePreviewHost(size: .small)
}

#Preview("Large library") {
    HomePreviewHost(size: .large)
}

/// Seeds an in-memory container so Home renders a real breakdown in previews
/// without touching PhotoKit.
private struct HomePreviewHost: View {
    let size: DemoData.LibrarySize

    var body: some View {
        let container = try! ModelContainer(for: ScanResult.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        container.mainContext.insert(DemoData.scanResult(size))
        return NavigationStack {
            HomeView(scanner: PhotoLibraryScanner())
        }
        .modelContainer(container)
    }
}
