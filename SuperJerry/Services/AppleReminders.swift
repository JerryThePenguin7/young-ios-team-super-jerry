import Foundation
import EventKit
import CoreGraphics
import UserNotifications

/// Puts Jenny's medicines into Apple's Reminders app: one repeating reminder per medicine per pill time,
/// with an alert, in a list called "ยา Jenny" (or "Jenny Medicines" in English). The user ticks it off in Reminders when they've taken it,
/// and it also shows on their Apple Watch and other Apple devices. Jenny sends no notifications itself.
enum AppleReminders {
    enum Result {
        case added(Int)       // how many reminders are now in the list
        case denied           // the user said no: fix it in the Settings app
        case notConfigured    // the Info.plist permission text is missing
        case failed(String)
    }

    /// The list's name, in the app's language. The other names are ones Jenny used before.
    static var listTitle: String { AppLanguage.current("ยา Jenny", "Jenny Medicines") }
    private static let jennyListTitles: Set = ["ยา Jenny", "Jenny Medicines", "ยา · Jenny"]
    /// Opens the Reminders app.
    static let appURL = URL(string: "x-apple-reminderkit://")

    private static let store = EKEventStore()
    private static let listIDKey = "jennyRemindersListID"
    private static let itemIDsKey = "jennyReminderItemIDs"

    /// Without NSRemindersFullAccessUsageDescription (target ▸ Info), asking for access crashes the app.
    static var isConfigured: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSRemindersFullAccessUsageDescription") != nil
    }

    static var hasAccess: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    }

    static func requestAccess() async -> Bool {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess: return true
        case .notDetermined: return (try? await store.requestFullAccessToReminders()) ?? false
        default: return false
        }
    }

    /// Replaces Jenny's reminders with one per medicine per time. "When needed" medicines get none.
    static func sync(_ medicines: [Medicine]) async -> Result {
        guard isConfigured else { return .notConfigured }
        guard await requestAccess() else { return .denied }
        do {
            removeJennyReminders()
            let list = try jennyList()
            var created: [EKReminder] = []
            for medicine in medicines {
                for slot in medicine.orderedSlots where !medicine.asNeeded {
                    let reminder = makeReminder(for: medicine, at: slot, in: list)
                    try store.save(reminder, commit: false)
                    created.append(reminder)
                }
            }
            try store.commit()
            UserDefaults.standard.set(created.map(\.calendarItemIdentifier), forKey: itemIDsKey)
            return .added(created.count)
        } catch {
            store.reset()
            return .failed(error.localizedDescription)
        }
    }

    /// Takes Jenny's reminders out of the Reminders app (when the user turns reminders off).
    static func removeAll() {
        guard isConfigured, hasAccess else { return }
        removeJennyReminders()
        try? store.commit()
    }

    /// Older versions of Jenny sent their own notifications. Clear them, since Reminders does this now.
    static func removeOldJennyNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: Helpers

    private static func makeReminder(for medicine: Medicine, at slot: TimeSlot, in list: EKCalendar) -> EKReminder {
        let language = AppLanguage.current
        let reminder = EKReminder(eventStore: store)
        reminder.calendar = list
        // Thai: the label's own words. English: Jenny's summary, with the label's words in the notes.
        let instruction = medicine.instruction(language).replacingOccurrences(of: "\n", with: " ")
        reminder.title = "💊 \(medicine.displayName(language)) · \(instruction)"

        var notes = ["\(slot.name(language)) (\(slot.time.label(language)))"]
        if let directions = medicine.directions {
            notes.append(language("ฉลากเขียนว่า: ", "The label says: ") + directions)
        }
        if let expiry = medicine.expiryText(language) { notes.append(expiry) }
        if !medicine.meal.isEmpty { notes.append(Medicine.mealName(medicine.meal, language)) }
        if let purpose = medicine.purpose(language) { notes.append(purpose) }
        notes += medicine.warningLines(language)
        notes.append(language("เพิ่มโดยแอป Jenny ไม่ใช่คำแนะนำทางการแพทย์", "Added by the Jenny app. Not medical advice."))
        reminder.notes = notes.joined(separator: "\n")

        reminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: nextDate(at: slot.time))
        reminder.addAlarm(EKAlarm(relativeOffset: 0))
        reminder.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))
        return reminder
    }

    /// Today at this time, or tomorrow if it has already passed.
    private static func nextDate(at time: DoseTime) -> Date {
        let today = time.date(on: Date())
        return today > Date() ? today : Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    }

    /// Only removes reminders Jenny made, never the user's own.
    private static func removeJennyReminders() {
        for id in UserDefaults.standard.stringArray(forKey: itemIDsKey) ?? [] {
            if let reminder = store.calendarItem(withIdentifier: id) as? EKReminder {
                try? store.remove(reminder, commit: false)
            }
        }
        UserDefaults.standard.removeObject(forKey: itemIDsKey)
    }

    /// Jenny's list, made the first time. Falls back to the default list if a new one can't be made.
    private static func jennyList() throws -> EKCalendar {
        if let id = UserDefaults.standard.string(forKey: listIDKey), let list = store.calendar(withIdentifier: id) {
            // Switched language? Rename the list too (but never a name the user typed).
            if list.title != listTitle && jennyListTitles.contains(list.title) {
                list.title = listTitle
                try? store.saveCalendar(list, commit: false)
            }
            return list
        }
        if let existing = store.calendars(for: .reminder).first(where: { jennyListTitles.contains($0.title) }) {
            UserDefaults.standard.set(existing.calendarIdentifier, forKey: listIDKey)
            return existing
        }
        let fallback = store.defaultCalendarForNewReminders()
        guard let source = fallback?.source ?? store.sources.first(where: { $0.sourceType == .local }) else {
            if let fallback { return fallback }
            throw NSError(domain: "Jenny", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No Reminders account on this device."])
        }
        let list = EKCalendar(for: .reminder, eventStore: store)
        list.title = listTitle
        list.cgColor = CGColor(red: 0.83, green: 0.18, blue: 0.18, alpha: 1)
        list.source = source
        do {
            try store.saveCalendar(list, commit: true)
            UserDefaults.standard.set(list.calendarIdentifier, forKey: listIDKey)
            return list
        } catch {
            if let fallback { return fallback }
            throw error
        }
    }
}
