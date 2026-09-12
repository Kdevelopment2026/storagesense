import SwiftUI
import SwiftData

@main
struct StorageSenseApp: App {
    @AppStorage("storagesense.appearance") private var appearanceRawValue: String = AppearanceOption.system.rawValue

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ScanResult.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create StorageSense's on-device data store: \(error)")
        }
    }()

    private var appearance: AppearanceOption {
        AppearanceOption(rawValue: appearanceRawValue) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
