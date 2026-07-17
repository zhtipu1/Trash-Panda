import SwiftUI

struct OrphanRowView: View {
    let orphan: OrphanFile
    let onDelete: () -> Void
    @State private var showConfirm = false
    @ObservedObject private var settings = AppSettings.shared

    private var trashMessage: String {
        settings.emptyTrashAfterDelete
            ? "This will be permanently deleted right away (\(Format.mb(orphan.sizeMB)))."
            : "This will be moved to the Trash (\(Format.mb(orphan.sizeMB)))."
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(orphan.category)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(orphan.isSafe ? Theme.danger : Theme.warn)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(orphan.isSafe ? Theme.dangerBg : Theme.warnBg))
                .fixedSize()

            VStack(alignment: .leading, spacing: 2) {
                Text(orphan.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(orphan.displayPath)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.hint)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !orphan.isSafe, let linked = orphan.linkedApp {
                    Text("⚠ Used by \(linked)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.warn)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Theme.warnBg))
                }
            }

            Spacer(minLength: 8)

            Text(Format.mb(orphan.sizeMB))
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
                .frame(minWidth: 52, alignment: .trailing)

            Button(orphan.isSafe ? "Delete" : "Protected") { showConfirm = true }
                .buttonStyle(.dangerSmall)
                .disabled(!orphan.isSafe)
                .help(orphan.isSafe ? "" : "This file belongs to an installed app")
                .confirmationDialog(
                    "Delete “\(orphan.name)”?",
                    isPresented: $showConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) { onDelete() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(trashMessage)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(orphan.isSafe ? Theme.surface : Theme.warnBg.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(orphan.isSafe ? Theme.border2 : Theme.warn.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}
