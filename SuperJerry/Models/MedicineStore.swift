import Foundation
import Observation

/// Holds every saved medicine and every "taken" tick, and saves them to a JSON file on the device.
@Observable
final class MedicineStore {
    private(set) var medicines: [Medicine] = []
    private(set) var records: [DoseRecord] = []
    /// Keep Jenny's medicines in Apple's Reminders app.
    var remindersEnabled = false
    /// When the user eats. Pill times follow these (`Medicine.doseTime(for:)`). Change them with `setMealTimes`.
    private(set) var mealTimes = MealTimes.current
    /// Waits a moment before rewriting reminders, so turning a time wheel doesn't rewrite them at every step.
    @ObservationIgnored private var reminderRefresh: Task<Void, Never>?

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

    /// A saved medicine that's the same as this one: the same name (ignoring capitals, spaces and the
    /// Thai name in brackets), or two names for the same medicine in Jenny's list (e.g. a brand and its generic).
    func duplicate(of medicine: Medicine) -> Medicine? {
        let key = MedicineNames.matchKey(medicine.displayName(.english))
        guard !medicine.name.isEmpty, !key.isEmpty else { return nil }
        let listName = MedicineNames.entry(named: medicine.name)?.name
        return medicines.first { saved in
            guard saved.id != medicine.id else { return false }
            if MedicineNames.matchKey(saved.displayName(.english)) == key { return true }
            guard let listName else { return false }
            return MedicineNames.entry(named: saved.name)?.name == listName
        }
    }

    /// Newest first, so a medicine you just scanned is at the top.
    func add(_ medicine: Medicine) {
        medicines.insert(medicine, at: 0)
        medicinesChanged()
        if medicine.group == nil { fillMissingGroups() }
    }

    func update(_ medicine: Medicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        var updated = medicine
        // The editor doesn't change the count; keep the latest one (doses may have been logged meanwhile).
        updated.stock = medicines[index].stock
        updated.stockFull = medicines[index].stockFull
        updated.lowAt = medicines[index].lowAt
        medicines[index] = updated
        // "ก่อนอาหาร" may have become "หลังอาหาร": its ticks move to the new time.
        rekeyRecords()
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
        refreshReminders()
    }

    // MARK: Meal times

