import Foundation

@MainActor
final class AppListViewModel: ObservableObject {
    enum SortMode: String, CaseIterable, Identifiable, Hashable {
        case name, size, cache
        var id: String { rawValue }
        var label: String {
            switch self {
            case .name: return "Name"
            case .size: return "App size"
            case .cache: return "Cache size"
            }
        }
    }

    @Published var apps: [InstalledApp] = []
    @Published var selectedID: String?
    @Published var searchText: String = ""
    @Published var sortMode: SortMode = .name
    @Published var isLoading = false
    @Published var loadFailed = false
    @Published var toast: Toast?

    private var toastTask: Task<Void, Never>?

    /// Re-scans installed apps and their leftover files. Mirrors AppAPI.get_apps.
    func loadApps(options: ScanOptions) async {
        isLoading = true
        loadFailed = false
        selectedID = nil
        let scanned = await Task.detached(priority: .userInitiated) {
            AppScanner.scanApps(options: options)
        }.value
        apps = scanned
        isLoading = false
    }

    var filteredApps: [InstalledApp] {
        let query = searchText.lowercased()
        var list = apps.filter { query.isEmpty || $0.name.lowercased().contains(query) }
        switch sortMode {
        case .name:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .size:
            list.sort { $0.appSizeMB > $1.appSizeMB }
        case .cache:
            list.sort { $0.junkMB > $1.junkMB }
        }
        return list
    }

    var installedApps: [InstalledApp] { filteredApps.filter { $0.appType == .installed } }
    var systemApps: [InstalledApp] { filteredApps.filter { $0.appType == .system } }

    var installedCount: Int { apps.filter { $0.appType == .installed }.count }
    var systemCount: Int { apps.filter { $0.appType == .system }.count }
    var totalStorageMB: Double { apps.reduce(0) { $0 + $1.totalSizeMB } }
    var totalJunkMB: Double { apps.reduce(0) { $0 + $1.junkMB } }

    var selectedApp: InstalledApp? {
        guard let id = selectedID else { return nil }
        return apps.first { $0.id == id }
    }

    /// Locked (self) rows have selection disabled at the List level, but guard here too in case
    /// selection ever ends up pointing at one (e.g. after a re-scan reorders apps).
    func clearSelectionIfLocked() {
        if selectedApp?.locked == true {
            selectedID = nil
        }
    }

    func toggleFile(_ fileID: String, isOn: Bool) {
        guard let idx = apps.firstIndex(where: { $0.id == selectedID }) else { return }
        if let fileIdx = apps[idx].files.firstIndex(where: { $0.id == fileID }) {
            apps[idx].files[fileIdx].isOn = isOn
        } else if let suiteIdx = apps[idx].suiteFiles.firstIndex(where: { $0.id == fileID }) {
            apps[idx].suiteFiles[suiteIdx].isOn = isOn
        }
    }

    func clearCache(for app: InstalledApp) async {
        let result = await FileCleaner.clearCache(app.files)
        if let idx = apps.firstIndex(where: { $0.id == app.id }) {
            apps[idx].files.removeAll { result.deletedIds.contains($0.id) }
        }
        showToast(icon: "🧹", title: "Cache cleared", subtitle: "\(Format.mb(result.freedMB)) freed · \(app.name) still installed")
    }

    func resetApp(_ app: InstalledApp) async {
        let result = await FileCleaner.resetApp(app.files)
        if let idx = apps.firstIndex(where: { $0.id == app.id }) {
            apps[idx].files = []
        }
        showToast(icon: "🔄", title: "App data wiped", subtitle: "\(Format.mb(result.freedMB)) freed · fresh install state")
    }

    func uninstall(_ app: InstalledApp) async {
        let result = await FileCleaner.uninstallApp(app)
        apps.removeAll { $0.id == app.id }
        if selectedID == app.id { selectedID = nil }
        showToast(icon: "✅", title: "\(app.name) removed", subtitle: "\(Format.mb(result.freedMB)) freed from your Mac")
    }

    private func showToast(icon: String, title: String, subtitle: String) {
        toastTask?.cancel()
        toast = Toast(icon: icon, title: title, subtitle: subtitle)
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }
}
