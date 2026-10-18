import SwiftUI

/// One time in "Log" (like the Health app): "8:00 AM", the medicines still to take then, and a + to log them.
struct LogTimeCard: View {
    @Environment(\.language) private var language
    let time: DoseTime
    let medicines: [Medicine]
    /// Today only: .dueNow shows "Time to take", .missed shows "Late".
    var status: DoseStatus = .upcoming
    /// false for days that haven't come yet.
    var canLog = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                // One row when it fits; with very big text the badge and "Log" go on their own lines.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        timeText
                        badge
                        Spacer(minLength: 8)
                        logPill
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        timeText
                        badge
                        logPill
                    }
                }
                ForEach(medicines) { medicine in
                    HStack(spacing: 12) {
                        PillIcon(medicine: medicine)
                        Text(medicine.displayName(language))
                            .font(.title3)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.red, lineWidth: status == .dueNow ? 2 : 0)
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .buttonStyle(.pressable)
        .disabled(!canLog)
        .accessibilityHint(language("แตะเพื่อบันทึกว่าทานแล้ว", "Tap to log these medicines"))
    }

    private var timeText: some View {
        Text(time.label(language))
            .font(.title3.bold())
    }

    /// A round + (the whole card is the button; VoiceOver hears the hint).
    @ViewBuilder
    private var logPill: some View {
        if canLog {
            RoundIcon(symbol: "plus")
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch status {
        case .dueNow:
            StatusBadge(title: language("ถึงเวลาแล้ว", "Time to take"), symbol: "bell.fill", color: Theme.red)
        case .missed:
            StatusBadge(title: language("เลยเวลาแล้ว", "Late"), symbol: "exclamationmark.circle.fill", color: .orange)
        default:
            EmptyView()
        }
    }

}

#Preview {
    let store = MedicineStore.preview()
    VStack {
        LogTimeCard(time: DoseTime(hour: 8), medicines: Array(store.medicines.prefix(2)), status: .dueNow) {}
        LogTimeCard(time: DoseTime(hour: 18), medicines: Array(store.medicines.suffix(1))) {}
    }
    .padding()
    .environment(\.language, .english)
}
