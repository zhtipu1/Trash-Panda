import SwiftUI

struct StatPill: View {
    let label: String
    let value: String
    var danger: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .foregroundColor(Theme.muted)
            Text(value)
                .foregroundColor(danger ? Theme.danger : Theme.text)
                .fontWeight(.medium)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Theme.surface)
                .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
        )
    }
}
