import Foundation

/// Detects leftover files whose owning app is no longer installed. Ported from find_orphaned_files
/// and _is_orphan_candidate in scanner.py.
enum OrphanScanner {
    private static let knownExtensions = ["plist", "savedstate", "sb", "db"]

    private static func stripKnownExtension(_ s: String) -> String {
        for ext in knownExtensions {
            let suffix = "." + ext
            if s.hasSuffix(suffix) {
                return String(s.dropLast(suffix.count))
            }
        }
        return s
    }

    /// Matches the regex `^[a-z]{2,}\.[a-z]` — a bundle-id-shaped prefix (e.g. "com.something").
    private static func matchesCandidatePattern(_ s: String) -> Bool {
        let chars = Array(s)
        var i = 0
        var letterCount = 0
        while i < chars.count, chars[i].isASCII, chars[i].isLowercase, chars[i].isLetter {
            letterCount += 1
            i += 1
        }
        guard letterCount >= 2, i < chars.count, chars[i] == "." else { return false }
        let j = i + 1
        guard j < chars.count, chars[j].isASCII, chars[j].isLowercase, chars[j].isLetter else { return false }
        return true
    }

    private static func isOrphanCandidate(_ name: String) -> Bool {
        let n = name.lowercased()
        if n.hasPrefix("com.apple.") { return false }
        return matchesCandidatePattern(stripKnownExtension(n))
    }

    /// Search dirs for orphan scanning always include Containers (unlike the main app scan, which
    /// respects the scan_containers toggle) — this mirrors a quirk in the original Python implementation.
    private static func searchDirs(scanGroupContainers: Bool) -> [(category: String, url: URL)] {
        let lib = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        var dirs: [(String, URL)] = [
            ("Caches", lib.appendingPathComponent("Caches")),
            ("App Support", lib.appendingPathComponent("Application Support")),
            ("Preferences", lib.appendingPathComponent("Preferences")),
            ("Logs", lib.appendingPathComponent("Logs")),
            ("WebKit", lib.appendingPathComponent("WebKit")),
            ("Containers", lib.appendingPathComponent("Containers")),
        ]
        if scanGroupContainers {
            dirs.append(("Group Containers", lib.appendingPathComponent("Group Containers")))
        }
        return dirs
    }

    static func findOrphans(installedApps: [InstalledApp], scanGroupContainers: Bool) -> [OrphanFile] {
        let fm = FileManager.default
        var orphans: [OrphanFile] = []

        for (category, searchURL) in searchDirs(scanGroupContainers: scanGroupContainers) {
            guard let entries = try? fm.contentsOfDirectory(at: searchURL, includingPropertiesForKeys: nil, options: []) else { continue }

            for entry in entries {
                let name = entry.lastPathComponent
                guard isOrphanCandidate(name) else { continue }
                let n = name.lowercased()
                let base = stripKnownExtension(n)

                let match = installedApps.first { app -> Bool in
                    let bundleLower = app.bundleId.lowercased()
                    if !app.bundleId.isEmpty, base.hasPrefix(bundleLower) || bundleLower.hasPrefix(base) {
                        return true
                    }
                    let nameKey = app.name.lowercased().replacingOccurrences(of: " ", with: "")
                    if app.name.count > 3, !nameKey.isEmpty, base.contains(nameKey) {
                        return true
                    }
                    return false
                }

                orphans.append(OrphanFile(
                    id: "orphan::\(category)::\(name)",
                    name: name,
                    category: category,
                    displayPath: FileSystemPaths.collapse(entry.path),
                    sizeMB: DirectorySize.megabytes(at: entry.path),
                    isSafe: match == nil,
                    linkedApp: match?.name
                ))
            }
        }

        return orphans.sorted { $0.sizeMB > $1.sizeMB }
    }
}
