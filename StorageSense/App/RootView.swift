import SwiftUI
import Photos

/// Root navigation and the Photos permission gate. Nothing downstream of
/// this view ever needs to think about authorization state directly.
///
/// First launch only: a short intro (Splash → Onboarding) before the
/// pre-permission explanation. Every later launch goes straight to Home.
struct RootView: View {
    @State private var scanner = PhotoLibraryScanner()
    @AppStorage("storagesense.hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if !hasSeenOnboarding, showSplash {
                SplashView { showSplash = false }
            } else if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
            } else {
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
        }
        .animation(StorageSenseTheme.animation(reduceMotion: reduceMotion), value: hasSeenOnboarding)
        .animation(StorageSenseTheme.animation(reduceMotion: reduceMotion), value: showSplash)
        .task {
            scanner.refreshAuthorizationStatus()
        }
    }
}
