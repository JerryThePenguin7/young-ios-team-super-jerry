import SwiftUI

/// A medicine's times as big chips, by meal: "หลังอาหารเช้า · 07:15 น.". On a saved medicine, tap a chip to tick
/// that dose as taken today.
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
            // Wide enough for "Morning · Taken" on one line; a chip wraps onto 2 lines rather than cutting words off.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: chipWidth), spacing: 10, alignment: .leading)],
                      alignment: .leading, spacing: 10) {
                ForEach(medicine.orderedSlots, id: \.self) { slot in
                    if let now {
                        let status = store.status(of: medicine, at: medicine.doseTime(for: slot), now: now)
                        Button {
                            store.toggleTaken(medicine, at: slot, now: now)
                        } label: {
                            chip(for: slot, status: status)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityHint(status.isLogged ? language("แตะเพื่อยกเลิก", "Tap to undo")
                                                           : language("แตะเมื่อทานแล้ว", "Tap when you've taken it"))
                    } else {
                        chip(title: "\(medicine.doseLabel(at: slot, language)) · \(medicine.doseTime(for: slot).label(language))",
                             symbol: slot.symbol, style: .plain)
                    }
                }
            }
        }
    }

    /// The narrowest a chip gets. Grows with the text size, so big text gets fewer chips per row.
    @ScaledMetric(relativeTo: .title3) private var chipWidth: CGFloat = 210

    private enum ChipStyle { case plain, taken, due, missed }

    private func chip(for slot: TimeSlot, status: DoseStatus) -> some View {
        let name = medicine.doseLabel(at: slot, language)
        return switch status {
        case .taken: chip(title: "\(name) · \(language("ทานแล้ว", "Taken"))", symbol: "checkmark.circle.fill", style: .taken)
        case .skipped: chip(title: "\(name) · \(language("ข้าม", "Skipped"))", symbol: "minus.circle.fill", style: .plain)
        case .dueNow: chip(title: "\(name) · \(language("ถึงเวลา", "Now"))", symbol: "bell.fill", style: .due)
        case .missed: chip(title: "\(name) · \(language("ยังไม่ทาน", "Not taken"))", symbol: "exclamationmark.circle.fill", style: .missed)
        case .upcoming: chip(title: "\(name) · \(medicine.doseTime(for: slot).label(language))", symbol: slot.symbol, style: .plain)
        }
    }

    private func chip(title: String, symbol: String, style: ChipStyle) -> some View {
        Label(title, systemImage: symbol)
            .font(.title3.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .foregroundStyle(foreground(style))
            // A rounded rectangle, not a capsule, so a chip that wraps onto 2 lines still looks right.
            .background(background(style), in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .strokeBorder(border(style), lineWidth: 2)
            }
    }

    private func foreground(_ style: ChipStyle) -> Color {
        switch style {
        case .taken: .white
        case .due: .primary
        case .missed: .orange
        case .plain: .primary
        }
    }

    private func background(_ style: ChipStyle) -> Color {
        switch style {
        case .taken: Theme.greenFill
        case .due: Theme.yellow
        case .missed: Color.orange.opacity(0.12)
        case .plain: Theme.fill
        }
    }

    private func border(_ style: ChipStyle) -> Color {
        switch style {
        case .due: Theme.accent
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
