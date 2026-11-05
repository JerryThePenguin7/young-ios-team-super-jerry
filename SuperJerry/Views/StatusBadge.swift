import SwiftUI

/// A small status capsule: dark words on a light tint, with a colored icon ("Late", "Time to take", "Running low").
/// White text on orange is too hard to read, so only the icon carries the color.
/// The words never get cut off with "…": the badge keeps its full width, so give it room (or a second line).
struct StatusBadge: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
        }
        .font(.callout.bold())
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.18), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(title: "Late", symbol: "exclamationmark.circle.fill", color: .orange)
        StatusBadge(title: "Time to take", symbol: "bell.fill", color: Theme.accent)
        StatusBadge(title: "ใกล้หมด", symbol: "exclamationmark.triangle.fill", color: .orange)
    }
    .padding()
}
