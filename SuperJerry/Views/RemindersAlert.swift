import SwiftUI
import UIKit

/// Tells the user what happened after adding medicines to Apple Reminders, with a button to open
/// Reminders (or the Settings app, if they said no).
struct RemindersAlert: ViewModifier {
    @Binding var result: AppleReminders.Result?
    @Environment(\.language) private var language
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content.alert(title, isPresented: isPresented, presenting: result) { result in
            switch result {
            case .added:
                Button(language("เปิดแอปเตือนความจำ", "Open Reminders")) {
                    if let url = AppleReminders.appURL { openURL(url) }
                }
                Button(language("ตกลง", "OK"), role: .cancel) {}
            case .denied:
                Button(language("เปิดการตั้งค่า", "Open Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button(language("ยกเลิก", "Cancel"), role: .cancel) {}
            case .notConfigured, .failed:
                Button(language("ตกลง", "OK"), role: .cancel) {}
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
        case .added: language("เพิ่มในแอปเตือนความจำแล้ว", "Added to Reminders")
        case .denied: language("Jenny ใช้แอปเตือนความจำไม่ได้", "Reminders is off")
        case .notConfigured, .failed, nil: language("เพิ่มการเตือนไม่สำเร็จ", "Couldn't add reminders")
        }
    }

    private func message(for result: AppleReminders.Result) -> String {
        let list = AppleReminders.listTitle
        return switch result {
        case .added(let count) where count == 0:
            language("ยังไม่มียาที่ตั้งเวลาไว้ Jenny จะเพิ่มลงในรายการ \"\(list)\" เมื่อคุณบันทึกยา",
                     "No medicines with set times yet. Jenny will add them to the \"\(list)\" list when you save one.")
        case .added(let count):
            language("มีการเตือน \(count) รายการในรายการ \"\(list)\" เตือนทุกเวลาทานยา ติ๊กในแอปเตือนความจำเมื่อทานยาแล้ว",
                     "\(count) reminders are in the \"\(list)\" list, with an alert at each pill time. Tick them off in Reminders when you take your medicine.")
        case .denied:
            language("เปิดได้ที่ การตั้งค่า ▸ Jenny ▸ การเตือนความจำ ▸ การเข้าถึงทั้งหมด",
                     "Turn it on in Settings ▸ Jenny ▸ Reminders ▸ Full Access.")
        case .notConfigured:
            language("ไม่พบข้อความขออนุญาตใช้แอปเตือนความจำ ให้เพิ่ม NSRemindersFullAccessUsageDescription ที่ target ▸ Info",
                     "The Reminders permission text is missing. Add NSRemindersFullAccessUsageDescription in target ▸ Info.")
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
