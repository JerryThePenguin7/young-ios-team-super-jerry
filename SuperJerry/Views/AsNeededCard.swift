import SwiftUI

/// "When needed" medicines in Log, like paracetamol: "ครั้งละ 1 เม็ด ห่างกันอย่างน้อย 6 ชม. เมื่อมีอาการ".
/// They have no set time, but each one has a tick box like the meals: tap it when you take one. It stays ticked
/// for the rest of the day; tapping it again asks: take another dose, or take back the last one (a tick by mistake)?
/// A timeline (`DoseTimeline`) shows when it was taken and, if the label gives a gap, when it can be taken again.
/// Logging it again before the gap is over asks first, so nobody takes too much by mistake.
/// It sits at the top of the Log; "…" can move it below the meals (and back), for people who'd rather see meals first.
struct AsNeededCard: View {
    /// For scrolling to the card after it moves.
    static let scrollID = "asNeededCard"

    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    let medicines: [Medicine]
    let now: Date
    /// true when the user moved it below the meals.
    var isAtBottom = false
    /// Logs a dose, taken now.
    let take: (Medicine) -> Void
    /// Takes back today's last dose.
    let undo: (Medicine) -> Void
    /// Moves the card to the top of the Log or below the meals. nil: not in the "…" menu.
    var move: (() -> Void)? = nil
    /// The full log sheet for these medicines.
    let more: () -> Void

