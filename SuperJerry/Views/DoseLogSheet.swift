import SwiftUI

/// Log one meal's medicines (like the Health app): Taken or Skipped for each one, or "Log All as Taken".
/// Nothing is saved until Done. Tap a medicine's name to open it in Your Medications (what's chosen is saved first).
struct DoseLogSheet: View {
    enum Kind: Hashable {
        case meal(TimeSlot)   // e.g. breakfast: before and after eating
        case asNeeded         // "when needed" medicines, taken now
    }

    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss

    let kind: Kind
    let day: Date
    /// Opens a medicine's own screen (the sheet closes first). nil: names aren't buttons.
    var openMedicine: ((UUID) -> Void)? = nil

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
                            for medicine in medicines { choices[medicine.id] = .taken(at: takenTime(medicine)) }
                        } label: {
                            Label(language("ทานครบทุกตัวแล้ว", "Log All as Taken"), systemImage: "checkmark.circle")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Theme.green)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.surface, in: Capsule())
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.pressable)
                    }

                    ForEach(medicines) { medicine in
                        row(medicine)
                    }

                    Label(language("ตรวจกับฉลากจริงทุกครั้ง ไม่ใช่คำแนะนำทางการแพทย์",
                                   "Always check the real label. Not medical advice."),
                          systemImage: "info.circle")
                        .font(.subheadline)
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
                        .background(Theme.accentFill, in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                }
                .buttonStyle(.pressable)
                .frame(maxWidth: 700)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                // The list fades out behind Done: no gray band with a hard edge, and no text peeking under the button.
                .background {
                    LinearGradient(colors: [Theme.background.opacity(0), Theme.background],
                                   startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35))
                        .ignoresSafeArea()
                }
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

    /// "ยามื้อเช้า" or "Breakfast Medications"
    private var title: String {
        switch kind {
        case .meal(let slot): language("ยา\(slot.mealName(.thai))", "\(slot.mealName(.english)) Medications")
        case .asNeeded: language("ยาเมื่อมีอาการ", "As Needed Medications")
        }
    }

    /// Today: now. An earlier day: the time the dose was due.
    private func takenTime(_ medicine: Medicine) -> Date {
        if case .meal(let slot) = kind, !Calendar.current.isDateInToday(day) {
            return medicine.doseTime(for: slot).date(on: day)
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
                    name(medicine)
                    Text(medicine.formLine(language))
                        .foregroundStyle(.secondary)
                    // "หลังอาหารเช้า · 07:15 น."
                    if case .meal(let slot) = kind {
                        Label("\(medicine.doseLabel(at: slot, language)) · \(medicine.doseTime(for: slot).label(language))",
                              systemImage: "clock")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Text(doseLine(medicine, choice: choice))
                        .font(.headline)
                        .foregroundStyle(doseLineColor(choice))
                        .fixedSize(horizontal: false, vertical: true)
                    // In English the line above is Yao's summary, so show the label's own words too.
                    if language == .english, choice == nil, let directions = medicine.directions {
                        Text(directions)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if medicine.isExpired() || medicine.expiresSoon() {
                        ExpiryLabel(medicine: medicine)
                    }
                    if medicine.stock != nil && medicine.canCountStock {
                        Label(medicine.stockText(language), systemImage: "shippingbox")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    // A "when needed" medicine whose gap since the last dose isn't over yet.
                    if kind == .asNeeded, let last = store.lastTaken(medicine.id),
                       let next = medicine.nextDose(after: last), next > Date() {
                        Label(language("ยังไม่ครบเวลา ทานได้อีกครั้งหลัง \(language.time(next))",
                                       "Too soon: next dose after \(language.time(next))"),
                              systemImage: "hourglass")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    SpeechReader.shared.read(medicine, in: language)
                } label: {
                    RoundIcon(symbol: "speaker.wave.2.fill")
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(language("อ่านออกเสียง", "Read aloud"))
            }

            // The envelope's "หมายเหตุ" notes are left out of the log; they're on the medicine's own screen.
            let warnings = medicine.warningLines(language, includeNotes: false)
            if !medicine.meal.isEmpty || !warnings.isEmpty {
                Divider()
                if !medicine.meal.isEmpty {
                    Label(Medicine.mealName(medicine.meal, language), systemImage: "fork.knife")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                ForEach(warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }

            // Side by side, or one above the other when the text is very big.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { choiceButtons(medicine, choice: choice) }
                VStack(spacing: 12) { choiceButtons(medicine, choice: choice) }
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    /// The name. With `openMedicine`, a button (with a ›) that opens the medicine in Your Medications.
    @ViewBuilder
    private func name(_ medicine: Medicine) -> some View {
        let text = Text(medicine.title(language))
            .font(.title2.bold())
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        if openMedicine != nil {
            Button {
                open(medicine)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    text
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(language("เปิดยานี้ในหน้า ยาของคุณ", "Opens this medicine in Your Medications"))
        } else {
            text
        }
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
            // Thai: the label's own words. English: Yao's summary (the label's words are shown below it).
            return medicine.instruction(language)
        }
    }

    @ViewBuilder
    private func choiceButtons(_ medicine: Medicine, choice: DoseLog?) -> some View {
        if kind != .asNeeded {
            choiceButton(language("ข้าม", "Skipped"), symbol: "xmark.circle", selected: choice == .skipped,
                         color: Theme.red, fill: Theme.redFill) {
                choices[medicine.id] = choice == .skipped ? nil : .skipped
            }
        }
        // Green, so Taken is easy to tell apart from Skipped.
        choiceButton(language("ทานแล้ว", "Taken"), symbol: "checkmark.circle", selected: choice?.isTaken == true,
                     color: Theme.green, fill: Theme.greenFill) {
            choices[medicine.id] = choice?.isTaken == true ? nil : .taken(at: takenTime(medicine))
        }
    }

    private func doseLineColor(_ choice: DoseLog?) -> Color {
        switch choice {
        case .taken: Theme.green
        case .skipped: .secondary
        case nil: Theme.accent
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
                            in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Loading and saving

    private func load() {
        guard medicines.isEmpty else { return }
        switch kind {
        case .meal(let slot):
            medicines = store.meals(on: day).first { $0.slot == slot }?.medicines ?? []
            for medicine in medicines {
                if let record = store.record(for: medicine, at: slot, on: day) {
                    choices[medicine.id] = DoseLog(record)
                }
            }
        case .asNeeded:
            medicines = store.medicines
                .filter(\.asNeeded)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    /// Done: save, and close.
    private func save() {
        saveChoices()
        dismiss()
    }

    /// A medicine's name: save what's chosen, close the sheet, and open the medicine in Your Medications.
    private func open(_ medicine: Medicine) {
        saveChoices()
        openMedicine?(medicine.id)
        dismiss()
    }

    private func saveChoices() {
        for medicine in medicines {
            switch kind {
            case .meal(let slot):
                let before = store.record(for: medicine, at: slot, on: day).map(DoseLog.init)
                // Only save what changed, so earlier "taken at" times stay as they were.
                if before != choices[medicine.id] {
                    store.setLog(choices[medicine.id], for: medicine, at: slot, on: day)
                }
            case .asNeeded:
                if choices[medicine.id]?.isTaken == true { store.logAsNeeded(medicine) }
            }
        }
        // Saved once: a second save mustn't log "when needed" doses twice.
        if kind == .asNeeded { choices = [:] }
    }
}

#Preview {
    DoseLogSheet(kind: .meal(.morning), day: Date()) { _ in }
        .environment(MedicineStore.preview())
        .environment(\.language, .english)
}
