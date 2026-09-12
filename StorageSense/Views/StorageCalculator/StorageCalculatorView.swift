import SwiftUI
import SwiftData

/// A manual iCloud-tier calculator. StorageSense cannot read the user's
/// actual iCloud usage or plan — that's a private API — so every number here
/// is arithmetic on what the user typed in, and the copy must say so plainly
/// (see CLAUDE.md, golden rule 4). Never rename this to imply automatic
/// detection.
struct StorageCalculatorView: View {
    struct Tier: Identifiable, Equatable {
        let name: String
        let gigabytes: Double
        var id: String { name }
    }

    static let tiers: [Tier] = [
        Tier(name: "5 GB (free)", gigabytes: 5),
        Tier(name: "50 GB", gigabytes: 50),
        Tier(name: "200 GB", gigabytes: 200),
        Tier(name: "2 TB", gigabytes: 2_000),
        Tier(name: "6 TB", gigabytes: 6_000),
        Tier(name: "12 TB", gigabytes: 12_000),
    ]

    @Query(sort: \ScanResult.scannedAt, order: .reverse) private var scanResults: [ScanResult]

    @State private var currentTierIndex = 2 // 200 GB, the most common paid tier
    @State private var currentUsageGB: Double?
    @State private var wouldFreeGB: Double?
    @State private var didPrefill = false
    @FocusState private var focusedField: Field?

    private enum Field { case usage, free }