    /// A medicine being logged before its gap is over: ask first.
    @State private var tooSoon: Medicine?
    /// A ticked medicine tapped again: another dose, or undo?
    @State private var again: Medicine?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language("ยาเมื่อมีอาการ", "When needed"))
                        .font(.title3.bold())
                    Text(language("ไม่มีเวลาที่แน่นอน ทานเฉพาะเมื่อมีอาการ", "No set time. Take only when you need it."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                moreMenu
            }
            ForEach(medicines) { medicine in
                if medicine.id != medicines.first?.id { Divider() }
                row(medicine)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .alert(language("ยังไม่ครบเวลา", "It's too soon"), isPresented: tooSoonShown, presenting: tooSoon) { medicine in
            Button(language("ยังไม่\(medicine.thaiVerb)", "Not yet"), role: .cancel) {}
            Button(language("บันทึกว่า\(medicine.thaiVerb)แล้ว", "Log as taken")) { take(medicine) }
        } message: { medicine in
            Text(tooSoonMessage(medicine))
        }
        .alert(againTitle, isPresented: againShown, presenting: again) { medicine in
            Button(language("\(medicine.thaiVerb)อีกครั้งตอนนี้", "Take another one now")) { take(medicine) }
            Button(language("ยกเลิกครั้งล่าสุด", "Undo the last one"), role: .destructive) { undo(medicine) }
            Button(language("ปิด", "Close"), role: .cancel) {}
        } message: { medicine in
            Text(againMessage(medicine))
        }
    }

    // MARK: One medicine

    /// A tick box row like the meals', then the timeline.
    private func row(_ medicine: Medicine) -> some View {
        let count = takenToday(medicine).count
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                tap(medicine)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: count > 0 ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Theme.green)
                        .frame(width: 44, height: 44)
                        .contentTransition(.symbolEffect(.replace))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicine.title(language))
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)
                        // How much, and the least time between doses ("ห่างกันอย่างน้อย 6 ชั่วโมง").
                        BulletList(items: medicine.summaryBullets(language, includeTimes: false))
                        MedicineAlerts(medicine: medicine, showsNotes: false)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(medicine.title(language))
            .accessibilityValue(count > 0 ? language("วันนี้\(medicine.thaiVerb)แล้ว \(count) ครั้ง", "Taken \(count) times today")
                                          : language("วันนี้ยังไม่ได้\(medicine.thaiVerb)", "Not taken today"))
            .accessibilityHint(language("แตะสองครั้งเมื่อ\(medicine.thaiVerb)ยานี้", "Double-tap when you take it"))

            // Taken in the last 24 hours → now → when it can be taken again.
            DoseTimeline(medicine: medicine,
                         taken: store.takenTimes(of: medicine.id, since: now.addingTimeInterval(-24 * 3600)),
                         now: now)
                .padding(14)
                .background(Theme.fill.opacity(0.6), in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        }
        .padding(.vertical, 10)
    }

    /// Empty box: taken now (asking first if it's too soon). Ticked box: another one, or undo?
    private func tap(_ medicine: Medicine) {
        if !takenToday(medicine).isEmpty {
            again = medicine
        } else if nextDose(medicine) != nil {
            tooSoon = medicine
        } else {
            take(medicine)
        }
    }

    /// When it was taken today, oldest first.
    private func takenToday(_ medicine: Medicine) -> [Date] {
        store.takenTimes(of: medicine.id, since: Calendar.current.startOfDay(for: now))
    }

    /// When it can be taken again, while the label's gap isn't over yet (it can be from last night). nil = it can be taken now.
    private func nextDose(_ medicine: Medicine) -> Date? {
        guard let last = store.lastTaken(medicine.id), let next = medicine.nextDose(after: last), next > now else { return nil }
        return next
    }

    private func tooSoonMessage(_ medicine: Medicine) -> String {
        let last = store.lastTaken(medicine.id).map { language.time($0) } ?? ""
        let next = nextDose(medicine).map { language.time($0) } ?? ""
        let hours = String(format: "%g", medicine.hoursApart ?? 0)
        let verb = medicine.thaiVerb
        return language(
            "ฉลากบอกให้\(verb)ห่างกันอย่างน้อย \(hours) ชั่วโมง \(verb)ครั้งล่าสุดเมื่อ \(last) \(verb)ได้อีกครั้งหลัง \(next) ถ้าไม่แน่ใจ ให้ถามเภสัชกร",
            "The label says at least \(hours) hours apart. It was last taken at \(last), so the next dose is after \(next). If unsure, ask your pharmacist.")
    }

    /// "วันนี้ทานแล้ว 1 ครั้ง ล่าสุด 10:05 น.", and the label's gap if it isn't over yet.
    private func againMessage(_ medicine: Medicine) -> String {
        let times = takenToday(medicine)
        let last = times.last.map { language.time($0) } ?? ""
        let verb = medicine.thaiVerb
        var message = language("วันนี้\(verb)แล้ว \(times.count) ครั้ง ล่าสุด \(last)",
                               "Taken \(times.count) \(times.count == 1 ? "time" : "times") today, last at \(last).")
        if let next = nextDose(medicine) {
            let hours = String(format: "%g", medicine.hoursApart ?? 0)
            message += language(" ฉลากบอกให้\(verb)ห่างกันอย่างน้อย \(hours) ชั่วโมง \(verb)ได้อีกครั้งหลัง \(language.time(next))",
                                " The label says at least \(hours) hours apart, so the next dose is after \(language.time(next)).")
        }
        return message
    }

    private var tooSoonShown: Binding<Bool> {
        Binding(get: { tooSoon != nil }, set: { if !$0 { tooSoon = nil } })
    }

    /// The medicine's name, e.g. "ยาแก้ปวด ลดไข้ (Paracetamol)".
    private var againTitle: String {
        again?.title(language) ?? ""
    }

    private var againShown: Binding<Bool> {
        Binding(get: { again != nil }, set: { if !$0 { again = nil } })
    }

    // MARK: The "…" menu

    /// "…": the full log sheet, and moving the card ("ย้ายไปไว้ใต้มื้ออาหาร" or "ย้ายขึ้นไว้บนสุด").
    private var moreMenu: some View {
        Menu {
            Button(language("ดูรายละเอียด", "Details"), systemImage: "list.bullet", action: more)
            if let move {
                Button(isAtBottom ? language("ย้ายขึ้นไว้บนสุด", "Move to the top") : language("ย้ายไปไว้ใต้มื้ออาหาร", "Move below the meals"),
                       systemImage: isAtBottom ? "arrow.up.to.line" : "arrow.down.to.line",
                       action: move)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3.bold())
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.fill, in: Circle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel(language("ตัวเลือกเพิ่มเติม เช่น ย้ายการ์ดนี้", "More: details, or move this card"))
    }
}

#Preview {
    let store = MedicineStore.preview()
    var paracetamol = Medicine.blank
    paracetamol.name = "Paracetamol"
    paracetamol.strength = "500 mg"
    paracetamol.asNeeded = true
    paracetamol.slots = []
    paracetamol.hoursApart = 6
    paracetamol.labelDirections = "รับประทานครั้งละ 1 เม็ด ห่างกันอย่างน้อย 6 ชม. เมื่อมีอาการ"
    return ScrollView {
        AsNeededCard(medicines: [paracetamol], now: Date(), take: { _ in }, undo: { _ in }, move: {}, more: {})
            .padding()
    }
    .background(Theme.background)
    .environment(store)
    .environment(\.language, .thai)
}
