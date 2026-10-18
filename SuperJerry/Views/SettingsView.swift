import SwiftUI

/// Apple Reminders, read-aloud, erase everything, and the disclaimer.
struct SettingsView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("autoReadAloud") private var autoReadAloud = true

    @State private var remindersResult: AppleReminders.Result?
    @State private var showingEraseConfirmation = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Toggle("เพิ่มในแอปเตือนความจำ · Add to Apple Reminders", isOn: $store.remindersEnabled)
                    Button("เปิดแอปเตือนความจำ · Open Reminders", systemImage: "checklist") {
                        if let url = AppleReminders.appURL { openURL(url) }
                    }
                } header: {
                    Text("การเตือน · Reminders")
                } footer: {
                    Text("Jenny puts each medicine in a list called \"\(AppleReminders.listTitle)\" in the Reminders app, repeating every day with an alert: \(reminderTimes). Tick it off in Reminders when you take it. Turning this off takes Jenny's reminders out again.")
                }

                Section {
                    Toggle("อ่านออกเสียงหลังถ่ายรูป · Read aloud after each photo", isOn: $autoReadAloud)
                } header: {
                    Text("เสียง · Voice")
                } footer: {
                    Text("Uses the Thai voice built into this device. If it sounds wrong, add the Thai voice in Settings ▸ Accessibility ▸ Spoken Content ▸ Voices.")
                }

                Section {
                    Button("ลบข้อมูลทั้งหมด · Erase all medicines", systemImage: "trash", role: .destructive) {
                        showingEraseConfirmation = true
                    }
                } footer: {
                    Text("Your medicines and label photos are saved on this device only.")
                }

                Section("เกี่ยวกับ · About") {
                    Text("Jenny by Team Super Jerry (YIDH26). Jenny reads medicine labels to help you remember them. It is not medical advice: always check the real label, and ask your doctor or pharmacist if unsure.")
                        .font(.callout)
                }
            }
            .tint(Theme.red)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: store.remindersEnabled) {
                Task { await applyReminders() }
            }
            .remindersAlert(result: $remindersResult)
            .confirmationDialog("ลบยาและรูปทั้งหมด? · Erase all medicines and photos?",
                                isPresented: $showingEraseConfirmation, titleVisibility: .visible) {
                Button("ลบทั้งหมด · Erase everything", role: .destructive) {
                    store.eraseAll()
                }
            }
        }
    }

    /// "เช้า 8:00 AM · กลางวัน 12:00 PM · …"
    private var reminderTimes: String {
        TimeSlot.allCases.map { "\($0.thai) \($0.time.label)" }.joined(separator: " · ")
    }

    private func applyReminders() async {
        if let result = await store.applyReminderSetting() {
            remindersResult = result
        }
    }
}

#Preview {
    SettingsView()
        .environment(MedicineStore.preview())
}
