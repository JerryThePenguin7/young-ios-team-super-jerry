import Foundation
import Observation

/// Holds every saved medicine and every "taken" tick, and saves them to a JSON file on the device.
@Observable
final class MedicineStore {
    private(set) var medicines: [Medicine] = []
    private(set) var records: [DoseRecord] = []
    /// Keep Jenny's medicines in Apple's Reminders app.
    var remindersEnabled = false

    /// nil means "don't save" (used by Previews).
    private let fileURL: URL?

    init(inMemory: Bool = false) {
        fileURL = inMemory ? nil : URL.documentsDirectory.appending(path: "jenny-medicines.json")
        load()
        if !inMemory { AppleReminders.removeOldJennyNotifications() }
        fillMissingGroups()
    }

    func medicine(id: UUID) -> Medicine? {
        medicines.first { $0.id == id }
    }

    // MARK: Editing medicines

    /// Newest first, so a medicine you just scanned is at the top.
    func add(_ medicine: Medicine) {
        medicines.insert(medicine, at: 0)
        medicinesChanged()
        if medicine.group == nil { fillMissingGroups() }
    }

    func update(_ medicine: Medicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        medicines[index] = medicine
        medicinesChanged()
    }

    func delete(_ medicine: Medicine) {
        if let photoFile = medicine.photoFile { PhotoStore.delete(photoFile) }
        medicines.removeAll { $0.id == medicine.id }
        records.removeAll { $0.medicineID == medicine.id }
        medicinesChanged()
    }

    func eraseAll() {
        PhotoStore.deleteAll()
        medicines = []
        records = []
        medicinesChanged()
    }

    private func medicinesChanged() {
        save()
        if remindersEnabled {
            let current = medicines
            Task { _ = await AppleReminders.sync(current) }
        }
    }

    // MARK: Groups

    /// Groups medicines that don't have one yet: the name list and how it's used first, then the AI.
    private func fillMissingGroups() {
        var changed = false
        for index in medicines.indices where medicines[index].group == nil {
            let medicine = medicines[index]
            if let group = MedicineNames.entry(named: medicine.name)?.group
                ?? LabelReader.ruleGroup(route: medicine.route, name: medicine.name) {
                medicines[index].group = group
                changed = true
            }
        }
        if changed { save() }

        let ungrouped = medicines.filter { $0.group == nil }
        guard !ungrouped.isEmpty else { return }
        // If no AI could group it, it stays ungrouped (shown under "อื่น ๆ") and Jenny tries again next launch.
        Task {
            for medicine in ungrouped {
                if let result = await MedicineGrouper.group(for: medicine) {
                    setGroup(result.group, for: medicine.id)
                }
            }
        }
    }

    private func setGroup(_ group: MedicineGroup, for id: UUID) {
        guard let index = medicines.firstIndex(where: { $0.id == id }), medicines[index].group == nil else { return }
        medicines[index].group = group
        save()
    }

    // MARK: Taken today

    func status(of medicine: Medicine, at time: DoseTime, now: Date) -> DoseStatus {
        let day = Calendar.current.startOfDay(for: now)
        let takenAt = recordIndex(medicineID: medicine.id, time: time, day: day).map { records[$0].takenAt }
        let status = DoseStatus.make(time: time, takenAt: takenAt, day: day, now: now)
        // A medicine added after this time today didn't miss it: it starts tomorrow.
        if status == .missed && medicine.addedAt > time.date(on: day) { return .upcoming }
        return status
    }

    /// Ticks a dose as taken today, or un-ticks it.
    func toggleTaken(_ medicine: Medicine, at time: DoseTime, now: Date = Date()) {
        let day = Calendar.current.startOfDay(for: now)
        if let index = recordIndex(medicineID: medicine.id, time: time, day: day) {
            records.remove(at: index)
        } else {
            records.append(DoseRecord(medicineID: medicine.id, time: time, day: day, takenAt: now))
        }
        save()
    }

    /// Every dose today, in time order.
    func doses(now: Date) -> [ScheduledDose] {
        var result: [ScheduledDose] = []
        for medicine in medicines {
            for time in medicine.times {
                result.append(ScheduledDose(medicine: medicine, time: time,
                                            status: status(of: medicine, at: time, now: now)))
            }
        }
        return result.sorted { first, second in
            if first.time != second.time { return first.time < second.time }
            return first.medicine.name < second.medicine.name
        }
    }

    private func recordIndex(medicineID: UUID, time: DoseTime, day: Date) -> Int? {
        records.firstIndex { record in
            record.medicineID == medicineID && record.time == time
                && Calendar.current.isDate(record.day, inSameDayAs: day)
        }
    }

    // MARK: Reminders

    /// Applies `remindersEnabled`: adds Jenny's medicines to Apple Reminders, or takes them out.
    /// nil when reminders were turned off.
    func applyReminderSetting() async -> AppleReminders.Result? {
        defer { save() }
        guard remindersEnabled else {
            AppleReminders.removeAll()
            return nil
        }
        let result = await AppleReminders.sync(medicines)
        if case .added = result { return result }
        remindersEnabled = false
        return result
    }

    // MARK: Saving

    private nonisolated struct SavedData: Codable {
        var medicines: [Medicine]
        var records: [DoseRecord]
        var remindersEnabled: Bool
    }

    private func load() {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode(SavedData.self, from: data)
        else { return }
        medicines = saved.medicines
        // Keep 60 days of ticks so the file stays small.
        let cutoff = Date().addingTimeInterval(-60 * 24 * 60 * 60)
        records = saved.records.filter { $0.day > cutoff }
        // Turned on in an older version (Jenny's own notifications)? Ask again for Apple Reminders.
        remindersEnabled = saved.remindersEnabled && AppleReminders.hasAccess
    }

    private func save() {
        guard let fileURL else { return }
        let saved = SavedData(medicines: medicines, records: records, remindersEnabled: remindersEnabled)
        do {
            let data = try JSONEncoder().encode(saved)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Jenny couldn't save: \(error)")
        }
    }
}

// MARK: Xcode Previews

extension MedicineStore {
    /// For Xcode Previews only: the made-up envelopes in SampleLabels, never saved to the device.
    static func preview(empty: Bool = false) -> MedicineStore {
        let store = MedicineStore(inMemory: true)
        if !empty {
            for sample in SampleLabels.all.reversed() {
                if let reading = LabelReader.read(sample.lines) { store.add(reading.medicine) }
            }
        }
        return store
    }
}
