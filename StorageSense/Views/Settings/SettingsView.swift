import SwiftUI
import Photos

struct SettingsView: View {
    var scanner: PhotoLibraryScanner
    var onRescan: () async -> Void

    @AppStorage("storagesense.appearance") private var appearanceRawValue: String = AppearanceOption.system.rawValue
    @State private var isRescanning = false

    var body: some View {
        Form {
            Section("Library") {
                Button {
                    Task {
                        isRescanning = true
                        await onRescan()
                        isRescanning = false
                    }
                } label: {
                    if isRescanning {
                        ProgressView()
                    } else {
                        Text("Re-scan Photos library")
                    }
                }
                .disabled(isRescanning)

                LabeledContent("Photos access", value: permissionLabel)
                if scanner.authorizationStatus != .authorized {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            Section("Tools") {
                NavigationLink("Storage calculator") {
                    StorageCalculatorView()
                }
            }

            Section("Appearance") {
                Picker("Appearance", selection: $appearanceRawValue) {
                    ForEach(AppearanceOption.allCases) { option in
                        Text(option.label).tag(option.rawValue)
                    }
                }
            }

            Section("Privacy") {
                Text("StorageSense reads your Photos library on-device to build the breakdown you see. Nothing is uploaded, no account is required, and no usage data is collected or shared.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    NavigationStack {
        SettingsView(scanner: PhotoLibraryScanner(), onRescan: {})
    }
}
