import SwiftUI

/// The "About" tab. Ported from #view-about in the original frontend.
struct AboutView: View {
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.accentBg)
                        Text("🐼").font(.system(size: 30))
                    }
                    .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trash Panda: App Manager").font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)
                        Text("Version 1.0.0  ·  macOS").font(.system(size: 13)).foregroundColor(Theme.muted)
                    }
                }

                Rectangle().fill(Theme.border2).frame(height: 0.5)

                Text("This loves digging through your system and eating the unwanted apps and garbage. Trash Panda gives you a complete picture of every app installed on your Mac — not just the .app bundle, but all the caches, preferences, logs, and support files apps quietly leave behind. Clear cache without losing your data, reset apps to a fresh install state, or remove everything in one click.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.muted)
                    .lineSpacing(6)

                VStack(spacing: 10) {
                    aboutMetaRow("Built with", "Swift & SwiftUI")
                    aboutMetaRow("Platform", "macOS 13 Ventura and later")
                    aboutMetaRow("License", "MIT — free to use and modify")
                }

                Rectangle().fill(Theme.border2).frame(height: 0.5)

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.accentBg)
                        Text("ZT").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.accent)
                    }
                    .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Zahidul Haque Tipu").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text)
                        Text("Designer & Developer").font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border2, lineWidth: 0.5))
                )
            }
            .frame(maxWidth: 480)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .navigationTitle("About")
    }

    private func aboutMetaRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(Theme.muted)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(Theme.text)
        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.border).frame(height: 0.5) }
    }
}
