import SwiftUI

/// A single leftover-file checklist row, used for both ~/Library leftovers and suite files.
struct FileRowView: View {
    let file: LeftoverFile
    var titleOverride: String? = nil
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(get: { file.isOn }, set: onToggle))
                .toggleStyle(.checkbox)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(titleOverride ?? file.category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.text)
                Text(file.displayPath)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.hint)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Text(Format.mb(file.sizeMB))
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }
}
