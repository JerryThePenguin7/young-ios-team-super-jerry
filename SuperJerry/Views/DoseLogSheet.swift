import SwiftUI

/// Log one time's medicines (like the Health app): Taken or Skipped for each one, or "Log All as Taken".
/// Nothing is saved until Done.
struct DoseLogSheet: View {
    enum Kind: Hashable {
        case time(DoseTime)   // e.g. the 8:00 AM medicines
        case asNeeded         // "when needed" medicines, taken now
    }

    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss

    let kind: Kind
    let day: Date

    @State private var choices: [UUID: DoseLog] = [:]
    /// The medicines in this sheet, fixed when it opens so rows don't jump around while logging.
    @State private var medicines: [Medicine] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text(language.longDay(day))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(title)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                    }

                    if kind != .asNeeded && medicines.count > 1 {
                        Button {
                            for medicine in medicines { choices[medicine.id] = .taken(at: takenTime) }
                        } label: {
                            Label(language("ทานครบทุกตัวแล้ว", "Log All as Taken"), systemImage: "checkmark.circle")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Theme.green)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.surface, in: Capsule())
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(medicines) { medicine in
                        row(medicine)
                    }

                    Label(language("ตรวจกับฉลากจริงทุกครั้ง ไม่ใช่คำแนะนำทางการแพทย์",
                                   "Always check the real label. Not medical advice."),
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Text(language("เสร็จ", "Done"))
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundStyle(.white)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 700)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language("ยกเลิก", "Cancel")) { dismiss() }
                }
            }
            .onAppear(perform: load)
            .onDisappear { SpeechReader.shared.stop() }
        }
    }

    /// "8:00 AM Medication" or "ยาเวลา 08:00 น."
    private var title: String {
        switch kind {
        case .time(let time): language("ยาเวลา \(time.label(.thai))", "\(time.label(.english)) Medication")
        case .asNeeded: language("ยาเมื่อมีอาการ", "As Needed Medications")
        }
    }

    /// Today: now. An earlier day: the time the dose was due.
    private var takenTime: Date {
        if case .time(let time) = kind, !Calendar.current.isDateInToday(day) {
            return time.date(on: day)
        }
        return Date()
    }

    // MARK: One medicine

    private func row(_ medicine: Medicine) -> some View {
        let choice = choices[medicine.id]
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                if medicine.photoFile != nil {
                    MedicinePhoto(file: medicine.photoFile, size: 72)
                } else {
                    PillIcon(medicine: medicine, size: 72)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.displayName(language))
                        .font(.title2.bold())
                    Text(medicine.formLine(language))
                        .foregroundStyle(.secondary)
                    Text(doseLine(medicine, choice: choice))
                        .font(.headline)
                        .foregroundStyle(doseLineColor(choice))
                    if medicine.stock != nil && medicine.canCountStock {
                        Label(medicine.stockText(language), systemImage: "shippingbox")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    SpeechReader.shared.read(medicine, in: language)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.red)
                        .frame(width: 50, height: 50)
                        .background(Theme.fill, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language("อ่านออกเสียง", "Read aloud"))
            }

            if !medicine.meal.isEmpty || !medicine.warnings.isEmpty {
                Divider()
                if !medicine.meal.isEmpty {
                    Label(Medicine.mealName(medicine.meal, language), systemImage: "fork.knife")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                ForEach(medicine.warningLines(language), id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 12) {
                if kind != .asNeeded {
                    choiceButton(language("ข้าม", "Skipped"), symbol: "xmark.circle", selected: choice == .skipped,
                                 color: Theme.red, fill: Theme.card) {
                        choices[medicine.id] = choice == .skipped ? nil : .skipped
                    }
                }
                // Green, so Taken is easy to tell apart from Skipped.
                choiceButton(language("ทานแล้ว", "Taken"), symbol: "checkmark.circle", selected: choice?.isTaken == true,
                             color: Theme.green, fill: Theme.greenFill) {
                    choices[medicine.id] = choice?.isTaken == true ? nil : .taken(at: takenTime)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    /// "1 capsule at 3:16 PM" once taken, "Skipped", or how much to take.
    private func doseLine(_ medicine: Medicine, choice: DoseLog?) -> String {
        switch choice {
        case .taken(let date):
            let time = language.time(date)
            if medicine.unit.isEmpty { return language("ใช้ยาแล้ว เวลา \(time)", "Used at \(time)") }
            return language("ทาน \(medicine.doseText(.thai)) เวลา \(time)", "\(medicine.doseText(.english)) at \(time)")
        case .skipped:
            return language("ข้ามยานี้", "Skipped")
        case nil:
            return medicine.amountLine(language)
        }
    }

    private func doseLineColor(_ choice: DoseLog?) -> Color {
        switch choice {
        case .taken: Theme.green
        case .skipped: .secondary
        case nil: Theme.red
        }
    }

    /// Gray with colored words until chosen, then filled with white words.
    private func choiceButton(_ title: String, symbol: String, selected: Bool, color: Color, fill: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: selected ? "\(symbol).fill" : symbol)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 56)
                .foregroundStyle(selected ? Color.white : color)
                .background(selected ? fill : Theme.fill,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Loading and saving

    private func load() {
        guard medicines.isEmpty else { return }
        switch kind {
        case .time(let time):
            medicines = store.medicines(at: time, on: day)
            for medicine in medicines {
                if let record = store.record(for: medicine.id, at: time, on: day) {
                    choices[medicine.id] = DoseLog(record)
                }
            }
        case .asNeeded:
            medicines = store.medicines
                .filter(\.asNeeded)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    private func save() {
        for medicine in medicines {
            switch kind {
            case .time(let time):
                let before = store.record(for: medicine.id, at: time, on: day).map(DoseLog.init)
                // Only save what changed, so earlier "taken at" times stay as they were.
                if before != choices[medicine.id] {
                    store.setLog(choices[medicine.id], for: medicine.id, at: time, on: day)
                }
            case .asNeeded:
                if choices[medicine.id]?.isTaken == true { store.logAsNeeded(medicine) }
            }
        }
        dismiss()
    }
}

#Preview {
    DoseLogSheet(kind: .time(DoseTime(hour: 8)), day: Date())
        .environment(MedicineStore.preview())
        .environment(\.language, .english)
}
