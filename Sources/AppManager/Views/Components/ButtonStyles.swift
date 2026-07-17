import SwiftUI

/// A single reusable pill button style, covering every colored button in the original design
/// (clear cache / reset / uninstall / delete-orphan / clean-all / settings' small buttons / onboarding buttons).
struct TintedButtonStyle: ButtonStyle {
    var foreground: Color
    var background: Color
    var horizontalPadding: CGFloat = 14
    var verticalPadding: CGFloat = 7
    var fontSize: CGFloat = 12
    var cornerRadius: CGFloat = 8
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(Theme.border2, lineWidth: 0.5))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == TintedButtonStyle {
    static var cacheAction: TintedButtonStyle { TintedButtonStyle(foreground: Theme.accent, background: Theme.accentBg) }
    static var resetAction: TintedButtonStyle { TintedButtonStyle(foreground: Theme.warn, background: Theme.warnBg) }
    static var uninstallAction: TintedButtonStyle { TintedButtonStyle(foreground: Theme.danger, background: Theme.dangerBg) }
    static var dangerSmall: TintedButtonStyle { TintedButtonStyle(foreground: Theme.danger, background: Theme.dangerBg, horizontalPadding: 10, verticalPadding: 5, cornerRadius: 6) }
    static var secondary: TintedButtonStyle { TintedButtonStyle(foreground: Theme.text, background: Theme.surface2, horizontalPadding: 18, verticalPadding: 9) }
    static func primary(warnState: Bool) -> TintedButtonStyle {
        TintedButtonStyle(foreground: .white, background: warnState ? Theme.warn : Theme.accent, verticalPadding: 11, fontSize: 14, fullWidth: true)
    }
}
