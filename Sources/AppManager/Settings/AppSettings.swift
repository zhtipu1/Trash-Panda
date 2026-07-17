import Foundation

/// Persisted scanner/startup preferences, replacing the manual plist read/write in app_api.py.
/// Backed by UserDefaults.standard, which — since it's keyed by the app's bundle identifier —
/// writes to the same `~/Library/Preferences/com.appmanager.app.plist` the Python version used.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let scanContainers = "scan_containers"
        static let scanGroupContainers = "scan_group_containers"
        static let showOnboarding = "show_onboarding"
        static let emptyTrashAfterDelete = "empty_trash_after_delete"
    }

    private let defaults = UserDefaults.standard

    @Published var scanContainers: Bool {
        didSet { defaults.set(scanContainers, forKey: Keys.scanContainers) }
    }
    @Published var scanGroupContainers: Bool {
        didSet { defaults.set(scanGroupContainers, forKey: Keys.scanGroupContainers) }
    }
    @Published var showOnboarding: Bool {
        didSet { defaults.set(showOnboarding, forKey: Keys.showOnboarding) }
    }
    /// When on, anything the app deletes is moved to the Trash and then immediately
    /// removed from the Trash too (permanently freeing the space right away) instead
    /// of sitting there until the user empties it themselves.
    @Published var emptyTrashAfterDelete: Bool {
        didSet { defaults.set(emptyTrashAfterDelete, forKey: Keys.emptyTrashAfterDelete) }
    }

    private init() {
        defaults.register(defaults: [
            Keys.scanContainers: true,
            Keys.scanGroupContainers: false,
            Keys.showOnboarding: true,
            Keys.emptyTrashAfterDelete: false,
        ])
        scanContainers = defaults.bool(forKey: Keys.scanContainers)
        scanGroupContainers = defaults.bool(forKey: Keys.scanGroupContainers)
        showOnboarding = defaults.bool(forKey: Keys.showOnboarding)
        emptyTrashAfterDelete = defaults.bool(forKey: Keys.emptyTrashAfterDelete)
    }

    var scanOptions: ScanOptions {
        ScanOptions(scanContainers: scanContainers, scanGroupContainers: scanGroupContainers)
    }
}
