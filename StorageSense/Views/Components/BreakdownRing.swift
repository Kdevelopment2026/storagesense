import SwiftUI
import Charts

/// The Observatory ring: a thin segmented donut with the library total in
/// the centre. Colour is never the only signal — the chips beneath it on
/// Home repeat every label and byte value, and VoiceOver gets a full chart
/// descriptor (CLAUDE.md, golden rule 9).
struct BreakdownRing: View {
    let totals: [CategoryTotal]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    private var totalBytes: Int64 { totals.reduce(0) { $0 + $1.byteCount } }
    private var totalCount: Int { totals.reduce(0) { $0 + $1.assetCount } }
    private var ranked: [CategoryTotal] { totals.sorted { $0.byteCount > $1.byteCount } }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [StorageSenseTheme.accent.opacity(0.22), StorageSenseTheme.accent.opacity(0)],
                        center: .center, startRadius: 40, endRadius: 150
                    )
                )
                .accessibilityHidden(true)

            Chart(ranked) { total in
                SectorMark(
                    angle: .value("Bytes", isRevealed ? total.byteCount : 0),
                    innerRadius: .ratio(0.82),
                    angularInset: 1.5
                )
                .cornerRadius(3)
                .foregroundStyle(StorageSenseTheme.color(for: total.category))
                .accessibilityLabel(total.category.displayName)
                .accessibilityValue("\(total.assetCount) items, \(ByteFormatter.spoken(total.byteCount))")
            }
            .chartLegend(.hidden)
            .chartBackground { _ in
                Circle()
                    .strokeBorder(StorageSenseTheme.ringTrack, lineWidth: 18)
                    .padding(1)
            }
            .chartOverlay { _ in
                VStack(spacing: StorageSenseTheme.Spacing.xs) {
                    Text(ByteFormatter.string(from: totalBytes))
                        .font(StorageSenseTheme.Font.display)
                        .foregroundStyle(StorageSenseTheme.textPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("\(totalCount.formatted()) items")
                        .font(StorageSenseTheme.Font.secondary)
                        .foregroundStyle(StorageSenseTheme.textSecondary)
                }
                .padding(StorageSenseTheme.Spacing.xl)
                .accessibilityElement(children: .combine)
            }
            .accessibilityChartDescriptor(BreakdownChartDescriptor(totals: ranked))
            .padding(StorageSenseTheme.Spacing.md)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(StorageSenseTheme.animation(.easeOut(duration: 0.8), reduceMotion: reduceMotion)) {
                isRevealed = true
            }
        }
    }
}

/// Text-equivalent breakdown for VoiceOver, so the chart is never the only
/// way to read the data.
private struct BreakdownChartDescriptor: AXChartDescriptorRepresentable {
    let totals: [CategoryTotal]

    func makeChartDescriptor() -> AXChartDescriptor {
        let totalBytes = totals.reduce(0) { $0 + $1.byteCount }
        let categoryAxis = AXCategoricalDataAxisDescriptor(
            title: "Category",
            categoryOrder: totals.map { $0.category.displayName }
        )
        let byteAxis = AXNumericDataAxisDescriptor(
            title: "Size",
            range: 0...Double(max(totalBytes, 1)),
            gridlinePositions: []
        ) { value in ByteFormatter.spoken(Int64(value)) }

        let series = AXDataSeriesDescriptor(
            name: "Photos library breakdown",
            isContinuous: false,
            dataPoints: totals.map { total in
                AXDataPoint(x: total.category.displayName, y: Double(total.byteCount))
            }
        )

        return AXChartDescriptor(
            title: "Photos library breakdown",
            summary: "\(ByteFormatter.spoken(totalBytes)) across \(totals.count) categories.",
            xAxis: categoryAxis,
            yAxis: byteAxis,
            series: [series]
        )
    }
}

#Preview("Medium") {
    BreakdownRing(totals: DemoData.totals(.medium))
        .padding()
        .screenBackground()
}

#Preview("Small") {
    BreakdownRing(totals: DemoData.totals(.small))
        .padding()
        .screenBackground()
}
