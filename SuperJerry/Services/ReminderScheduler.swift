import Foundation
import UserNotifications

/// Jenny's "nagging": a local notification at every pill time, repeating daily.
/// Local notifications need no Info.plist key, and they work in the simulator too.
enum ReminderScheduler {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Replaces all reminders with one per medicine per time.
    static func schedule(_ medicines: [Medicine]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for medicine in medicines {
            for time in medicine.times {
                let content = UNMutableNotificationContent()
                content.title = "Time for \(medicine.name)"
                content.body = medicine.details.isEmpty
                    ? "Jenny here! Tap Taken in the app once you've had it."
                    : "\(medicine.details). Tap Taken in the app once you've had it."
                content.sound = .default

                var components = DateComponents()
                components.hour = time.hour
                components.minute = time.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(medicine.id.uuidString)-\(time.minutesFromMidnight)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// For the demo: a reminder 5 seconds from now. Returns false if notifications are off.
    static func sendTest(for medicine: Medicine?) async -> Bool {
        guard await requestPermission() else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Time for \(medicine?.name ?? "your medicine")"
        content.body = "Jenny here! This is a test reminder."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "jenny-test", content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            return false
        }
    }
}
