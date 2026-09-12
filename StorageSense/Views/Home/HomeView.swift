import SwiftUI
import SwiftData
import Charts

/// The whole diagnostic in one screen: the breakdown chart, the single
/// biggest-win recommendation, and entry points into each category. Never
/// gated behind ProStatus — see CLAUDE.md, golden rule 2.
struct HomeView: View {
    var scanner: PhotoLibraryScanner

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanResult.scannedAt, order: .reverse) private var scanResults: [ScanResult]
    @State private var latestAssets: [AssetSummary] = []
    @State private var isScanning = false

    private var latestScan: ScanResult? { scanResults.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.lg) {
                if let scan = latestScan {
                    breakdownCard(for: scan)
                    if let recommendation = RecommendationEngine.topRecommendation(from: scan.categoryTotals) {
                        biggestWinCard(recommendation)
                    }
                    categoryList(for: scan)
                    lastScannedFooter(scan)
                } else if isScanning {
                    ProgressView("Scanning your Photos library…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, StorageSenseTheme.Spacing.xl)
                } else {
                    emptyState
                }
            }
            .padding(StorageSenseTheme.Spacing.md)
        }
        .navigationTitle("StorageSense")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(scanner: scanner, onRescan: { await performScan() })
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .task {
            if latestScan == nil {
                await performScan()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: StorageSenseTheme.Spacing.md) {
            Text("No scan yet")
                .font(.title3.bold())
            Button("Scan my Photos library") {
                Task { await performScan() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, StorageSenseTheme.Spacing.xl)
    }

    private func breakdownCard(for scan: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            Text("Your Photos library")
                .font(.headline)
            Text(ByteFormatter.string(from: scan.totalByteCount))
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Chart(scan.categoryTotals) { total in
                SectorMark(
                    angle: .value("Bytes", total.byteCount),
                    innerRadius: .ratio(0.6)
                )
                .foregroundStyle(StorageSenseTheme.color(for: total.category))
                .accessibilityLabel(total.category.displayName)
                .accessibilityValue(ByteFormatter.string(from: total.byteCount))
            }
            .frame(height: 200)
            // Colour is never the only signal — every segment also has a
            // labelled legend row below (golden rule 9).
            .accessibilityChartDescriptor(BreakdownChartDescriptor(scan: scan))

            VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.xs) {
                ForEach(scan.categoryTotals.sorted(by: { $0.byteCount > $1.byteCount })) { total in
                    HStack {
                        Circle()
                            .fill(StorageSenseTheme.color(for: total.category))
                            .frame(width: 10, height: 10)
                        Text(total.category.displayName)
                        Spacer()
                        Text(ByteFormatter.string(from: total.byteCount))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(StorageSenseTheme.Spacing.md)
        .background(StorageSenseTheme.cardBackground, in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card))
    }

    private func biggestWinCard(_ recommendation: RecommendationEngine.Recommendation) -> some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.xs) {
            Label("Biggest win", systemImage: "arrow.down.right.circle.fill")
                .font(.headline)
                .foregroundStyle(.tint)
            Text(recommendation.headline)
                .font(.body)
            Text(recommendation.category.explanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(StorageSenseTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StorageSenseTheme.cardBackground, in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card))
    }

    private func categoryList(for scan: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            Text("By category")
                .font(.headline)
            ForEach(RecommendationEngine.rankedRecommendations(from: scan.categoryTotals), id: \.category) { recommendation in
                NavigationLink {
                    CategoryDetailView(category: recommendation.category, assets: latestAssets)
                } label: {
                    HStack {
                        Image(systemName: recommendation.category.systemImageName)
                            .foregroundStyle(StorageSenseTheme.color(for: recommendation.category))
                            .frame(width: 28)
                        VStack(alignment: .leading) {
                            Text(recommendation.category.displayName)
                            Text("\(recommendation.assetCount) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(ByteFormatter.string(from: recommendation.byteCount))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private func lastScannedFooter(_ scan: ScanResult) -> some View {
        HStack {
            Text("Last scanned \(scan.scannedAt.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Re-scan") {
                Task { await performScan() }
            }
            .font(.caption)
        }
        .padding(.top, StorageSenseTheme.Spacing.sm)
    }

    private func performScan() async {
        isScanning = true
        let (totals, assets) = await scanner.scan()
        latestAssets = assets
        let result = ScanResult(scannedAt: .now, categoryTotals: totals)
        modelContext.insert(result)
        // Keep only the latest scan cached — StorageSense never needs scan
        // history, only "what does the library look like right now."
        for old in scanResults {
            modelContext.delete(old)
        }
        isScanning = false
    }
}

/// Text-equivalent breakdown for VoiceOver, so the chart is never the only
/// way to read the data (golden rule 9).
private struct BreakdownChartDescriptor: AXChartDescriptorRepresentable {
    let scan: ScanResult

    func makeChartDescriptor() -> AXChartDescriptor {
        let categoryAxis = AXCategoricalDataAxisDescriptor(
            title: "Category",
            categoryOrder: scan.categoryTotals.map { $0.category.displayName }
        )
        let byteAxis = AXNumericDataAxisDescriptor(
            title: "Bytes",
            range: 0...Double(scan.totalByteCount),
            gridlinePositions: []
        ) { value in ByteFormatter.string(from: Int64(value)) }

        let series = AXDataSeriesDescriptor(
            name: "Storage breakdown",
            isContinuous: false,
            dataPoints: scan.categoryTotals.map { total in
                AXDataPoint(x: total.category.displayName, y: Double(total.byteCount))
            }
        )

        return AXChartDescriptor(
            title: "Storage breakdown",
            summary: nil,
            xAxis: categoryAxis,
            yAxis: byteAxis,
            series: [series]
        )
    }
}
