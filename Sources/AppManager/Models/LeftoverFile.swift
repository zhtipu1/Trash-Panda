import Foundation

/// A single leftover file/folder found for an installed (or suite) app —
/// mirrors the `{id, cat, path, size, on}` dicts produced by scanner.py.
struct LeftoverFile: Identifiable, Hashable {
    let id: String
    let category: String
    /// Display path with the home directory collapsed to "~", matching the Python version.
    let displayPath: String
    let sizeMB: Double
    var isOn: Bool

    /// Absolute filesystem path, expanding "~" back to the real home directory.
    var resolvedURL: URL {
        FileSystemPaths.resolve(displayPath)
    }

    var fileName: String {
        (displayPath as NSString).lastPathComponent
    }
}
