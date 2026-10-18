import SwiftUI

/// Home ▸ Today: a progress ring, then every dose for today grouped by time, each with a big check circle.
/// This is the main place to tick doses, like logging medications in Health.
struct TodayScheduleCard: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let doses: [ScheduledDose]
    let now: Date

    /// With very big text, rows stack vertically so nothing gets squeezed.
    private var isStacked: Bool { dynamicTypeSize.isAccessibilitySize }

    private func rowLayout(spacing: CGFloat) -> AnyLayout {
        isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
    }

    var body: some View {
        let taken = doses.filter(\.status.isTaken).count

        SummaryCard(title: "วันนี้ · Today", symbol: "calendar",
                    detail: now.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
            let summaryLayout = rowLayout(spacing: 20)
            summaryLayout {
                TodayProgressRing(taken: taken, total: doses.count)
                VStack(alignment: .leading, spacing: 4) {
                    Text(taken == doses.count ? "ทานครบแล้ว · All done" : "ทานแล้ว \(taken) จาก \(doses.count)")
                        .font(.title3.bold())
                    if let next = doses.first(where: { $0.status == .upcoming }) {
                        Label("ถัดไป · Next \(next.time.label)", systemImage: next.time.periodSymbol)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(times, id: \.self) { time in
                Divider()
                timeGroup(time)
            }
        }
    }

    private var times: [DoseTime] {
        Array(Set(doses.map(\.time))).sorted()
    }

    private func timeGroup(_ time: DoseTime) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(groupTitle(time), systemImage: time.periodSymbol)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            ForEach(doses.filter { $0.time == time }) { dose in
                row(dose)
            }
        }
    }

    /// "เช้า · 8:00 AM"
    private func groupTitle(_ time: DoseTime) -> String {
        if let slot = TimeSlot.at(time) { "\(slot.thai) · \(time.label)" } else { time.label }
    }

    private func row(_ dose: ScheduledDose) -> some View {
        let layout = rowLayout(spacing: 12)
        return layout {
            if !isStacked {
                MedicinePhoto(file: dose.medicine.photoFile, size: 52)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(dose.medicine.name.isEmpty ? "ยา (ไม่ทราบชื่อ)" : dose.medicine.name)
                    .font(.headline)
                Text(dose.medicine.meal.isEmpty
                     ? dose.medicine.amountLine
                     : "\(dose.medicine.amountLine) · \(dose.medicine.meal)")
                    .foregroundStyle(.secondary)
                statusLine(dose.status)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            DoseCheckButton(name: dose.medicine.name, status: dose.status) {
                store.toggleTaken(dose.medicine, at: dose.time, now: now)
            }
        }
    }

    @ViewBuilder
    private func statusLine(_ status: DoseStatus) -> some View {
        switch status {
        case .taken(let at):
            Label("ทานแล้ว \(at.formatted(date: .omitted, time: .shortened))", systemImage: "checkmark.circle.fill")
                .font(.subheadline.bold())
                .labelStyle(TintedIconLabelStyle(tint: Theme.taken))
        case .missed:
            Label("เลยเวลา · Late", systemImage: "exclamationmark.circle.fill")
                .font(.subheadline.bold())
                .labelStyle(TintedIconLabelStyle(tint: Theme.late))
        case .dueNow:
            Label("ถึงเวลา · Now", systemImage: "bell.fill")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.red)
        case .upcoming:
            EmptyView()
        }
    }
}

/// A big round check button: empty until taken, then a green check. Tap again to un-tick.
private struct DoseCheckButton: View {
    let name: String
    let status: DoseStatus
    let action: () -> Void

    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 52

    var body: some View {
        Button(action: action) {
            ZStack {
                if status.isTaken {
                    Circle().fill(Theme.taken)
                    Image(systemName: "checkmark")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                } else {
                    Circle().strokeBorder(ringColor, lineWidth: 3)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(status.isTaken ? "\(name), taken" : "Mark \(name) as taken")
        .accessibilityHint(status.isTaken ? "Tap to un-tick" : "")
    }

    private var ringColor: Color {
        switch status {
        case .dueNow: Theme.red
        case .missed: Theme.late
        default: Color.secondary.opacity(0.5)
        }
    }
}

/// Colors only the icon, so the text stays easy to read (orange or green text is hard to read on white).
struct TintedIconLabelStyle: LabelStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon.foregroundStyle(tint)
        }
    }
}

#Preview {
    let store = MedicineStore.preview()
    ScrollView {
        TodayScheduleCard(doses: store.doses(now: Date()), now: Date())
            .padding()
    }
    .background(Theme.background)
    .environment(store)
}
