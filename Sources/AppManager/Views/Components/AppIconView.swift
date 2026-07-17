import AppKit
import SwiftUI

/// Shows an app's real icon (via NSWorkspace) or falls back to a colored initial badge.
struct AppIconView: View {
    let icon: NSImage?
    let tagColor: TagColor
    let letter: String
    var size: CGFloat = 34
    var cornerRadius: CGFloat = 8

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    tagColor.bg
                    Text(letter.uppercased())
                        .font(.system(size: size * 0.41, weight: .semibold))
                        .foregroundColor(tagColor.fg)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
