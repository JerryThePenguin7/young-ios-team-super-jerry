import SwiftUI

/// The round gray button look used across Jenny: a red symbol (+, pencil, speaker…) on a soft gray circle.
/// One size everywhere (`Theme.iconButton`), so every round button lines up.
/// Use it as a button's label, or on its own inside a card that is itself the button.
struct RoundIcon: View {
    let symbol: String
    var size: CGFloat = Theme.iconButton

    var body: some View {
        Image(systemName: symbol)
            .font(.title3.bold())
            .foregroundStyle(Theme.accent)
            .frame(width: size, height: size)
            .background(Theme.fill, in: Circle())
    }
}

#Preview {
    HStack(spacing: 12) {
        RoundIcon(symbol: "plus")
        RoundIcon(symbol: "pencil")
        RoundIcon(symbol: "speaker.wave.2.fill")
    }
    .padding()
    .background(Theme.surface)
}
