import SwiftUI

/// "When needed" medicines in Log, like paracetamol: "ครั้งละ 1 เม็ด ห่างกันอย่างน้อย 6 ชม. เมื่อมีอาการ".
/// They have no set time, so each one has its own big **Taken** button instead of a tick box.
/// Jenny shows when it was last taken and, if the label gives a gap, when it can be taken again.
/// Logging it again before the gap is over asks first, so nobody takes too much by mistake.
struct AsNeededCard: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    let medicines: [Medicine]
    let now: Date
    let take: (Medicine) -> Void
    /// "…": the full log sheet for these medicines.
    let more: () -> Void

    /// A medicine being logged before its gap is over: ask first.
    @State private var tooSoon: Medicine?

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
                moreButton
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
            Button(language("ยังไม่ทาน", "Not yet"), role: .cancel) {}
            Button(language("บันทึกว่าทานแล้ว", "Log as taken")) { take(medicine) }
        } message: { medicine in
            Text(tooSoonMessage(medicine))
        }
    }

    // MARK: One medicine

    private func row(_ medicine: Medicine) -> some View {
        let next = nextDose(medicine)
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.title(language))
                    .font(.title3)
                // How much, and the least time between doses ("ห่างกันอย่างน้อย 6 ชั่วโมง").
                BulletList(items: medicine.summaryBullets(language, includeTimes: false))
                MedicineAlerts(medicine: medicine, showsNotes: false)
                takenToday(medicine)
                if let next {
                    Label {
                        Text(language("ทานได้อีกครั้งหลัง \(language.time(next))", "Next dose after \(language.time(next))"))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "hourglass")
                            .foregroundStyle(.orange)
                    }
                    .font(.callout.weight(.semibold))
                }
            }

            Button {
                if next != nil { tooSoon = medicine } else { take(medicine) }
            } label: {
                Label(language("ทานแล้ว", "Taken"), systemImage: "checkmark.circle")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.green)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(language("ทาน \(medicine.title(.thai)) แล้ว", "Taken: \(medicine.title(.english))"))
            .accessibilityHint(language("แตะเมื่อทานยานี้แล้ว", "Tap after you've taken it"))
        }
        .padding(.vertical, 10)
    }

    /// "วันนี้ทานแล้ว 2 ครั้ง ล่าสุด 10:15 น." Nothing if it hasn't been taken today.
    @ViewBuilder
    private func takenToday(_ medicine: Medicine) -> some View {
        let count = store.takenCount(of: medicine.id, on: now)
        if count > 0, let last = store.lastTaken(medicine.id) {
            let time = language.time(last)
            Label(language("วันนี้ทานแล้ว \(count) ครั้ง ล่าสุด \(time)",
                           count == 1 ? "Taken once today, at \(time)" : "Taken \(count) times today, last at \(time)"),
                  systemImage: "clock")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
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
        return language(
            "ฉลากบอกให้ทานห่างกันอย่างน้อย \(hours) ชั่วโมง ทานครั้งล่าสุดเมื่อ \(last) ทานได้อีกครั้งหลัง \(next) ถ้าไม่แน่ใจ ให้ถามเภสัชกร",
            "The label says at least \(hours) hours apart. It was last taken at \(last), so the next dose is after \(next). If unsure, ask your pharmacist.")
    }

    private var tooSoonShown: Binding<Bool> {
        Binding(get: { tooSoon != nil }, set: { if !$0 { tooSoon = nil } })
    }

    private var moreButton: some View {
        Button(action: more) {
            Image(systemName: "ellipsis")
                .font(.title3.bold())
                .foregroundStyle(Theme.red)
                .frame(width: 44, height: 44)
                .background(Theme.fill, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language("ตัวเลือกเพิ่มเติม", "More"))
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
        AsNeededCard(medicines: [paracetamol], now: Date(), take: { _ in }, more: {})
            .padding()
    }
    .background(Theme.background)
    .environment(store)
    .environment(\.language, .thai)
}
