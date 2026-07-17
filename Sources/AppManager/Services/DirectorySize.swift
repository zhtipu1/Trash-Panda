import Foundation

/// Directory/file size measurement, ported from scanner.py's get_dir_size_mb / cleaner.py's du probe.
///
/// Shells out to `/usr/bin/du -sk`, the same technique real native disk-usage utilities use —
/// a recursive `FileManager` walk would be far slower on large cache folders.
enum DirectorySize {
    static func megabytes(at path: String) -> Double {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0.0 }

        if !isDir.boolValue {
            if let attrs = try? fm.attributesOfItem(atPath: path),
               let size = attrs[.size] as? NSNumber {
                return (size.doubleValue / (1024 * 1024) * 10).rounded() / 10
            }
            return 0.0
        }

        guard let kb = duKilobytes(path: path) else { return 0.0 }
        return (Double(kb) / 1024 * 10).rounded() / 10
    }

    /// Runs `du -sk <path>` with a 10s watchdog, returning the size in kilobytes.
    private static func duKilobytes(path: String) -> Int? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        process.arguments = ["-sk", path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return nil
        }

        let watchdog = DispatchWorkItem {
            if process.isRunning { process.terminate() }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 10, execute: watchdog)

        process.waitUntilExit()
        watchdog.cancel()

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8),
              let firstField = output.split(whereSeparator: { $0 == " " || $0 == "\t" }).first,
              let kb = Int(firstField) else { return nil }
        return kb
    }
}
