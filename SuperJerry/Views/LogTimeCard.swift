import SwiftUI

/// One time in "Log" as a checklist: "8:00 AM", then each medicine still to take with a big tick box.
/// Tap the box when you've taken it: it moves to "Taken" (like ticking off an item in the Reminders app).
/// Press and hold a medicine to mark it skipped; "…" opens the full log sheet.
struct LogTimeCard: View {
    @Environment(\.language) private var language
    let time: DoseTime
    let medicines: [Medicine]
    /// Today only: .dueNow shows "Time to take", .missed shows "Late".
    var status: DoseStatus = .upcoming
    /// false for days that haven't come yet.
    var canLog = true
    let tick: (Medicine) -> Void
    let skip: (Medicine) -> Void
    let more: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // One row when it fits; with very big text the badge goes on its own line.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    timeText
                    badge
                    Spacer(minLength: 8)
                    moreButton
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        timeText
                        Spacer(minLength: 8)
                        moreButton
                    }
                    badge
                }
            }
            ForEach(medicines) { medicine in
                row(medicine)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.red, lineWidth: status == .dueNow ? 2 : 0)
        }
    }

    /// One checklist row: an empty tick box, the name, how to take it in short bullets, and anything important.
    private func row(_ medicine: Medicine) -> some View {
        Button {
            tick(medicine)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "circle")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(canLog ? Theme.green : Color.secondary)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.title(language))
                        .font(.title3)
                    // Jenny's summary as bullets (the time is already this card's title).
                    // The label's exact words are on the medicine's own screen.
                    BulletList(items: medicine.summaryBullets(language, includeTimes: false))
                    // Expired, running low, or a warning from the label: seen before ticking.
                    // The envelope's "หมายเหตุ" notes are left out here; they're on the medicine's own screen.
                    MedicineAlerts(medicine: medicine, showsNotes: false)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canLog)
        .contextMenu {
            if canLog {
                Button(language("ทานแล้ว", "Taken"), systemImage: "checkmark.circle") { tick(medicine) }
                Button(language("ข้าม", "Skipped"), systemImage: "xmark.circle") { skip(medicine) }
            }
        }
        .accessibilityLabel(medicine.title(language))
        .accessibilityValue(language("ยังไม่ได้ทาน", "Not taken yet"))
        .accessibilityHint(language("แตะสองครั้งเมื่อทานแล้ว", "Double-tap when you've taken it"))
        .accessibilityAction(named: language("ข้าม", "Skipped")) { skip(medicine) }
    }

    private var timeText: some View {
        Text(time.label(language))
            .font(.title3.bold())
    }

    /// "…": the full log sheet (Taken or Skipped for each, Log All as Taken, read aloud).
    @ViewBuilder
    private var moreButton: some View {
        if canLog {
            Button(action: more) {
                Image(systemName: "ellipsis")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.red)
                    .frame(width: 44, height: 44)
                    .background(Theme.fill, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(language("ตัวเลือกเพิ่มเติม เช่น ข้าม หรือทานครบทุกตัว", "More: skip, or log all as taken"))
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch status {
        case .dueNow:
            badgeLabel(language("ถึงเวลาแล้ว", "Time to take"), symbol: "bell.fill", color: Theme.red)
        case .missed:
            badgeLabel(language("เลยเวลาแล้ว", "Late"), symbol: "exclamationmark.circle.fill", color: .orange)
        default:
            EmptyView()
        }
    }

    /// Dark text on a light tint, with a colored icon: white on orange is too hard to read.
    private func badgeLabel(_ title: String, symbol: String, color: Color) -> some View {
        Label {
            Text(title)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.18), in: Capsule())
    }
}

#Preview {
    let store = MedicineStore.preview()
    VStack {
        LogTimeCard(time: DoseTime(hour: 8), medicines: Array(store.medicines.prefix(2)), status: .dueNow,
                    tick: { _ in }, skip: { _ in }, more: {})
        LogTimeCard(time: DoseTime(hour: 18), medicines: Array(store.medicines.suffix(1)),
                    tick: { _ in }, skip: { _ in }, more: {})
    }
    .padding()
    .environment(\.language, .english)
}
