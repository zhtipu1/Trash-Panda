import AppKit

struct DeleteResult {
    let ok: Bool
    let freedMB: Double
    let error: String?
}

struct BatchDeleteResult {
    let ok: Bool
    let freedMB: Double
    let deletedIds: Set<String>
    let errors: [String]
}

struct UninstallResult {
    let ok: Bool
    let freedMB: Double
    let errors: [String]
}

/// Deletion operations, ported from backend/cleaner.py and the uninstall flow in backend/app_api.py.
///
/// Everything goes through the Trash (via NSWorkspace, the same mechanism as dragging something
/// to the Trash in Finder) rather than deleting outright — recoverable by default. When
/// AppSettings.emptyTrashAfterDelete is on, the exact item just trashed is immediately removed
/// from the Trash too (using the URL Trash handed back), so disk space is actually freed right
/// away without touching anything else already sitting in the user's Trash.
enum FileCleaner {
    /// Moves a URL to the Trash via the Finder's own mechanism, returning where it landed.
    private static func moveToTrash(_ url: URL) async -> (trashedURL: URL?, error: Error?) {
        await withCheckedContinuation { continuation in
            NSWorkspace.shared.recycle([url]) { newURLs, error in
                continuation.resume(returning: (newURLs[url], error))
            }
        }
    }

    /// Moves a single file/folder to the Trash, then permanently empties it from the Trash too
    /// if that setting is enabled.
    static func deletePath(_ displayPath: String) async -> DeleteResult {
        let url = FileSystemPaths.resolve(displayPath)
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            return DeleteResult(ok: true, freedMB: 0, error: nil)
        }

        let freed = DirectorySize.megabytes(at: url.path)
        let (trashedURL, error) = await moveToTrash(url)
        guard error == nil else {
            return DeleteResult(ok: false, freedMB: 0, error: error?.localizedDescription)
        }

        if AppSettings.shared.emptyTrashAfterDelete, let trashedURL {
            try? fm.removeItem(at: trashedURL)
        }

        return DeleteResult(ok: true, freedMB: freed, error: nil)
    }

    private static func deleteFiltered(_ files: [LeftoverFile], where predicate: (LeftoverFile) -> Bool) async -> BatchDeleteResult {
        var totalFreed = 0.0
        var errors: [String] = []
        var deletedIds: Set<String> = []

        for file in files where predicate(file) {
            let result = await deletePath(file.displayPath)
            if result.ok {
                totalFreed += result.freedMB
                deletedIds.insert(file.id)
            } else if let error = result.error {
                errors.append(error)
            }
        }

        return BatchDeleteResult(ok: errors.isEmpty, freedMB: (totalFreed * 10).rounded() / 10, deletedIds: deletedIds, errors: errors)
    }

    /// Deletes only "Caches" category files (clear_cache).
    static func clearCache(_ files: [LeftoverFile]) async -> BatchDeleteResult {
        await deleteFiltered(files) { $0.category == "Caches" }
    }

    /// Deletes every leftover file (reset_app — wipes app data, keeps the .app bundle).
    static func resetApp(_ files: [LeftoverFile]) async -> BatchDeleteResult {
        await deleteFiltered(files) { _ in true }
    }

    /// Full uninstall: delete checked ~/Library leftovers, checked suite files, move the .app bundle
    /// to Trash, then remove the suite folder if it's now empty. Ported from AppAPI.uninstall_app.
    static func uninstallApp(_ app: InstalledApp) async -> UninstallResult {
        var totalFreed = 0.0
        var errors: [String] = []

        let leftoverResult = await deleteFiltered(app.files) { $0.isOn }
        totalFreed += leftoverResult.freedMB
        errors.append(contentsOf: leftoverResult.errors)

        let checkedSuite = app.suiteFiles.filter { $0.isOn }
        for suiteFile in checkedSuite {
            let result = await deletePath(suiteFile.displayPath)
            if result.ok {
                totalFreed += result.freedMB
            } else if let error = result.error {
                errors.append(error)
            }
        }

        let appResult = await deletePath(app.appPath)
        if appResult.ok {
            totalFreed += app.appSizeMB
        } else {
            errors.append(appResult.error ?? "Could not move \(app.name).app to Trash")
        }

        if let suiteFolder = app.suiteFolder {
            let folderURL = URL(fileURLWithPath: suiteFolder)
            let fm = FileManager.default
            if let remaining = try? fm.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: []) {
                let visible = remaining.filter { !$0.lastPathComponent.hasPrefix(".") }
                if visible.isEmpty {
                    try? fm.removeItem(at: folderURL)
                }
            }
        }

        return UninstallResult(ok: errors.isEmpty, freedMB: (totalFreed * 10).rounded() / 10, errors: errors)
    }

    /// Deletes every "safe" orphan in one pass (delete_all_orphans).
    static func deleteAllOrphans(_ orphans: [OrphanFile]) async -> UninstallResult {
        var totalFreed = 0.0
        var errors: [String] = []
        for orphan in orphans where orphan.isSafe {
            let result = await deletePath(orphan.displayPath)
            if result.ok {
                totalFreed += result.freedMB
            } else if let error = result.error {
                errors.append(error)
            }
        }
        return UninstallResult(ok: errors.isEmpty, freedMB: (totalFreed * 10).rounded() / 10, errors: errors)
    }
}
