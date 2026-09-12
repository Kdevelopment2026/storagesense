import SwiftUI
import Photos

/// Root navigation and the Photos permission gate. Nothing downstream of
/// this view ever needs to think about authorization state directly.
struct RootView: View {
    @State private var scanner = PhotoLibraryScanner()

    var body: some View {
        Group {
            switch scanner.authorizationStatus {
            case .authorized, .limited:
                NavigationStack {
                    HomeView(scanner: scanner)
                }
            case .denied, .restricted:
                PermissionDeniedView()
            case .notDetermined:
                PermissionView(scanner: scanner)
            @unknown default:
                PermissionView(scanner: scanner)
            }
        }
        .task {
            scanner.refreshAuthorizationStatus()
        }
    }
}
