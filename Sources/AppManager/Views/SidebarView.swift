import SwiftUI

enum SidebarTab: String, CaseIterable, Identifiable, Hashable {
    case apps, orphans, about
    var id: String { rawValue }

    var label: String {
        switch self {
        case .apps: return "Apps"
        case .orphans: return "Orphaned"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .apps: return "square.grid.2x2"
        case .orphans: return "trash"
        case .about: return "info.circle"
        }
    }
}

/// A native sidebar list — selection, hover, and materials all come from `List`/`.sidebar` style
/// for free, instead of hand-rolled row backgrounds.
struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    let orphanBadgeCount: Int

    var body: some View {
        List(selection: $selectedTab) {
            ForEach(SidebarTab.allCases) { tab in
                Label(tab.label, systemImage: tab.systemImage)
                    .badge(tab == .orphans ? orphanBadgeCount : 0)
                    .tag(tab)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 8) {
                Text("🐼").font(.system(size: 18))
                Text("Trash Panda").font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
    }
}
