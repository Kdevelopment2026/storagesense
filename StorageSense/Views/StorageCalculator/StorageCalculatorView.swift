import SwiftUI

/// A manual iCloud-tier calculator. StorageSense cannot read the user's
/// actual iCloud usage or plan — that's a private API — so every number here
/// is arithmetic on what the user typed in, and the copy must say so plainly
/// (see CLAUDE.md, golden rule 4). Never rename this to imply automatic
/// detection.
struct StorageCalculatorView: View {
    private static let tiers: [(name: String, gigabytes: Double)] = [
        ("5GB (Free)", 5),
        ("50GB", 50),
        ("200GB", 200),
        ("2TB", 2_000),
        ("6TB", 6_000),
        ("12TB", 12_000),
    ]

    @State private var currentUsageGB: Double = 0
    @State private var currentTierIndex = 2 // 200GB, the most common paid tier
    @State private var wouldFreeGB: Double = 0

    private var projectedUsageGB: Double {
        max(0, currentUsageGB - wouldFreeGB)
    }

    private var projectedTier: (name: String, gigabytes: Double)? {
        Self.tiers.first { $0.gigabytes >= projectedUsageGB }
    }

    var body: some View {
        Form {
            Section {
                Text("These numbers come from what you enter below — StorageSense can't read your actual iCloud plan or usage automatically. Check Settings → [your name] → iCloud → Manage Account Storage for your current numbers.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Your current iCloud storage") {
                Picker("Current plan", selection: $currentTierIndex) {
                    ForEach(Self.tiers.indices, id: \.self) { index in
                        Text(Self.tiers[index].name).tag(index)
                    }
                }
                HStack {
                    Text("Currently using")
                    Spacer()
                    TextField("GB", value: $currentUsageGB, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("GB")
                        .foregroundStyle(.secondary)
                }
            }

            Section("What StorageSense would free") {
                HStack {
                    Text("Space to free")
                    Spacer()
                    TextField("GB", value: $wouldFreeGB, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("GB")
                        .foregroundStyle(.secondary)
                }
            }

            Section("After freeing that space") {
                LabeledContent("New usage", value: "\(projectedUsageGB.formatted(.number.precision(.fractionLength(1)))) GB")
                if let projectedTier, projectedTier.gigabytes < Self.tiers[currentTierIndex].gigabytes {
                    Label("You could drop to the \(projectedTier.name) plan", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("This wouldn't change which plan you need.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Storage calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StorageCalculatorView()
    }
}
