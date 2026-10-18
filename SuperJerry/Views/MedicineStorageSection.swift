import SwiftUI

/// "Medicine Storage" under Your Medications: how many of each medicine are left, and about how many days
/// that lasts. Jenny counts down by itself when a dose is logged as Taken.
/// It starts as a swipeable stack of cards (running low first); tap it to see them all,
/// then tap a row to set or refill the count and the "Running low" level.
struct MedicineStorageSection: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var cardHeight: CGFloat = 156
    @Namespace private var namespace
    @State private var isStacked = true
    @State private var current: UUID?
    let edit: (Medicine) -> Void

    var body: some View {
        let medicines = countable

        VStack(alignment: .leading, spacing: 12) {
            // The title and the Stack button side by side, or one above the other with very big text.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer(minLength: 8)
                    stackButton
                }
                VStack(alignment: .leading, spacing: 8) {
                    title
                    stackButton
                }
            }
            Text(language("Jenny จะลดจำนวนยาให้เองทุกครั้งที่คุณบันทึกว่าทานแล้ว",
                          "Jenny counts down by itself every time you log Taken."))
                .font(.callout)
                .foregroundStyle(.secondary)

            if isStacked && medicines.count > 1 {
                CardStack(items: medicines, cardHeight: cardHeight, current: $current, namespace: namespace,
                          title: language("คลังยา \(medicines.count) ตัว", "Medicine Storage, \(medicines.count) medicines"),
                          itemName: { $0.displayName(language) }) { medicine in
                    StorageRow(medicine: medicine)
                        .padding(.horizontal, Theme.cardPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .background(Theme.surface)
                } open: {
                    withAnimation(animation) { isStacked = false }
                }
                .transition(.opacity)
            } else {
                list(medicines)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: some View {
        Text(language("คลังยา", "Medicine Storage"))
            .font(.title.bold())
    }

    @ViewBuilder
    private var stackButton: some View {
        if !isStacked && countable.count > 1 {
            Button(language("ซ้อน", "Stack")) {
                withAnimation(animation) { isStacked = true }
            }
            .font(.title3)
            .tint(Theme.red)
        }
    }

    /// Every medicine in one card, each row tappable to set its count.
    private func list(_ medicines: [Medicine]) -> some View {
        VStack(spacing: 0) {
            ForEach(medicines) { medicine in
                if medicine.id != medicines.first?.id { Divider() }
                Button {
                    edit(medicine)
                } label: {
                    StorageRow(medicine: medicine)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .matchedGeometryEffect(id: medicine.id, in: namespace)
                .accessibilityHint(language("แตะเพื่อใส่หรือเติมจำนวนยา", "Tap to set or refill the count"))
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    /// A springy "drop down", like Apple's. A plain fade for people who turned on Reduce Motion.
    private var animation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.25)
    }

    /// Running low first, then the fewest days left, then the ones not counted yet.
    private var countable: [Medicine] {
        store.medicines
            .filter(\.canCountStock)
            .sorted { first, second in
                if first.isLowStock != second.isLowStock { return first.isLowStock }
                if (first.stock != nil) != (second.stock != nil) { return first.stock != nil }
                return (first.daysLeft ?? .max) < (second.daysLeft ?? .max)
            }
    }
}

/// One medicine's count: the icon, the name, how many are left, a bar, days left, and the warning level.
private struct StorageRow: View {
    @Environment(\.language) private var language
    let medicine: Medicine

    var body: some View {
        // Icons line up with the medicine's name at the top, like the Log cards.
        HStack(alignment: .top, spacing: 14) {
            PillIcon(medicine: medicine)
            VStack(alignment: .leading, spacing: 6) {
                Text(medicine.displayName(language))
                    .font(.title3)
                if medicine.stock != nil {
                    // The count and "Running low" side by side, or one above the other when there's no room.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            countText
                            if medicine.isLowStock { lowBadge }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            countText
                            if medicine.isLowStock { lowBadge }
                        }
                    }
                    ProgressView(value: medicine.stockFraction)
                        .tint(medicine.isLowStock ? Color.orange : Theme.green)
                        .accessibilityHidden(true)
                    Text([medicine.daysLeftText(language), medicine.lowLevelText(language)]
                            .compactMap { $0 }
                            .joined(separator: " · "))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Text(language("ยังไม่ได้นับ แตะเพื่อใส่จำนวนยาที่มี",
                                  "Not counted yet. Tap to add how many you have."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            RoundIcon(symbol: medicine.stock == nil ? "plus" : "pencil")
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
    }

    private var countText: some View {
        Text(medicine.stockText(language))
            .font(.headline)
    }

    private var lowBadge: some View {
        StatusBadge(title: language("ใกล้หมด", "Running low"), symbol: "exclamationmark.triangle.fill", color: .orange)
    }
}

#Preview {
    let store = MedicineStore.preview()
    store.setStock(30, for: store.medicines[0].id)
    store.setStock(4, for: store.medicines[1].id)
    store.setLowAt(10, for: store.medicines[0].id)
    return ScrollView {
        MedicineStorageSection { _ in }
            .padding()
    }
    .background(Theme.background)
    .environment(store)
    .environment(\.language, .english)
}
