import SwiftUI

/// A stack of cards like the widget stacks on the iPhone and iPad Home Screen (Smart Stack):
/// one card in front and the next two peeking out behind it. Swipe up or down to flip through them,
/// with dots on the side showing where you are. Tap to spread the stack out.
/// Used for Your Medications and Medicine Storage.
struct CardStack<Item: Identifiable, Card: View>: View {
    @Environment(\.language) private var language

    let items: [Item]
    /// The height of one card. Pass a @ScaledMetric so it grows with the text size.
    let cardHeight: CGFloat
    /// The card in front. The parent keeps it, so the stack closes on the card it opened from.
    @Binding var current: Item.ID?
    /// Each card here gets a matching card in the spread-out list, so it can glide into place.
    let namespace: Namespace.ID
    /// "Your medicines" / "ยาของคุณ", for VoiceOver.
    let title: String
    /// The name of one card, for VoiceOver.
    let itemName: (Item) -> String
    let card: (Item) -> Card
    let open: () -> Void

    /// How much of each card behind shows above the one in front.
    private let peek: CGFloat = 12

    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .top) {
                behindCards
                pages
                    .padding(.top, CGFloat(peekCount) * peek)
            }
            if items.count > 1 {
                pageDots
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(language("ปัดขึ้นหรือลงเพื่อเปลี่ยน แตะสองครั้งเพื่อแสดงทั้งหมด",
                                    "Swipe up or down to change. Double-tap to show them all."))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open() }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(by: 1)
            case .decrement: move(by: -1)
            @unknown default: break
            }
        }
        .sensoryFeedback(.selection, trigger: currentIndex)
    }

    // MARK: Pieces

    /// The cards you swipe through, one page each.
    private var pages: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    card(item)
                        .frame(height: cardHeight)
                        .allowsHitTesting(false)
                        // A clear layer on top takes the tap, so the buttons inside the card don't.
                        .overlay {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(perform: open)
                        }
                        .matchedGeometryEffect(id: item.id, in: namespace)
                        .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $current)
        .scrollIndicators(.hidden)
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    /// The next cards, peeking out above the front one: smaller and a little darker the further back.
    private var behindCards: some View {
        ForEach(Array(peekItems.indices.reversed()), id: \.self) { depth in
            // depth 0 is the next card (just behind the front one), lower down and bigger than the one behind it.
            let level = CGFloat(peekCount - depth)
            card(peekItems[depth])
                .frame(height: cardHeight)
                .allowsHitTesting(false)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.06 * Double(depth + 1)))
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .scaleEffect(1 - 0.06 * CGFloat(depth + 1), anchor: .top)
                .offset(y: (level - 1) * peek)
                .accessibilityHidden(true)
        }
    }

    /// Dots on the side, like a Smart Stack: the filled one is the card in front.
    @ViewBuilder
    private var pageDots: some View {
        if items.count <= 8 {
            VStack(spacing: 6) {
                ForEach(items.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.primary : Color.secondary.opacity(0.35))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, CGFloat(peekCount) * peek)
            .animation(.snappy, value: currentIndex)
        } else {
            Text("\(currentIndex + 1)/\(items.count)")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
                .padding(.top, CGFloat(peekCount) * peek)
        }
    }

    // MARK: Which card is where

    private var currentIndex: Int {
        items.firstIndex { $0.id == current } ?? 0
    }

    /// How many cards peek out behind the front one (0, 1 or 2).
    private var peekCount: Int {
        min(items.count - 1, 2)
    }

    /// The cards right after the front one, going round to the start at the end.
    private var peekItems: [Item] {
        guard peekCount > 0 else { return [] }
        return (1...peekCount).map { items[(currentIndex + $0) % items.count] }
    }

    private var accessibilityValue: String {
        guard !items.isEmpty else { return "" }
        let name = itemName(items[currentIndex])
        return language("\(name) ลำดับที่ \(currentIndex + 1) จาก \(items.count)",
                        "\(name), \(currentIndex + 1) of \(items.count)")
    }

    private func move(by step: Int) {
        let index = min(max(currentIndex + step, 0), items.count - 1)
        withAnimation(.snappy) { current = items[index].id }
    }
}

#Preview {
    @Previewable @State var current: UUID?
    @Previewable @Namespace var namespace
    let store = MedicineStore.preview()
    NavigationStack {
        ScrollView {
            CardStack(items: store.medicines, cardHeight: 160, current: $current, namespace: namespace,
                      title: "Your medicines", itemName: \.name) { medicine in
                MedicineCard(medicine: medicine, height: 160)
            } open: {}
                .padding()
        }
        .background(Theme.background)
    }
    .environment(store)
    .environment(\.language, .english)
}
