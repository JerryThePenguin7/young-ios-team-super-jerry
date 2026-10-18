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
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(time.label(language))
                        .font(.title3.bold())
                    badge
                    Spacer(minLength: 0)
                    if canLog {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Theme.red)
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
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.red, lineWidth: status == .dueNow ? 2 : 0)
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canLog)
        .accessibilityHint(language("แตะเพื่อบันทึกว่าทานแล้ว", "Tap to log these medicines"))
    }

    @ViewBuilder
    private var badge: some View {
        switch status {
        case .dueNow:
            badgeLabel(language("ถึงเวลาแล้ว", "Time to take"), color: Theme.card)
        case .missed:
            badgeLabel(language("เลยเวลาแล้ว", "Late"), color: .orange)
        default:
            EmptyView()
        }
    }

    private func badgeLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
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
