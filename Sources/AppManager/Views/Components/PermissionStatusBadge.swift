import SwiftUI

enum PermissionStatus: Equatable {
    case checking, granted, denied

    var color: Color {
        switch self {
        case .checking: return Theme.muted
        case .granted: return Theme.success
        case .denied: return Theme.danger
        }
    }

    var background: Color {
        switch self {
        case .checking: return Theme.surface2
        case .granted: return Theme.successBg
        case .denied: return Theme.dangerBg
        }
    }

    var label: String {
        switch self {
        case .checking: return "Checking…"
        case .granted: return "Granted"
        case .denied: return "Not granted"
        }
    }
}

struct PermissionStatusBadge: View {
    let status: PermissionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(status.color).frame(width: 7, height: 7)
            Text(status.label)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(status.background))
    }
}
