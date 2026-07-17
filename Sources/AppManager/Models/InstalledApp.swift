import AppKit

enum AppType: String {
    case installed
    case system
}

/// A discovered `.app` bundle plus everything scanner.py used to compute about it.
struct InstalledApp: Identifiable, Hashable {
    let id: String
    let name: String
    let version: String
    let appSizeMB: Double
    let suiteSizeMB: Double
    /// Absolute path (not "~"-collapsed) to the vendor folder this app lives in, e.g. "/Applications/Adobe".
    let suiteFolder: String?
    var suiteFiles: [LeftoverFile]
    let bundleId: String
    /// Absolute path to the .app bundle.
    let appPath: String
    let appType: AppType
    let tagColor: TagColor
    let icon: NSImage?
    /// True for App Manager itself — cannot be cleaned/reset/uninstalled from within itself.
    let locked: Bool
    var files: [LeftoverFile]

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Total size of everything this app leaves behind in ~/Library (leftover + suite files).
    var junkMB: Double {
        files.reduce(0) { $0 + $1.sizeMB } + suiteFiles.reduce(0) { $0 + $1.sizeMB }
    }

    var totalSizeMB: Double {
        appSizeMB + suiteSizeMB
    }

    var hasSuiteFiles: Bool { !suiteFiles.isEmpty }
}
