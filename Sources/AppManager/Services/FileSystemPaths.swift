import Foundation

/// Home-directory collapsing/expansion, matching the Python version's `str(path).replace(str(HOME), "~")`.
enum FileSystemPaths {
    static let home = FileManager.default.homeDirectoryForCurrentUser.path

    static func collapse(_ path: String) -> String {
        guard path.hasPrefix(home) else { return path }
        return "~" + path.dropFirst(home.count)
    }

    static func resolve(_ displayPath: String) -> URL {
        if displayPath.hasPrefix("~") {
            return URL(fileURLWithPath: home + displayPath.dropFirst())
        }
        return URL(fileURLWithPath: displayPath)
    }
}
