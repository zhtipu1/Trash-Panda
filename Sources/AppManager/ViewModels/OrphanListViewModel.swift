import Foundation

@MainActor
final class OrphanListViewModel: ObservableObject {
    @Published var orphans: [OrphanFile] = []
    @Published var isLoading = false
    @Published var hasLoaded = false
    @Published var toast: Toast?

    private var toastTask: Task<Void, Never>?

    /// Mirrors AppAPI.get_orphans.
    func load(installedApps: [InstalledApp], scanGroupContainers: Bool) async {
        isLoading = true
        let found = await Task.detached(priority: .userInitiated) {
            OrphanScanner.findOrphans(installedApps: installedApps, scanGroupContainers: scanGroupContainers)
        }.value
        orphans = found
        hasLoaded = true
        isLoading = false
    }

    /// Called after the Apps tab re-scans, so the next visit to Orphaned re-scans too (orphansLoaded=false).
    func invalidate() {
        hasLoaded = false
    }

    var safeOrphans: [OrphanFile] { orphans.filter { $0.isSafe } }
    var unsafeOrphans: [OrphanFile] { orphans.filter { !$0.isSafe } }
    var totalSafeMB: Double { safeOrphans.reduce(0) { $0 + $1.sizeMB } }
    var sortedForDisplay: [OrphanFile] { safeOrphans + unsafeOrphans }

    func delete(_ orphan: OrphanFile) async {
        let result = await FileCleaner.deletePath(orphan.displayPath)
        if result.ok {
            orphans.removeAll { $0.id == orphan.id }
        }
    }

    func cleanAllSafe() async {
        let result = await FileCleaner.deleteAllOrphans(orphans)
        orphans.removeAll { $0.isSafe }
        showToast(icon: "🧹", title: "Orphaned files cleaned", subtitle: "\(Format.mb(result.freedMB)) freed from your Mac")
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
