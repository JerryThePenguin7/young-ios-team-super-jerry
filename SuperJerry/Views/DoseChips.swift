import SwiftUI

/// A medicine's times. With `now`, they're big chips you tap to tick that dose as taken today;
/// without it, they're a plain list of times.
struct DoseChips: View {
    @Environment(MedicineStore.self) private var store
    let medicine: Medicine
    /// nil for a medicine that isn't saved yet: the chips only show the times.
    var now: Date?

    var body: some View {
        if medicine.asNeeded {
            chip(title: "เมื่อมีอาการ · When needed", symbol: "hand.raised.fill", style: .plain)
        } else if medicine.orderedSlots.isEmpty {
            Label("ไม่มีเวลาทานยา · No time set. Tap Edit to add one.", systemImage: "clock.badge.questionmark")
                .font(.headline)
                .labelStyle(TintedIconLabelStyle(tint: Theme.late))
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10, alignment: .leading)],
                      alignment: .leading, spacing: 10) {
                ForEach(medicine.orderedSlots, id: \.self) { slot in
                    if let now {
                        let status = store.status(of: medicine, at: slot.time, now: now)
                        Button {
                            store.toggleTaken(medicine, at: slot.time, now: now)
                        } label: {
                            chip(for: slot, status: status)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityHint(status.isTaken ? "Tap to un-tick" : "Tap when you've taken it")
                    } else {
                        chip(title: "\(slot.thai) · \(slot.time.label)", symbol: slot.symbol, style: .plain)
                    }
                }
            }
        }
    }

    private enum ChipStyle { case plain, taken, due, missed }

    private func chip(for slot: TimeSlot, status: DoseStatus) -> some View {
        switch status {
        case .taken: chip(title: "\(slot.thai) · ทานแล้ว", symbol: "checkmark.circle.fill", style: .taken)
        case .dueNow: chip(title: "\(slot.thai) · ถึงเวลา", symbol: "bell.fill", style: .due)
        case .missed: chip(title: "\(slot.thai) · ยังไม่ทาน", symbol: "exclamationmark.circle.fill", style: .missed)
        case .upcoming: chip(title: "\(slot.thai) · \(slot.time.label)", symbol: slot.symbol, style: .plain)
        }
    }

    /// Only saved medicines can be ticked. Otherwise the times are shown as plain text, so they don't look tappable.
    private var isInteractive: Bool { now != nil && !medicine.asNeeded }

    /// Text stays dark for easy reading. The icon, fill, and border carry the color.
    private func chip(title: String, symbol: String, style: ChipStyle) -> some View {
        Label(title, systemImage: symbol)
            .labelStyle(TintedIconLabelStyle(tint: tint(style)))
            .font(.headline)
            .foregroundStyle(style == .due ? Theme.red : Color.primary)
            .lineLimit(2)
            .padding(.horizontal, isInteractive ? 14 : 0)
            .padding(.vertical, isInteractive ? 8 : 0)
            .frame(maxWidth: .infinity, minHeight: isInteractive ? 52 : nil, alignment: .leading)
            .background(isInteractive ? background(style) : .clear, in: Capsule())
            .overlay {
                Capsule().strokeBorder(border(style), lineWidth: 2)
            }
            .contentShape(Capsule())
    }

    private func tint(_ style: ChipStyle) -> Color {
        switch style {
        case .taken: Theme.taken
        case .due, .plain: Theme.red
        case .missed: Theme.late
        }
    }

    private func background(_ style: ChipStyle) -> Color {
        switch style {
        case .taken: Theme.taken.opacity(0.15)
        case .due: Theme.red.opacity(0.12)
        case .missed: Theme.late.opacity(0.12)
        case .plain: Theme.background
        }
    }

    private func border(_ style: ChipStyle) -> Color {
        switch style {
        case .due: Theme.red
        case .missed: Theme.late
        case .taken, .plain: .clear
        }
    }
}

#Preview {
    let store = MedicineStore.preview()
    VStack(alignment: .leading, spacing: 20) {
        DoseChips(medicine: store.medicines[1], now: Date())
        DoseChips(medicine: store.medicines[1])
    }
    .padding()
    .background(Theme.surface)
    .environment(store)
}
