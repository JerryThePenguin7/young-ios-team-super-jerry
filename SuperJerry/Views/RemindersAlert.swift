import SwiftUI
import UIKit

/// Tells the user what happened after adding medicines to Apple Reminders, with a button to open
/// Reminders (or the Settings app, if they said no).
struct RemindersAlert: ViewModifier {
    @Binding var result: AppleReminders.Result?
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content.alert(title, isPresented: isPresented, presenting: result) { result in
            switch result {
            case .added:
                Button("เปิดแอปเตือนความจำ · Open Reminders") {
                    if let url = AppleReminders.appURL { openURL(url) }
                }
                Button("OK", role: .cancel) {}
            case .denied:
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Cancel", role: .cancel) {}
            case .notConfigured, .failed:
                Button("OK", role: .cancel) {}
            }
        } message: { result in
            Text(message(for: result))
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { result != nil }, set: { if !$0 { result = nil } })
    }

    private var title: String {
        switch result {
        case .added: "เพิ่มในแอปเตือนความจำแล้ว · Added to Reminders"
        case .denied: "Jenny ใช้แอปเตือนความจำไม่ได้ · Reminders is off"
        case .notConfigured, .failed, nil: "เพิ่มไม่สำเร็จ · Couldn't add reminders"
        }
    }

    private func message(for result: AppleReminders.Result) -> String {
        switch result {
        case .added(let count) where count == 0:
            "No medicines with set times yet. Jenny will add them to the \"\(AppleReminders.listTitle)\" list when you save one."
        case .added(let count):
            "\(count) reminders are in the \"\(AppleReminders.listTitle)\" list, with an alert at each pill time. Tick them off in Reminders when you take your medicine."
        case .denied:
            "Turn it on in Settings ▸ Jenny ▸ Reminders ▸ Full Access."
        case .notConfigured:
            "The Reminders permission text is missing. Add NSRemindersFullAccessUsageDescription in target ▸ Info."
        case .failed(let reason):
            reason
        }
    }
}

extension View {
    func remindersAlert(result: Binding<AppleReminders.Result?>) -> some View {
        modifier(RemindersAlert(result: result))
    }
}
