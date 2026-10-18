import SwiftUI

/// "Your Medications" folded into a stack of cards, like a deck: the newest medicine in front,
/// two more peeking out behind it. Tap the stack to spread all the medicines out.
struct MedicineStack: View {
    @Environment(\.language) private var language
    let medicines: [Medicine]
    let open: () -> Void

    /// How far each card behind peeks out above the one in front.
    private let peek: CGFloat = 16

    var body: some View {
        let shown = Array(medicines.prefix(3))

        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .top) {
                // Back to front, so the newest medicine is drawn last, on top.
                ForEach((0..<shown.count).reversed(), id: \.self) { index in
                    MedicineCard(medicine: shown[index])
                        .allowsHitTesting(false)
                        // Darker and smaller the further back it is.
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.black.opacity(Double(index) * 0.06))
                        }
                        .scaleEffect(1 - CGFloat(index) * 0.06, anchor: .top)
                        .offset(y: CGFloat(shown.count - 1 - index) * peek)
                        .zIndex(Double(-index))
                }
            }
            .padding(.bottom, CGFloat(max(shown.count - 1, 0)) * peek)

            Label(medicines.count > 1
                  ? language("แตะเพื่อดูยาทั้ง \(medicines.count) ตัว", "Tap to see all \(medicines.count) medicines")
                  : language("แตะเพื่อดูยา", "Tap to see your medicine"),
                  systemImage: "square.stack.3d.down.right")
                .font(.headline)
                .foregroundStyle(Theme.red)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        // The cards inside have their own buttons, so the stack uses a tap instead of being a Button.
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language("ยาของคุณ \(medicines.count) ตัว ซ้อนกันอยู่", "Your \(medicines.count) medicines, stacked"))
        .accessibilityHint(language("แตะเพื่อแสดงยาทั้งหมด", "Tap to show them all"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open() }
    }
}

#Preview {
    let store = MedicineStore.preview()
    NavigationStack {
        ScrollView {
            MedicineStack(medicines: store.medicines) {}
                .padding()
        }
        .background(Theme.background)
    }
    .environment(store)
    .environment(\.language, .english)
}
