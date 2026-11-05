import SwiftUI

/// The big, easy-to-tap button look used across the app (at least 60 pt tall, for older hands).
struct BigButtonLabel: View {
    let title: String
    let symbol: String
    var filled = false

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 8)
            .foregroundStyle(filled ? Color.white : Theme.accent)
            .background(filled ? Theme.accentFill : Theme.fill,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 12) {
        BigButtonLabel(title: "Save medicine", symbol: "square.and.arrow.down.fill", filled: true)
        BigButtonLabel(title: "Read aloud", symbol: "speaker.wave.2.fill")
    }
    .padding()
}
