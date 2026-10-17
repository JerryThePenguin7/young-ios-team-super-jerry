import Foundation
import Observation

/// Holds every medicine and every "taken" record, and saves them to a JSON file on the device.
@Observable
final class MedicineStore {
    private(set) var medicines: [Medicine] = []
    private(set) var records: [DoseRecord] = []
    var remindersEnabled = false

    /// nil means "don't save" (used by Previews).
    private let fileURL: URL?

    init(inMemory: Bool = false) {
        fileURL = inMemory ? nil : URL.documentsDirectory.appending(path: "jenny-data.json")
        load()
    }

    // MARK: Today

    func doses(on day: Date, now: Date) -> [ScheduledDose] {
        let startOfDay = Calendar.current.startOfDay(for: day)
        var result: [ScheduledDose] = []
        for medicine in medicines {
            for time in medicine.times {
                let takenAt = recordIndex(medicineID: medicine.id, time: time, day: startOfDay)
                    .map { records[$0].takenAt }
                let status = DoseStatus.make(time: time, takenAt: takenAt, day: startOfDay, now: now)
                result.append(ScheduledDose(medicine: medicine, time: time, status: status))
            }
        }
        return result.sorted { first, second in
            if first.time != second.time { return first.time < second.time }
            return first.medicine.name < second.medicine.name
        }
    }

    /// Marks a dose as taken, or un-marks it if it was already taken.
    func toggleTaken(_ dose: ScheduledDose, on day: Date, now: Date = Date()) {
        let startOfDay = Calendar.current.startOfDay(for: day)
        if let index = recordIndex(medicineID: dose.medicine.id, time: dose.time, day: startOfDay) {
            records.remove(at: index)
        } else {
            records.append(DoseRecord(
                medicineID: dose.medicine.id,
                medicineName: dose.medicine.name,
                time: dose.time,
                day: startOfDay,
                takenAt: now
            ))
        }
        save()
    }

    private func recordIndex(medicineID: UUID, time: DoseTime, day: Date) -> Int? {
        records.firstIndex { record in
            record.medicineID == medicineID && record.time == time
                && Calendar.current.isDate(record.day, inSameDayAs: day)
        }
    }

    // MARK: History

    /// One summary per day, oldest first, ending on `end`.
    func summaries(lastDays count: Int, endingOn end: Date) -> [DaySummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: end)
        let currentIDs = Set(medicines.map(\.id))
        let dosesPerDay = medicines.reduce(0) { $0 + $1.times.count }

        var result: [DaySummary] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let taken = records.filter { record in
                currentIDs.contains(record.medicineID) && calendar.isDate(record.day, inSameDayAs: day)
            }.count
            result.append(DaySummary(date: day, taken: min(taken, dosesPerDay), total: dosesPerDay))
        }
        return result
    }

    // MARK: Editing medicines

    func add(_ newMedicines: [Medicine]) {
        medicines.append(contentsOf: newMedicines)
        medicinesChanged()
    }

    func update(_ medicine: Medicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        medicines[index] = medicine
        medicinesChanged()
    }

    func delete(_ medicine: Medicine) {
        medicines.removeAll { $0.id == medicine.id }
        medicinesChanged()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            medicines.remove(at: index)
        }
        medicinesChanged()
    }

    private func medicinesChanged() {
        save()
        if remindersEnabled {
            let current = medicines
            Task { await ReminderScheduler.schedule(current) }
        }
    }

    // MARK: Reminders

    /// Applies `remindersEnabled`. Returns false if the user said no to notifications.
    func applyReminderSetting() async -> Bool {
        defer { save() }
        guard remindersEnabled else {
            ReminderScheduler.cancelAll()
            return true
        }
        guard await ReminderScheduler.requestPermission() else {
            remindersEnabled = false
            return false
        }
        await ReminderScheduler.schedule(medicines)
        return true
    }

    // MARK: Sample data and reset

    /// Made-up medicines and a week of made-up history, so the demo isn't empty.
    /// Synthetic data only (PDPA): no real patient information.
    func loadSampleData(now: Date = Date()) {
        let samples = [
            Medicine(name: "Amlodipine", dose: "5 mg · 1 tablet", note: "After breakfast",
                     times: [DoseTime(hour: 8)]),
            Medicine(name: "Metformin", dose: "500 mg · 1 tablet", note: "After meals",
                     times: [DoseTime(hour: 8), DoseTime(hour: 18)]),
            Medicine(name: "Vitamin D", dose: "1 capsule", note: "With lunch",
                     times: [DoseTime(hour: 12)]),
            Medicine(name: "Simvastatin", dose: "20 mg · 1 tablet", note: "At bedtime",
                     times: [DoseTime(hour: 21)]),
        ]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        var sampleRecords: [DoseRecord] = []
        for dayOffset in 1...6 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            for (medicineIndex, medicine) in samples.enumerated() {
                for time in medicine.times {
                    // Skip a few doses so the history shows some misses.
                    if (dayOffset + medicineIndex + time.hour) % 7 == 0 { continue }
                    sampleRecords.append(DoseRecord(
                        medicineID: medicine.id,
                        medicineName: medicine.name,
                        time: time,
                        day: day,
                        takenAt: time.date(on: day).addingTimeInterval(Double(dayOffset * 4) * 60)
                    ))
                }
            }
        }

        medicines = samples
        records = sampleRecords
        medicinesChanged()
    }

    func eraseAll() {
        medicines = []
        records = []
        medicinesChanged()
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
        else {
            loadSampleData()
            return
        }
        medicines = saved.medicines
        records = saved.records
        remindersEnabled = saved.remindersEnabled
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
