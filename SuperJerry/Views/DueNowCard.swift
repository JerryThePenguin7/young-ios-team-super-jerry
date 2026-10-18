import SwiftUI

/// Home ▸ Time to take: shown at the very top only while a dose is due or late, with one big button per dose.
struct DueNowCard: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let doses: [ScheduledDose]
    let now: Date

    var body: some View {
        SummaryCard(title: "ถึงเวลาทานยา · Time to take", symbol: "bell.fill",
                    detail: "\(doses.count)", highlighted: true) {
            ForEach(doses) { dose in
                if dose.id != doses.first?.id {
                    Divider()
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        // With very big text, the photo would squeeze the words, so leave it out.
                        if !dynamicTypeSize.isAccessibilitySize {
                            MedicinePhoto(file: dose.medicine.photoFile, size: 64)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dose.medicine.name.isEmpty ? "ยา (ไม่ทราบชื่อ)" : dose.medicine.name)
                                .font(.title3.bold())
                            Text(dose.medicine.amountLine)
                                .font(.headline)
                                .fontDesign(.rounded)
                                .foregroundStyle(Theme.red)
                            timeLine(dose)
                        }
                    }

                    Button("ทานแล้ว · I took it", systemImage: "checkmark") {
                        store.toggleTaken(dose.medicine, at: dose.time, now: now)
                    }
                    .buttonStyle(.big)
                    .accessibilityLabel("Mark \(dose.medicine.name) as taken")
                }
            }
        }
    }

    @ViewBuilder
    private func timeLine(_ dose: ScheduledDose) -> some View {
        let meal = dose.medicine.meal.isEmpty ? "" : " · \(dose.medicine.meal)"
        if dose.status == .missed {
            Label("\(dose.time.label)\(meal) · เลยเวลา (late)", systemImage: "exclamationmark.circle.fill")
                .labelStyle(TintedIconLabelStyle(tint: Theme.late))
        } else {
            Text("\(dose.time.label)\(meal)")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let store = MedicineStore.preview()
    let doses = Array(store.doses(now: Date()).prefix(2))
    ScrollView {
        DueNowCard(doses: doses, now: Date())
            .padding()
    }
    .background(Theme.background)
    .environment(store)
}
