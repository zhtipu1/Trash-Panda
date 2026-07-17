import Foundation

/// A file left behind by an app that is no longer installed —
/// mirrors the `{id, name, cat, path, size, safe, linked_app}` dicts from find_orphaned_files.
struct OrphanFile: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let displayPath: String
    let sizeMB: Double
    /// True when no currently-installed app matches this file — safe to delete.
    let isSafe: Bool
    /// Name of the installed app this file appears to belong to, when isSafe is false.
    let linkedApp: String?

    var resolvedURL: URL {
        FileSystemPaths.resolve(displayPath)
    }
}
