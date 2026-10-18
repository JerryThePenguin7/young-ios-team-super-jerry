import SwiftUI

/// For buttons drawn as cards or rows (Log cards, Logged rows, storage rows, group headers):
/// keeps their own look and dims them slightly while pressed, like Apple's lists. Opacity only,
/// so nothing moves or changes size when tapped.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

#Preview {
    Button {} label: {
        Text("Tap and hold me")
            .font(.title3)
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
    .buttonStyle(.pressable)
    .padding()
    .background(Theme.background)
}
