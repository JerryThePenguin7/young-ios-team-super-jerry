import SwiftUI

/// One medicine at one time, with a big button to mark it as taken (tap again to undo).
struct DoseCard: View {
    let dose: ScheduledDose
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(dose.time.label) · \(dose.time.periodName)", systemImage: dose.time.periodSymbol)
                    .font(.headline)
                    .foregroundStyle(Theme.red)
                Spacer()
                statusPill
            }

            Text(dose.medicine.name)
                .font(.title2.bold())

            if !dose.medicine.details.isEmpty {
                Text(dose.medicine.details)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button(action: onToggle) {
                Label(buttonTitle, systemImage: isTaken ? "checkmark.circle.fill" : "circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(isTaken ? Theme.red : Color.white)
                    .background(
                        isTaken ? Theme.red.opacity(0.12) : Theme.card,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityHint(isTaken ? "Marks this dose as not taken" : "Marks this dose as taken")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(dose.status == .missed ? Theme.red : Theme.red.opacity(0.15),
                              lineWidth: dose.status == .missed ? 2 : 1)
        }
    }

    private var isTaken: Bool { dose.status.isTaken }

    private var buttonTitle: String {
        if case .taken(let takenAt) = dose.status {
            return "Taken at \(takenAt.formatted(date: .omitted, time: .shortened))"
        }
        return "Mark as taken"
    }

    private var statusPill: some View {
        Label(statusText, systemImage: statusSymbol)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(statusIsLoud ? Color.white : Theme.red)
            .background(statusIsLoud ? Theme.card : Theme.red.opacity(0.12), in: Capsule())
    }

    /// Red pill with white text for "Time now" and "Missed".
    private var statusIsLoud: Bool {
        dose.status == .dueNow || dose.status == .missed
    }

    private var statusText: String {
        switch dose.status {
        case .taken: "Taken"
        case .dueNow: "Time now"
        case .missed: "Missed"
        case .upcoming: "Later"
        }
    }

    private var statusSymbol: String {
        switch dose.status {
        case .taken: "checkmark"
        case .dueNow: "bell.fill"
        case .missed: "exclamationmark.triangle.fill"
        case .upcoming: "clock"
        }
    }
}

#Preview {
    let medicine = Medicine(name: "Metformin", dose: "500 mg · 1 tablet", note: "After meals",
                            times: [DoseTime(hour: 8)])
    ScrollView {
        VStack(spacing: 16) {
            DoseCard(dose: ScheduledDose(medicine: medicine, time: DoseTime(hour: 8), status: .missed)) {}
            DoseCard(dose: ScheduledDose(medicine: medicine, time: DoseTime(hour: 12), status: .dueNow)) {}
            DoseCard(dose: ScheduledDose(medicine: medicine, time: DoseTime(hour: 18),
                                         status: .taken(at: Date()))) {}
            DoseCard(dose: ScheduledDose(medicine: medicine, time: DoseTime(hour: 21), status: .upcoming)) {}
        }
        .padding()
    }
    .background(Theme.background)
}