    private var currentTier: Tier { Self.tiers[currentTierIndex] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.md) {
                manualEntryNote

                group("Your iCloud now") {
                    HStack {
                        Text("Plan")
                            .foregroundStyle(StorageSenseTheme.textPrimary)
                        Spacer()
                        Picker("Plan", selection: $currentTierIndex) {
                            ForEach(Self.tiers.indices, id: \.self) { index in
                                Text(Self.tiers[index].name).tag(index)
                            }
                        }
                        .tint(StorageSenseTheme.accent)
                    }
                    .frame(minHeight: StorageSenseTheme.minimumTapTarget)
                    divider
                    numberRow("Currently using", value: $currentUsageGB, field: .usage)
                }

                group("What you'd free") {
                    numberRow("Space to free", value: $wouldFreeGB, field: .free)
                    if didPrefill, let top = topCategory {
                        Text("Prefilled from your \(top.category.displayName.lowercased()) total — change it to anything.")
                            .font(StorageSenseTheme.Font.caption)
                            .foregroundStyle(StorageSenseTheme.textSecondary)
                    }
                }

                result
            }
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            .padding(.bottom, StorageSenseTheme.Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .navigationTitle("iCloud calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onAppear(perform: prefill)
    }

    // MARK: Sections

    private var manualEntryNote: some View {
        HStack(alignment: .top, spacing: StorageSenseTheme.Spacing.sm) {
            Image(systemName: "pencil.line")
                .foregroundStyle(StorageSenseTheme.caution)
                .accessibilityHidden(true)
            Text("These numbers come from what you type in. StorageSense can't read your iCloud plan or usage. Find them in Settings → your name → iCloud.")
                .font(StorageSenseTheme.Font.caption)
                .foregroundStyle(StorageSenseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StorageSenseTheme.caution.opacity(0.12), in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.button, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.button, style: .continuous).strokeBorder(StorageSenseTheme.caution.opacity(0.4), lineWidth: 1))
        .padding(.top, StorageSenseTheme.Spacing.sm)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(StorageSenseTheme.Font.eyebrow)
                .foregroundStyle(StorageSenseTheme.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private var divider: some View {
        Rectangle().fill(StorageSenseTheme.surfaceBorder).frame(height: 1)
    }

    private func numberRow(_ label: String, value: Binding<Double?>, field: Field) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(StorageSenseTheme.textPrimary)
            Spacer()
            TextField("0", value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(StorageSenseTheme.Font.stat)
                .foregroundStyle(StorageSenseTheme.accent)
                .frame(width: 90)
                .focused($focusedField, equals: field)
                .accessibilityLabel("\(label), in gigabytes")
            Text("GB")
                .font(StorageSenseTheme.Font.caption)
                .foregroundStyle(StorageSenseTheme.textSecondary)
        }
        .frame(minHeight: StorageSenseTheme.minimumTapTarget)
    }

    private var result: some View {
        let usage = currentUsageGB ?? 0
        let free = wouldFreeGB ?? 0
        let projected = Self.projectedUsage(current: usage, freeing: free)
        let fits = Self.cheapestTier(for: projected)
        let fraction = currentTier.gigabytes > 0 ? min(projected / currentTier.gigabytes, 1) : 0

        return VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            Text("After freeing \(Self.gb(free))".uppercased())
                .font(StorageSenseTheme.Font.eyebrow)
                .foregroundStyle(StorageSenseTheme.accent)
            HStack(alignment: .firstTextBaseline, spacing: StorageSenseTheme.Spacing.sm) {
                Text(Self.gb(projected))
                    .font(StorageSenseTheme.Font.display)
                    .foregroundStyle(StorageSenseTheme.textPrimary)
                Text("of \(currentTier.name)")
                    .font(StorageSenseTheme.Font.secondary)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(StorageSenseTheme.ringTrack)
                    Capsule().fill(StorageSenseTheme.accent).frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
            Text(Self.verdict(projected: projected, current: currentTier, fits: fits))
                .font(StorageSenseTheme.Font.secondary)
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(StorageSenseTheme.Spacing.md + 2)
        .background(StorageSenseTheme.winGradient, in: RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: StorageSenseTheme.CornerRadius.card, style: .continuous).strokeBorder(StorageSenseTheme.accent.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: Arithmetic (pure, unit-tested)

    static func projectedUsage(current: Double, freeing: Double) -> Double {
        max(0, current - max(0, freeing))
    }

    static func cheapestTier(for usageGB: Double) -> Tier? {
        tiers.first { $0.gigabytes >= usageGB }
    }

    static func verdict(projected: Double, current: Tier, fits: Tier?) -> String {
        guard let fits else {
            return "That's more than the largest iCloud plan — the calculator can only go up to \(tiers.last?.name ?? "")."
        }
        if projected > current.gigabytes {
            return "That's still over the \(current.name) plan by \(gb(projected - current.gigabytes))."
        }
        let headroom = current.gigabytes - projected
        if fits.gigabytes < current.gigabytes {
            return "You could drop to the \(fits.name) plan with \(gb(fits.gigabytes - projected)) to spare."
        }
        if let nextDown = tiers.last(where: { $0.gigabytes < current.gigabytes }) {
            let needed = projected - nextDown.gigabytes
            return "You'd stay on the \(current.name) plan, with \(gb(headroom)) headroom. Freeing \(gb(needed)) more would fit the \(nextDown.name) plan."
        }
        return "You'd stay on the \(current.name) plan, with \(gb(headroom)) headroom."
    }

    static func gb(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1)))) GB"
    }

    private var topCategory: RecommendationEngine.Recommendation? {
        guard let scan = scanResults.first else { return nil }
        return RecommendationEngine.topRecommendation(from: scan.categoryTotals)
    }

    private func prefill() {
        guard !didPrefill, wouldFreeGB == nil, let top = topCategory else { return }
        let gigabytes = (Double(top.byteCount) / 1_000_000_000 * 10).rounded() / 10
        // Only worth prefilling when the top category is at least 0.1 GB —
        // otherwise "0 GB" reads like a broken calculation.
        guard gigabytes >= 0.1 else { return }
        wouldFreeGB = gigabytes
        didPrefill = true
    }
}

#Preview {
    let container = try! ModelContainer(for: ScanResult.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(DemoData.scanResult())
    return NavigationStack {
        StorageCalculatorView()
    }
    .modelContainer(container)
}
