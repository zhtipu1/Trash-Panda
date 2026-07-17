import Foundation

/// Size formatting, ported 1:1 from the frontend's `fmt()` helper.
enum Format {
    static func mb(_ value: Double) -> String {
        guard value > 0 else { return "0 MB" }
        if value >= 1024 {
            return String(format: "%.1f GB", value / 1024)
        }
        return "\(Int(value.rounded())) MB"
    }
}

/// A transient banner shown after an action completes — the flash() equivalent.
struct Toast: Equatable {
    let icon: String
    let title: String
    let subtitle: String
}
