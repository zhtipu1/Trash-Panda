import SwiftUI

/// Top-level view: onboarding vs. main sidebar + content, plus the shared toast overlay.
/// Ported from the #onboarding / #app split in the original frontend.
struct RootView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var appListViewModel = AppListViewModel()
    @StateObject private var orphanListViewModel = OrphanListViewModel()

    @State private var showOnboarding: Bool
    @State private var selectedTab: SidebarTab = .apps

    init() {
        _showOnboarding = State(initialValue: AppSettings.shared.showOnboarding)
    }

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(settings: settings) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }

            ToastOverlay(toast: appListViewModel.toast ?? orphanListViewModel.toast)
        }
        .background(Theme.bg)
        .onChange(of: appListViewModel.apps) { _ in
            orphanListViewModel.invalidate()
        }
    }

    private var mainContent: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab, orphanBadgeCount: orphanListViewModel.safeOrphans.count)
        } detail: {
            switch selectedTab {
            case .apps:
                AppsView(viewModel: appListViewModel, scanOptions: settings.scanOptions)
            case .orphans:
                OrphansView(
                    viewModel: orphanListViewModel,
                    installedApps: appListViewModel.apps,
                    scanGroupContainers: settings.scanGroupContainers
                )
            case .about:
                AboutView()
            }
        }
        .background(Theme.bg)
        .foregroundColor(Theme.text)
    }
}
