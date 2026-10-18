import Foundation
import UserNotifications

/// Reminders: one notification per pill time, every day, listing every medicine due then.
/// Local notifications need no Info.plist key.
enum ReminderScheduler {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Replaces all reminders, e.g. "ถึงเวลาทานยาเช้า: Metformin ครั้งละ 1 เม็ด, Amlodipine ครั้งละ 1 เม็ด".
    static func schedule(_ medicines: [Medicine]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        var medicinesByTime: [DoseTime: [Medicine]] = [:]
        for medicine in medicines {
            for time in medicine.times {
                medicinesByTime[time, default: []].append(medicine)
            }
        }

        for (time, due) in medicinesByTime {
            let content = UNMutableNotificationContent()
            content.title = "ถึงเวลาทานยา\(TimeSlot.at(time)?.thai ?? "") · Time for your medicine"
            content.body = due.map { "\($0.name) \($0.amountLine)" }.joined(separator: ", ")
            content.sound = .default

            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "jenny-\(time.minutesFromMidnight)",
                                                content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
