import AppKit

/// Options controlling which ~/Library subfolders get scanned — mirrors AppSettings.
struct ScanOptions {
    var scanContainers: Bool = true
    var scanGroupContainers: Bool = false
}

/// Discovers installed .app bundles and the leftover files they've scattered across ~/Library.
/// Ported from backend/scanner.py.
enum AppScanner {
    /// Directories searched for .app bundles, in order, alongside the type they're tagged with.
    private static var appSources: [(url: URL, type: AppType)] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            (URL(fileURLWithPath: "/Applications"), .installed),
            (URL(fileURLWithPath: "/System/Applications"), .system),
            (URL(fileURLWithPath: "/System/Applications/Utilities"), .system),
            (home.appendingPathComponent("Applications"), .installed),
        ]
    }

    /// ~/Library subfolders scanned for leftover files, category label -> URL, in display order.
    static func baseSearchDirs(options: ScanOptions) -> [(category: String, url: URL)] {
        let lib = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        var dirs: [(String, URL)] = [
            ("Caches", lib.appendingPathComponent("Caches")),
            ("App Support", lib.appendingPathComponent("Application Support")),
            ("Preferences", lib.appendingPathComponent("Preferences")),
            ("Logs", lib.appendingPathComponent("Logs")),
            ("WebKit", lib.appendingPathComponent("WebKit")),
        ]
        if options.scanContainers {
            dirs.append(("Containers", lib.appendingPathComponent("Containers")))
        }
        if options.scanGroupContainers {
            dirs.append(("Group Containers", lib.appendingPathComponent("Group Containers")))
        }
        return dirs
    }

    private struct RawEntry {
        let path: URL
        let suiteFolder: String?
        let suiteFiles: [LeftoverFile]
        let appType: AppType
    }

    /// Recursively discovers .app bundles up to 2 folders deep, matching _collect_entries in scanner.py.
    private static func collectEntries(directory: URL, appType: AppType, seen: inout Set<String>, depth: Int = 0) -> [RawEntry] {
        guard depth <= 2 else { return [] }
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else { return [] }

        guard let children = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: []) else {
            return []
        }
        let visible = children.filter { !$0.lastPathComponent.hasPrefix(".") }
        let appChildren = visible.filter { $0.pathExtension.lowercased() == "app" }
        let folderChildren = visible.filter { url in
            url.pathExtension.lowercased() != "app" && ((try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false)
        }

        var results: [RawEntry] = []

        for entry in appChildren {
            let key = entry.path
            if seen.contains(key) { continue }
            seen.insert(key)

            var suite: [LeftoverFile] = []
            var suiteFolder: String? = nil
            if depth >= 1 {
                suiteFolder = directory.path
                // Suite files = non-.app sibling folders in the same vendor directory (e.g. "Adobe/").
                suite = folderChildren.map { child in
                    LeftoverFile(
                        id: "suite::\(child.lastPathComponent)",
                        category: "Suite files",
                        displayPath: FileSystemPaths.collapse(child.path),
                        sizeMB: DirectorySize.megabytes(at: child.path),
                        isOn: false
                    )
                }
            }

            results.append(RawEntry(path: entry, suiteFolder: suiteFolder, suiteFiles: suite, appType: appType))
        }

        for folder in folderChildren {
            results.append(contentsOf: collectEntries(directory: folder, appType: appType, seen: &seen, depth: depth + 1))
        }

        return results
    }

    private static func infoPlist(for appURL: URL) -> [String: Any] {
        Bundle(url: appURL)?.infoDictionary ?? [:]
    }

    /// Leftover files whose name matches the app by bundle-id prefix or (name, stripped of spaces) substring.
    /// Ported from find_leftover_files in scanner.py.
    private static func findLeftoverFiles(appName: String, bundleId: String?, searchDirs: [(category: String, url: URL)]) -> [LeftoverFile] {
        let nameLower = appName.lowercased().replacingOccurrences(of: " ", with: "")
        let fm = FileManager.default
        var leftovers: [LeftoverFile] = []

        for (category, searchURL) in searchDirs {
            guard let entries = try? fm.contentsOfDirectory(at: searchURL, includingPropertiesForKeys: nil, options: []) else { continue }
            for entry in entries {
                let en = entry.lastPathComponent.lowercased()
                let bundleMatch = bundleId.map { en.hasPrefix($0.lowercased()) } ?? false
                let nameMatch = nameLower.count > 3 && en.contains(nameLower)
                guard bundleMatch || nameMatch else { continue }

                leftovers.append(LeftoverFile(
                    id: "\(category)::\(entry.lastPathComponent)",
                    category: category,
                    displayPath: FileSystemPaths.collapse(entry.path),
                    sizeMB: DirectorySize.megabytes(at: entry.path),
                    isOn: true
                ))
            }
        }
        return leftovers
    }

    private static let ownName = "trash panda - app manager"

    /// Full scan: discover apps, then find each one's leftover files. Mirrors scan_apps in scanner.py.
    static func scanApps(options: ScanOptions) -> [InstalledApp] {
        let searchDirs = baseSearchDirs(options: options)

        var seen = Set<String>()
        var raw: [RawEntry] = []
        for source in appSources {
            raw.append(contentsOf: collectEntries(directory: source.url, appType: source.type, seen: &seen))
        }
        raw.sort { $0.path.deletingPathExtension().lastPathComponent.lowercased() < $1.path.deletingPathExtension().lastPathComponent.lowercased() }

        let ownBundleId = Bundle.main.bundleIdentifier

        var apps: [InstalledApp] = []
        for (i, rec) in raw.enumerated() {
            let entry = rec.path
            let plist = infoPlist(for: entry)
            let name = entry.deletingPathExtension().lastPathComponent
            let bundleId = plist["CFBundleIdentifier"] as? String
            let isSelf = (bundleId != nil && bundleId == ownBundleId) || name.lowercased() == ownName

            let suiteSize = rec.suiteFiles.reduce(0) { $0 + $1.sizeMB }
            let version = (plist["CFBundleShortVersionString"] as? String) ?? "—"

            apps.append(InstalledApp(
                id: entry.path,
                name: name,
                version: version,
                appSizeMB: DirectorySize.megabytes(at: entry.path),
                suiteSizeMB: suiteSize,
                suiteFolder: rec.suiteFolder,
                suiteFiles: rec.suiteFiles,
                bundleId: bundleId ?? "",
                appPath: entry.path,
                appType: rec.appType,
                tagColor: TagColor.cycle[i % TagColor.cycle.count],
                icon: NSWorkspace.shared.icon(forFile: entry.path),
                locked: isSelf,
                files: isSelf ? [] : findLeftoverFiles(appName: name, bundleId: bundleId, searchDirs: searchDirs)
            ))
        }

        return apps
    }
}
