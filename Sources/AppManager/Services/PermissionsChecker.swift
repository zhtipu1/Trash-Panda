import AppKit

/// Full Disk Access detection, ported from AppAPI.check_full_disk_access.
///
/// There's no public API to ask TCC directly, so — like the Python version — this probes a
/// protected location: a successful read means FDA is granted, a denial means it isn't.
enum PermissionsChecker {
    static func hasFullDiskAccess() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let tccURL = home.appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        if (try? Data(contentsOf: tccURL)) != nil {
            return true
        }

        let fm = FileManager.default
        for rel in ["Library/Safari", "Library/Mail", "Library/Messages"] {
            let path = home.appendingPathComponent(rel)
            guard fm.fileExists(atPath: path.path) else { continue }
            if (try? fm.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])) != nil {
                return true
            } else {
                return false
            }
        }
        return false
    }

    static func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }
}
