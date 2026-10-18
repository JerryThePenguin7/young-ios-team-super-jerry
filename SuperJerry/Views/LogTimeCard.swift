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
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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

    private var timeText: some View {
        Text(time.label(language))
            .font(.title3.bold())
    }

    /// A round + (the whole card is the button; VoiceOver hears the hint).
    @ViewBuilder
    private var logPill: some View {
        if canLog {
            Image(systemName: "plus")
                .font(.title3.bold())
                .foregroundStyle(Theme.red)
                .frame(width: 44, height: 44)
                .background(Theme.fill, in: Circle())
                .accessibilityHidden(true)
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
        LogTimeCard(time: DoseTime(hour: 8), medicines: Array(store.medicines.prefix(2)), status: .dueNow) {}
        LogTimeCard(time: DoseTime(hour: 18), medicines: Array(store.medicines.suffix(1))) {}
    }
    .padding()
    .environment(\.language, .english)
}
