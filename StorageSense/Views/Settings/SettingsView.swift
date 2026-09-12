import SwiftUI
import SwiftData
import Photos

/// Re-scan, permission status, the calculator, appearance, the privacy
/// statement and restore purchase. Restore is wired through ProStatus only —
/// no StoreKit calls live in views (CLAUDE.md, golden rule 8).
struct SettingsView: View {
    var scanner: PhotoLibraryScanner

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanResult.scannedAt, order: .reverse) private var scanResults: [ScanResult]
    @AppStorage("storagesense.appearance") private var appearanceRawValue: String = AppearanceOption.system.rawValue

    private var proStatus: ProStatus { .shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.lg) {
                section("Library") {
                    Button {
                        Task { await ScanStore.rescan(using: scanner, in: modelContext) }
                    } label: {
                        row(icon: "arrow.clockwise", label: scanner.isScanning ? "Scanning…" : "Re-scan Photos library", value: lastScannedLabel)
                    }
                    .disabled(scanner.isScanning)
                    divider
                    if scanner.authorizationStatus == .authorized {
                        row(icon: "photo.on.rectangle", label: "Photos access", value: permissionLabel, chevron: false)
                    } else {
                        Button(action: openSystemSettings) {
                            row(icon: "photo.on.rectangle", label: "Photos access", value: permissionLabel)
                        }
                        .accessibilityHint("Opens iOS Settings to change Photos access")
                    }
                }

                section("Tools") {
                    NavigationLink {
                        StorageCalculatorView()
                    } label: {
                        row(icon: "plus.forwardslash.minus", label: "iCloud calculator", value: "Manual entry")
                    }
                }

                section("Appearance") {
                    HStack(spacing: StorageSenseTheme.Spacing.sm + 4) {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundStyle(StorageSenseTheme.accent)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                        Picker("Appearance", selection: $appearanceRawValue) {
                            ForEach(AppearanceOption.allCases) { option in
                                Text(option.label).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .frame(minHeight: StorageSenseTheme.minimumTapTarget)
                }

                section("Privacy") {
                    VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
                        Text("StorageSense reads your Photos library on-device to build the breakdown you see. Nothing is uploaded, no account is required, and no usage data is collected or shared.")
                            .font(StorageSenseTheme.Font.secondary)
                            .foregroundStyle(StorageSenseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Label("Data Not Collected", systemImage: "checkmark.shield")
                            .font(StorageSenseTheme.Font.eyebrow)
                            .foregroundStyle(StorageSenseTheme.success)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(StorageSenseTheme.success.opacity(0.12), in: Capsule())
                    }
                }

                section("Pro") {
                    Button {
                        Task { await proStatus.restorePurchases() }
                    } label: {
                        row(icon: "arrow.counterclockwise", label: "Restore purchase", value: proStatus.isUnlocked ? "Unlocked" : "")
                    }
                    .accessibilityHint("Checks for a previous purchase")
                }

                Text("StorageSense 1.0 · Photos library only, by design")
                    .font(StorageSenseTheme.Font.caption)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, StorageSenseTheme.Spacing.lg)
            .padding(.vertical, StorageSenseTheme.Spacing.md)
        }
        .screenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { scanner.refreshAuthorizationStatus() }
    }

    // MARK: Building blocks

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: StorageSenseTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(StorageSenseTheme.Font.eyebrow)
                .foregroundStyle(StorageSenseTheme.textSecondary)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceCard(padding: 14)
        }
    }

    private var divider: some View {
        Rectangle().fill(StorageSenseTheme.surfaceBorder).frame(height: 1)
    }

    private func row(icon: String, label: String, value: String, chevron: Bool = true) -> some View {
        HStack(spacing: StorageSenseTheme.Spacing.sm + 4) {
            Image(systemName: icon)
                .foregroundStyle(StorageSenseTheme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(label)
                .font(StorageSenseTheme.Font.body)
                .foregroundStyle(StorageSenseTheme.textPrimary)
                .layoutPriority(1)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(StorageSenseTheme.Font.secondary)
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StorageSenseTheme.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: StorageSenseTheme.minimumTapTarget)
        .contentShape(Rectangle())
    }

    private var lastScannedLabel: String {
        guard let scan = scanResults.first else { return "Never" }
        return scan.scannedAt.formatted(.relative(presentation: .named))
    }

    private var permissionLabel: String {
        switch scanner.authorizationStatus {
        case .authorized: return "Full access"
        case .limited: return "Limited access"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: ScanResult.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(DemoData.scanResult())
    return NavigationStack {
        SettingsView(scanner: PhotoLibraryScanner())
    }
    .modelContainer(container)
}
