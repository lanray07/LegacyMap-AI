import SwiftUI

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            LegacyBackground()
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

private enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case map
    case scan
    case archive
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .map: "Explore"
        case .scan: "Scan"
        case .archive: "Archive"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .map: "map"
        case .scan: "camera.viewfinder"
        case .archive: "archivebox"
        case .settings: "gearshape"
        }
    }

    @ViewBuilder
    var content: some View {
        switch self {
        case .dashboard:
            DashboardView()
        case .map:
            CemeteryExplorerView()
        case .scan:
            HeadstoneScannerView()
        case .archive:
            HistoricalTimelineView()
        case .settings:
            SettingsView()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tab.content
                        .navigationTitle(tab.title)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .tint(.legacyGold)
    }
}
