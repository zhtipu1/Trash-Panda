import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

enum Theme {
    static let bg = Color(hex: 0x111113)
    static let surface = Color(hex: 0x1a1a1d)
    static let surface2 = Color(hex: 0x222226)
    static let border = Color.white.opacity(0.07)
    static let border2 = Color.white.opacity(0.13)
    static let text = Color(hex: 0xe8e6e1)
    static let muted = Color(hex: 0x888780)
    static let hint = Color(hex: 0x4a4845)

    static let accent = Color(hex: 0x378ADD)
    static let accentBg = Color(hex: 0x0c2a45)

    static let warn = Color(hex: 0xBA7517)
    static let warnBg = Color(hex: 0x2a1d06)

    static let danger = Color(hex: 0xE24B4A)
    static let dangerBg = Color(hex: 0x2e1010)

    static let success = Color(hex: 0x639922)
    static let successBg = Color(hex: 0x192308)
}

/// Tag colors cycled across the app list, mirroring the original color_cycle behavior.
enum TagColor: String {
    case info, success, warning, danger

    var bg: Color {
        switch self {
        case .info: return Theme.accentBg
        case .success: return Theme.successBg
        case .warning: return Theme.warnBg
        case .danger: return Theme.dangerBg
        }
    }

    var fg: Color {
        switch self {
        case .info: return Theme.accent
        case .success: return Theme.success
        case .warning: return Theme.warn
        case .danger: return Theme.danger
        }
    }

    static let cycle: [TagColor] = [.info, .success, .warning, .danger]
}
