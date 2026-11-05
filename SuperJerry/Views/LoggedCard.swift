import SwiftUI

/// "Taken": what was taken (green ✓) or skipped on this day, by meal ("มื้อเช้า"), like the completed items in Reminders.
/// "When needed" doses are listed by the time they were taken. Tap a medicine's tick to undo it (it goes back
/// to the checklist); tap a meal or time to open its log sheet.
struct LoggedCard: View {
    @Environment(\.language) private var language
    let logged: [LoggedTime]
    let now: Date
    /// Untick one dose: it goes back to the checklist.
    let undo: (LoggedDose) -> Void
    let open: (LoggedTime) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(language("ทานแล้ว", "Taken"), systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(Theme.green)
                .padding(.bottom, 12)
            ForEach(logged) { group in
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        open(group)
                    } label: {
                        header(group)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(language("แตะเพื่อเปิดรายละเอียด", "Tap for details"))
                    ForEach(group.doses) { dose in
                        row(dose)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    /// "มื้อเช้า · 3 ชม. ที่แล้ว ›" (or "10:15 น." for a "when needed" dose) on one line when it fits,
    /// otherwise one under the other.
    private func header(_ group: LoggedTime) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                timeText(group)
                Spacer(minLength: 8)
                agoText(group)
                chevron
            }
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    timeText(group)
                    agoText(group)
                }
                Spacer(minLength: 8)
                chevron
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    /// A ticked row: tap to undo.
    private func row(_ dose: LoggedDose) -> some View {
        Button {
            undo(dose)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: dose.record.isSkipped ? "minus.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(dose.record.isSkipped ? Color.secondary : Theme.green)
                    .frame(width: 44, height: 44)
                Text(dose.medicine.title(language))
                    .font(.title3)
                    .strikethrough(dose.record.isSkipped, color: .secondary)
                if dose.record.isSkipped {
                    Text(language("ข้าม", "Skipped"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dose.medicine.title(language))
        .accessibilityValue(dose.record.isSkipped ? language("ข้าม", "Skipped") : language("ทานแล้ว", "Taken"))
        .accessibilityHint(language("แตะสองครั้งเพื่อยกเลิก", "Double-tap to undo"))
    }

    private func timeText(_ group: LoggedTime) -> some View {
        Text(group.slot.map { $0.mealName(language) } ?? group.time.label(language))
            .font(.title3.bold())
    }

    private func agoText(_ group: LoggedTime) -> some View {
        Text(language.timeAgo(group.loggedAt, now: now))
            .foregroundStyle(.secondary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.tertiary)
    }
}

#Preview {
    let store = MedicineStore.preview()
    let medicine = store.medicines[0]
    let record = DoseRecord(medicineID: medicine.id, time: DoseTime(hour: 7, minute: 15), day: Date(),
                            takenAt: Date().addingTimeInterval(-3600), slot: .morning)
    LoggedCard(logged: [LoggedTime(time: record.time, doses: [LoggedDose(medicine: medicine, record: record)], slot: .morning)],
               now: Date(), undo: { _ in }) { _ in }
        .padding()
        .environment(\.language, .english)
}
