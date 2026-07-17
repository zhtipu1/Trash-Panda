import SwiftUI

/// Transient banner shown after an action completes (clear cache / reset / uninstall / clean orphans).
/// Mirrors the #flash overlay in the original UI.
struct ToastOverlay: View {
    let toast: Toast?

    var body: some View {
        ZStack {
            if let toast {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 10) {
                    Text(toast.icon).font(.system(size: 36))
                    Text(toast.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(toast.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 28)
                .frame(minWidth: 260)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border2, lineWidth: 0.5))
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast)
        .allowsHitTesting(false)
    }
}
