import SwiftUI

/// Jenny's big, easy-to-tap button: full width, at least 60 pt tall, icon plus title.
/// Use `.bigProminent` for the one main action on a screen and `.big` for everything else.
struct BigButtonStyle: ButtonStyle {
    var prominent = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.buttonCornerRadius)

        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 60)
            .foregroundStyle(prominent ? Color.white : Theme.red)
            .background(prominent ? AnyShapeStyle(Theme.card) : AnyShapeStyle(Theme.red.opacity(0.12)), in: shape)
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BigButtonStyle {
    /// A light red button.
    static var big: BigButtonStyle { BigButtonStyle() }
    /// The filled red button for the main action. Use one per screen.
    static var bigProminent: BigButtonStyle { BigButtonStyle(prominent: true) }
}

/// Keeps a custom-drawn button's own look (a card, a check circle) and just dims and shrinks it while pressed.
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

#Preview {
    VStack(spacing: 12) {
        Button("บันทึกยา · Save medicine", systemImage: "square.and.arrow.down.fill") {}
            .buttonStyle(.bigProminent)
        Button("อ่านออกเสียง · Read aloud", systemImage: "speaker.wave.2.fill") {}
            .buttonStyle(.big)
        Button("ปิดอยู่ · Disabled", systemImage: "xmark") {}
            .buttonStyle(.big)
            .disabled(true)
    }
    .padding()
    .background(Theme.background)
}
