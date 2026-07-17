import SwiftUI

/// A single row in the Apps list — icon, name (+ SUITE tag), size, and a locked/junk/clean badge.
/// Selection highlighting comes from the enclosing native `List`, not custom styling.
struct AppRowView: View {
    let app: InstalledApp

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(icon: app.icon, tagColor: app.tagColor, letter: String(app.name.prefix(1)), size: 34, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(app.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if app.hasSuiteFiles {
                        Text("SUITE")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Theme.accentBg))
                    }
                }
                Text(Format.mb(app.totalSizeMB))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)
            trailingBadge
        }
        .opacity(app.locked ? 0.6 : 1)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var trailingBadge: some View {
        if app.locked {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .help("App Manager is protected — it can't be managed from within itself.")
        } else if app.junkMB > 0 {
            Text(Format.mb(app.junkMB))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.danger)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Theme.dangerBg))
        } else {
            Text("Clean")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.success)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Theme.successBg))
        }
    }
}
