import SwiftUI

/// Language, text size, light or dark theme, meal times, Apple Reminders, read-aloud, the tutorial, erase everything,
/// and the disclaimer.
struct SettingsView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("autoReadAloud") private var autoReadAloud = true
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.deviceDefault
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.automatic
    @AppStorage(TextSize.storageKey) private var textSize = TextSize.system
    @AppStorage(TutorialView.seenKey) private var hasSeenTutorial = false

    @State private var remindersResult: AppleReminders.Result?
    @State private var showingEraseConfirmation = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Picker(language("ภาษา", "Language"), selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.name).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(language("ภาษา", "Language"))
                } footer: {
                    Text(language("Yao จะแสดงและอ่านออกเสียงเป็นภาษาไทยทั้งหมด",
                                  "Yao shows and reads everything in English."))
                }

                // Near the top, so it's easy to find: some people don't want Yao talking every time.
                Section {
                    Toggle(isOn: $autoReadAloud) {
                        Label(language("อ่านออกเสียงอัตโนมัติ", "Read aloud automatically"), systemImage: "speaker.wave.2.fill")
                    }
                } header: {
                    Text(language("เสียงอ่าน", "Voice"))
                } footer: {
                    Text(language("เปิดอยู่: ถ่ายรูปซองยาเสร็จ Yao จะอ่านฉลากออกเสียงทันที ปิดอยู่: Yao จะเงียบ แต่ยังแตะปุ่มลำโพงเพื่อฟังได้ทุกเมื่อ ใช้เสียงภาษาไทยที่มีในเครื่อง ถ้าฟังไม่ชัด เพิ่มเสียงได้ที่ การตั้งค่า ▸ การช่วยการเข้าถึง ▸ เนื้อหาที่พูด ▸ เสียง",
                                  "On: after each photo, Yao reads the label aloud straight away. Off: Yao stays quiet, and you can still tap a speaker button to listen any time. Uses the English voice built into this device (Settings ▸ Accessibility ▸ Spoken Content ▸ Voices)."))
                }

                Section {
                    // Each choice is shown at its own size, so it's easy to pick one you can read.
                    Picker(language("ขนาดตัวอักษร", "Text size"), selection: $textSize) {
                        ForEach(TextSize.allCases) { size in
                            Text(size.name(language))
                                .dynamicTypeSize(size.range)
                                .tag(size)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text(language("ขนาดตัวอักษร", "Text size"))
                } footer: {
                    Text(language("ตัวอักษรทั้งแอปเปลี่ยนทันที \"ตามเครื่อง\" ใช้ขนาดจาก การตั้งค่า ▸ จอภาพและความสว่าง ▸ ขนาดข้อความ",
                                  "All of YaoYao's text changes right away. \"Same as iPad\" uses Settings ▸ Display & Brightness ▸ Text Size."))
                }

                Section {
                    Picker(language("ธีม", "Theme"), selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Label(option.name(language), systemImage: option.symbol).tag(option)
                        }
                    }
                } header: {
                    Text(language("ธีมสว่างหรือมืด", "Light or dark"))
                } footer: {
                    Text(language("เปลี่ยนได้จากปุ่มมุมซ้ายบนของหน้าแรกด้วย", "You can also change it with the button at the top left of the home screen."))
                }

                Section {
                    MealTimesEditor()
                    // How early ก่อนอาหาร medicines come (and their reminder): 10 to 60 minutes before the meal.
                    Picker(selection: minutesBefore) {
                        ForEach(MealTimes.beforeChoices, id: \.self) { minutes in
                            Text(language("\(minutes) นาทีก่อนมื้อ", "\(minutes) min before")).tag(minutes)
                        }
                    } label: {
                        Label {
                            Text(language("ยาก่อนอาหาร", "Before-meal medicines"))
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundStyle(Theme.accent)
                        }
                        .font(.title3)
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text(language("เวลาอาหาร", "Meal times"))
                } footer: {
                    Text(language("เวลาทานยาจะตามมื้ออาหารของคุณ: ยาก่อนอาหาร \(store.mealTimes.minutesBefore) นาทีก่อนมื้อ ยาหลังอาหาร \(MealTimes.minutesAfter) นาทีหลังมื้อ การเตือนก็เปลี่ยนตามด้วย ฉลากส่วนใหญ่หมายถึง 15–30 นาทีก่อนอาหาร ถ้าไม่แน่ใจ ให้ถามเภสัชกร",
                                  "Your pill times follow your meals: before-meal medicines \(store.mealTimes.minutesBefore) minutes before, after-meal ones \(MealTimes.minutesAfter) minutes after. Reminders follow too. Most labels mean 15 to 30 minutes before eating; if unsure, ask your pharmacist."))
                }

                Section {
                    Toggle(language("เพิ่มในแอปเตือนความจำ", "Add to Apple Reminders"), isOn: $store.remindersEnabled)
                    Button(language("เปิดแอปเตือนความจำ", "Open Reminders"), systemImage: "checklist") {
                        if let url = AppleReminders.appURL { openURL(url) }
                    }
                } header: {
                    Text(language("การเตือน", "Reminders"))
                } footer: {
                    Text(language(
                        "Yao ใส่ยาแต่ละตัวไว้ในรายการ \"\(AppleReminders.listTitle)\" ของแอปเตือนความจำ เตือนทุกวันตามมื้ออาหาร (\(reminderTimes)) ติ๊กในแอปเตือนความจำเมื่อทานยาแล้ว ถ้าปิดตัวเลือกนี้ Yao จะลบการเตือนออก",
                        "Yao puts each medicine in a list called \"\(AppleReminders.listTitle)\" in the Reminders app, repeating every day with an alert around your meals (\(reminderTimes)). Tick it off in Reminders when you take it. Turning this off takes Yao's reminders out again."))
                }

                Section {
                    Button(language("ดูวิธีใช้อีกครั้ง", "Show the tutorial again"), systemImage: "questionmark.circle") {
                        // The home screen opens it once this sheet has closed.
                        hasSeenTutorial = false
                        dismiss()
                    }
                }

                Section {
                    Button(language("ลบข้อมูลทั้งหมด", "Erase all medicines"), systemImage: "trash", role: .destructive) {
                        showingEraseConfirmation = true
                    }
                } footer: {
                    Text(language("ยาและรูปฉลากของคุณเก็บไว้ในเครื่องนี้เท่านั้น",
                                  "Your medicines and label photos are saved on this device only."))
                }

                Section(language("เกี่ยวกับ", "About")) {
                    Text(language("YaoYao โดยทีม Super Jerry (YIDH26) ช่วยอ่านฉลากยาเพื่อให้คุณจำยาได้ ไม่ใช่คำแนะนำทางการแพทย์ ตรวจกับฉลากจริงทุกครั้ง และถามแพทย์หรือเภสัชกรเมื่อไม่แน่ใจ",
                                  "YaoYao by Team Super Jerry (YIDH26). Yao reads medicine labels to help you remember them. It is not medical advice: always check the real label, and ask your doctor or pharmacist if unsure."))
                        .font(.callout)
                }
            }
            .tint(Theme.accent)
            .navigationTitle(language("ตั้งค่า", "Settings"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language("เสร็จ", "Done")) { dismiss() }
                }
            }
            .onChange(of: store.remindersEnabled) {
                Task { await applyReminders() }
            }
            .remindersAlert(result: $remindersResult)
            .confirmationDialog(language("ลบยาและรูปทั้งหมด?", "Erase all medicines and photos?"),
                                isPresented: $showingEraseConfirmation, titleVisibility: .visible) {
                Button(language("ลบทั้งหมด", "Erase everything"), role: .destructive) {
                    store.eraseAll()
                }
            }
        }
    }

    /// Picking a choice saves it right away; the Log, the ticks and the reminders follow (`MedicineStore.setMealTimes`).
    private var minutesBefore: Binding<Int> {
        Binding(
            get: { store.mealTimes.minutesBefore },
            set: { minutes in
                var meals = store.mealTimes
                meals.minutesBefore = minutes
                store.setMealTimes(meals)
            }
        )
    }

    /// "มื้อเช้า 07:00 น. · มื้อกลางวัน 12:00 น. · …" or "Breakfast 7:00 AM · Lunch 12:00 PM · …"
    private var reminderTimes: String {
        TimeSlot.allCases.map { "\($0.mealName(language)) \(store.mealTimes.time(of: $0).label(language))" }
            .joined(separator: " · ")
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
        .environment(\.language, .english)
}
