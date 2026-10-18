import SwiftUI

/// A medicine's times as big chips. On a saved medicine, tap a chip to tick that dose as taken today.
struct DoseChips: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    let medicine: Medicine
    /// nil for a medicine that isn't saved yet: the chips only show the times.
    var now: Date?

    var body: some View {
        if medicine.asNeeded {
            chip(title: language("เมื่อมีอาการ", "When needed"), symbol: "hand.raised.fill", style: .plain)
        } else if medicine.orderedSlots.isEmpty {
            Label(language("ยังไม่ได้ตั้งเวลา แตะ แก้ไข เพื่อเพิ่มเวลา", "No time set. Tap Edit to add one."),
                  systemImage: "clock.badge.questionmark")
                .font(.headline)
                .foregroundStyle(.orange)
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
                        .buttonStyle(.plain)
                        .accessibilityHint(status.isLogged ? language("แตะเพื่อยกเลิก", "Tap to undo")
                                                           : language("แตะเมื่อทานแล้ว", "Tap when you've taken it"))
                    } else {
                        chip(title: "\(slot.name(language)) · \(slot.time.label(language))", symbol: slot.symbol, style: .plain)
                    }
                }
            }
        }
    }

    private enum ChipStyle { case plain, taken, due, missed }

    private func chip(for slot: TimeSlot, status: DoseStatus) -> some View {
        let name = slot.name(language)
        return switch status {
        case .taken: chip(title: "\(name) · \(language("ทานแล้ว", "Taken"))", symbol: "checkmark.circle.fill", style: .taken)
        case .skipped: chip(title: "\(name) · \(language("ข้าม", "Skipped"))", symbol: "minus.circle.fill", style: .plain)
        case .dueNow: chip(title: "\(name) · \(language("ถึงเวลา", "Now"))", symbol: "bell.fill", style: .due)
        case .missed: chip(title: "\(name) · \(language("ยังไม่ทาน", "Not taken"))", symbol: "exclamationmark.circle.fill", style: .missed)
        case .upcoming: chip(title: "\(name) · \(slot.time.label(language))", symbol: slot.symbol, style: .plain)
        }
    }

    private func chip(title: String, symbol: String, style: ChipStyle) -> some View {
        Label(title, systemImage: symbol)
            .font(.title3.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(foreground(style))
            .background(background(style), in: Capsule())
            .overlay {
                Capsule().strokeBorder(border(style), lineWidth: 2)
            }
    }

    private func foreground(_ style: ChipStyle) -> Color {
        switch style {
        case .taken: .white
        case .due: Theme.red
        case .missed: .orange
        case .plain: .primary
        }
    }

    private func background(_ style: ChipStyle) -> Color {
        switch style {
        case .taken: Theme.greenFill
        case .due: Theme.red.opacity(0.12)
        case .missed: Color.orange.opacity(0.12)
        case .plain: Theme.fill
        }
    }

    private func border(_ style: ChipStyle) -> Color {
        switch style {
        case .due: Theme.red
        case .missed: .orange
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
    .environment(store)
}
