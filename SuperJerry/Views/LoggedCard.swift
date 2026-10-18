import SwiftUI

/// "Logged" (like the Health app): what was taken (✓) or skipped on this day, by time.
/// Tap a time to change it.
struct LoggedCard: View {
    @Environment(\.language) private var language
    let logged: [LoggedTime]
    let now: Date
    let open: (DoseTime) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(language("บันทึกแล้ว", "Logged"))
                .font(.headline)
                .padding(.bottom, 12)
            ForEach(logged) { group in
                Divider()
                Button {
                    open(group.time)
                } label: {
                    row(group)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func row(_ group: LoggedTime) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // "8:00 AM · 3 hr. ago" on one line when it fits, otherwise one under the other.
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
            ForEach(group.doses) { dose in
                HStack(spacing: 10) {
                    Image(systemName: dose.record.isSkipped ? "minus.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(dose.record.isSkipped ? Color.secondary : Theme.red)
                    Text(dose.medicine.displayName(language))
                    if dose.record.isSkipped {
                        Text(language("ข้าม", "Skipped"))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.title3)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func timeText(_ group: LoggedTime) -> some View {
        Text(group.time.label(language))
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
    let record = DoseRecord(medicineID: medicine.id, time: DoseTime(hour: 8), day: Date(),
                            takenAt: Date().addingTimeInterval(-3600))
    LoggedCard(logged: [LoggedTime(time: DoseTime(hour: 8), doses: [LoggedDose(medicine: medicine, record: record)])],
               now: Date()) { _ in }
        .padding()
        .environment(\.language, .english)
}