    /// New meal times (from the tutorial or Settings). Every tick stays on its meal, at the meal's new time.
    func setMealTimes(_ meals: MealTimes) {
        guard meals != mealTimes else { return }
        MealTimes.current = meals
        mealTimes = meals
        rekeyRecords()
        save()
        reminderRefresh?.cancel()
        reminderRefresh = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            refreshReminders()
        }
    }

    /// Each tick's time follows its meal and the medicine's ก่อน/หลังอาหาร, so it still matches the schedule.
    private func rekeyRecords() {
        let meals = mealTimes
        for index in records.indices {
            guard let slot = records[index].slot, let medicine = medicine(id: records[index].medicineID) else { continue }
            records[index].time = medicine.doseTime(for: slot, meals: meals)
        }
    }

    /// Older versions used fixed times (8:00, 12:00, 18:00, 21:00). Give those ticks their meal.
    private func upgradeOldRecords() {
        for index in records.indices where records[index].slot == nil {
            let record = records[index]
            guard let medicine = medicine(id: record.medicineID), !medicine.asNeeded, record.time.minute == 0,
                  let slot = TimeSlot.legacy(hour: record.time.hour), medicine.slots.contains(slot) else { continue }
            records[index].slot = slot
        }
        rekeyRecords()
    }

    /// Rewrites Jenny's reminders, e.g. after the user switches between Thai and English.
    func refreshReminders() {
        guard remindersEnabled else { return }
        let current = medicines
        Task { _ = await AppleReminders.sync(current) }
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

    // MARK: Taken or skipped

    /// Today's status of one dose, for the chips on a medicine.
    func status(of medicine: Medicine, at time: DoseTime, now: Date) -> DoseStatus {
        let day = Calendar.current.startOfDay(for: now)
        let status = DoseStatus.make(time: time, record: record(for: medicine.id, at: time, on: day), day: day, now: now)
        // A medicine added after this time today didn't miss it: it starts tomorrow.
        if status == .missed && medicine.addedAt > time.date(on: day) { return .upcoming }
        return status
    }

    /// What the user logged for one dose on one day, if anything.
    func record(for medicineID: UUID, at time: DoseTime, on day: Date) -> DoseRecord? {
        recordIndex(medicineID: medicineID, time: time, day: day).map { records[$0] }
    }

    /// The last time this medicine was taken, on any day. For "when needed" medicines: when can it be taken again?
    func lastTaken(_ medicineID: UUID) -> Date? {
        records.filter { $0.medicineID == medicineID && !$0.isSkipped }.map(\.takenAt).max()
    }

    /// When this medicine was taken since a moment (e.g. the last 24 hours), oldest first. For the "when needed" timeline.
    func takenTimes(of medicineID: UUID, since start: Date) -> [Date] {
        records.filter { $0.medicineID == medicineID && !$0.isSkipped && $0.takenAt >= start }
            .map(\.takenAt)
            .sorted()
    }

    /// Ticking this dose now would be before its time (more than 30 minutes early): ask first.
    func isTooEarly(_ medicine: Medicine, at slot: TimeSlot, on day: Date, now: Date) -> Bool {
        DoseStatus.isTooEarly(time: medicine.doseTime(for: slot, meals: mealTimes), day: day, now: now)
    }

    /// One meal's dose of a medicine, on one day.
    func record(for medicine: Medicine, at slot: TimeSlot, on day: Date) -> DoseRecord? {
        record(for: medicine.id, at: medicine.doseTime(for: slot), on: day)
    }

    /// Logs one meal's dose of a medicine as taken or skipped. nil clears the log.
    func setLog(_ log: DoseLog?, for medicine: Medicine, at slot: TimeSlot, on day: Date) {
        setLog(log, for: medicine.id, at: medicine.doseTime(for: slot), slot: slot, on: day)
    }

    /// Logs a dose as taken or skipped. nil clears the log. `slot` is the meal (nil for "when needed" doses).
    /// The count of what's left follows along: taken takes a dose off, un-taking puts it back.
    func setLog(_ log: DoseLog?, for medicineID: UUID, at time: DoseTime, slot: TimeSlot? = nil, on day: Date) {
        let day = Calendar.current.startOfDay(for: day)
        let index = recordIndex(medicineID: medicineID, time: time, day: day)
        let wasTaken = index.map { !records[$0].isSkipped } ?? false
        let isTaken = log?.isTaken ?? false
        if wasTaken != isTaken { changeStock(of: medicineID, takingDose: isTaken) }
        if let index { records.remove(at: index) }
        switch log {
        case .taken(let date):
            records.append(DoseRecord(medicineID: medicineID, time: time, day: day, takenAt: date, slot: slot))
        case .skipped:
            records.append(DoseRecord(medicineID: medicineID, time: time, day: day, takenAt: Date(), skipped: true, slot: slot))
        case nil:
            break
        }
        save()
    }

    // MARK: How many are left

    /// Sets how many are left, e.g. after a refill. nil stops counting this medicine.
    func setStock(_ count: Double?, for medicineID: UUID) {
        guard let index = medicines.firstIndex(where: { $0.id == medicineID }) else { return }
        medicines[index].stock = count.map { max($0, 0) }
        medicines[index].stockFull = medicines[index].stock
        save()
    }

    /// "Running low" at this many left. nil goes back to Jenny's suggestion (about a week's worth).
    func setLowAt(_ level: Double?, for medicineID: UUID) {
        guard let index = medicines.firstIndex(where: { $0.id == medicineID }) else { return }
        medicines[index].lowAt = level.map { max($0, 0) }
        save()
    }

    /// One dose off (taken) or back on (un-taken). Not clamped at 0, so undoing always puts back what was taken.
    private func changeStock(of medicineID: UUID, takingDose: Bool) {
        guard let index = medicines.firstIndex(where: { $0.id == medicineID }),
              let stock = medicines[index].stock else { return }
        let dose = medicines[index].unitsPerDose
        medicines[index].stock = takingDose ? stock - dose : stock + dose
    }

    /// Ticks one meal's dose as taken today, or clears it.
    func toggleTaken(_ medicine: Medicine, at slot: TimeSlot, now: Date = Date()) {
        let logged = record(for: medicine, at: slot, on: now) != nil
        setLog(logged ? nil : .taken(at: now), for: medicine, at: slot, on: now)
    }

    /// A "when needed" medicine taken now. Each one is a new log.
    func logAsNeeded(_ medicine: Medicine, now: Date = Date()) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)
        let time = DoseTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
        guard record(for: medicine.id, at: time, on: now) == nil else { return }
        setLog(.taken(at: now), for: medicine.id, at: time, on: now)
    }

    // MARK: A day's schedule

    /// The medicines to take at each time on this day, in time order.
    /// A medicine only counts from the day it was added.
    func schedule(on day: Date) -> [DoseSlot] {
        let meals = mealTimes   // read through the store, so screens redraw when meal times change
        let active = activeMedicines(on: day)
        let times = Set(active.flatMap { $0.times(meals: meals) }).sorted()
        return times.map { time in
            DoseSlot(time: time, medicines: active.filter { $0.times(meals: meals).contains(time) }.sorted(by: Self.byName))
        }
    }

    /// The day by meal, for the Log: มื้อเช้า (ก่อนอาหาร 06:30 · หลังอาหาร 07:15), มื้อกลางวัน, มื้อเย็น, ก่อนนอน.
    /// Only the meals and parts that have medicines.
    func meals(on day: Date) -> [MealSchedule] {
        let meals = mealTimes   // read through the store, so screens redraw when meal times change
        let active = activeMedicines(on: day).filter { !$0.asNeeded }
        return TimeSlot.allCases.compactMap { slot -> MealSchedule? in
            let here = active.filter { $0.slots.contains(slot) }
            let parts = MealPart.allCases.compactMap { part -> MealPartSchedule? in
                let medicines = here.filter { $0.mealPart(at: slot) == part }.sorted(by: Self.byName)
                guard let first = medicines.first else { return nil }
                return MealPartSchedule(part: part, time: first.doseTime(for: slot, meals: meals), medicines: medicines)
            }
            return parts.isEmpty ? nil : MealSchedule(slot: slot, mealTime: meals.time(of: slot), parts: parts)
        }
    }

    /// Medicines that count on this day: only from the day they were added.
    private func activeMedicines(on day: Date) -> [Medicine] {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: day)
        return medicines.filter { calendar.startOfDay(for: $0.addedAt) <= day }
    }

    /// Everything logged on this day: by meal ("มื้อเช้า"), and "when needed" doses by the time they were taken.
    func logged(on day: Date) -> [LoggedTime] {
        let dayRecords = records.filter { Calendar.current.isDate($0.day, inSameDayAs: day) }
        let groups = Dictionary(grouping: dayRecords) { record in
            record.slot.map { "meal-\($0.rawValue)" } ?? "time-\(record.time.minutesFromMidnight)"
        }
        return groups.values.compactMap { group -> LoggedTime? in
            let doses = group.compactMap { record in
                medicine(id: record.medicineID).map { LoggedDose(medicine: $0, record: record) }
            }
            guard let first = group.first, let time = group.map(\.time).min(), !doses.isEmpty else { return nil }
            return LoggedTime(time: time, doses: doses.sorted { Self.byName($0.medicine, $1.medicine) }, slot: first.slot)
        }
        .sorted { $0.time == $1.time ? $0.id < $1.id : $0.time < $1.time }
    }

    /// How much of the day's schedule was taken, from 0 to 1. nil if nothing was due that day.
    func progress(on day: Date) -> Double? {
        let slots = schedule(on: day)
        let total = slots.reduce(0) { $0 + $1.medicines.count }
        guard total > 0 else { return nil }
        let taken = slots.reduce(0) { sum, slot in
            sum + slot.medicines.filter { medicine in
                record(for: medicine.id, at: slot.time, on: day).map { !$0.isSkipped } ?? false
            }.count
        }
        return Double(taken) / Double(total)
    }

    private func recordIndex(medicineID: UUID, time: DoseTime, day: Date) -> Int? {
        records.firstIndex { record in
            record.medicineID == medicineID && record.time == time
                && Calendar.current.isDate(record.day, inSameDayAs: day)
        }
    }

    private nonisolated static func byName(_ first: Medicine, _ second: Medicine) -> Bool {
        first.name.localizedStandardCompare(second.name) == .orderedAscending
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
        upgradeOldRecords()
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
