import SwiftUI

/// A short welcome the first time Yao opens: pick a language, then one page each on scanning,
/// your meal times (pill times follow them), logging, and reminders with counting what's left.
/// Skip it any time, or replay it from Settings.
struct TutorialView: View {
    static let seenKey = "hasSeenTutorial"

    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.deviceDefault
    @AppStorage(TutorialView.seenKey) private var hasSeenTutorial = false

    @State private var page = 0
    private let pageCount = 5

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page < pageCount - 1 {
                    Button(language("ข้าม", "Skip")) { finish() }
                        .font(.title3)
                        .tint(Theme.accent)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal)
            .frame(minHeight: 60)

            TabView(selection: $page) {
                welcomePage.tag(0)
                scanPage.tag(1)
                mealsPage.tag(2)
                logPage.tag(3)
                remindersPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pageCount - 1 {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            } label: {
                BigButtonLabel(title: page < pageCount - 1 ? language("ถัดไป", "Next") : language("เริ่มใช้งาน", "Get started"),
                               symbol: page < pageCount - 1 ? "arrow.right" : "checkmark", filled: true)
            }
            .buttonStyle(.plain)
            .padding()
            .frame(maxWidth: 560)
        }
        .background(Theme.background)
    }

    private func finish() {
        hasSeenTutorial = true
        dismiss()
    }

    // MARK: Pages

    private var welcomePage: some View {
        TutorialPage(symbol: "pills.fill", color: Theme.accentFill,
                     title: language("ยินดีต้อนรับสู่ YaoYao", "Welcome to YaoYao"),
                     logo: "YaoYaoLogo",
                     text: language("Yao อ่านซองยาของคุณ อ่านออกเสียง และช่วยให้คุณทานยาได้ถูกต้อง เลือกภาษาที่ต้องการ",
                                    "Yao reads your medicine envelopes, reads them aloud, and helps you take them on time. Choose your language.")) {
            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        appLanguage = option
                    } label: {
                        HStack {
                            Text(option.name)
                                .font(.title3.bold())
                            Spacer()
                            if option == appLanguage {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundStyle(option == appLanguage ? Color.white : Theme.accent)
                        .background(option == appLanguage ? Theme.accentFill : Theme.surface,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option == appLanguage ? .isSelected : [])
                }
            }
        }
    }

    private var scanPage: some View {
        TutorialPage(symbol: "camera.fill", color: Theme.accentFill,
                     title: language("1. ถ่ายรูปซองยา", "1. Scan a medicine envelope"),
                     text: language("แตะปุ่มสีเขียว \"ถ่ายรูปซองยา\" ด้านล่าง แล้วเลือก ถ่ายรูป หรือ เลือกจากคลังภาพ ถ่ายฉลากให้เต็มรูปในที่สว่าง Yao จะอ่านฉลากในเครื่องนี้และอ่านออกเสียง ตรวจดูแล้วแตะ บันทึกยา",
                                    "Tap the green \"Scan a medicine label\" button at the bottom, then Take photo (or Choose from Photos). Take the photo in good light. Yao reads it on this device and reads it aloud. Check it, then tap Save medicine.")) {
            EmptyView()
        }
    }

    /// When do you eat? Yao's pill times follow the meals, so nobody has to eat at 8:00 sharp.
    private var mealsPage: some View {
        TutorialPage(symbol: "fork.knife", color: Theme.accentFill,
                     title: language("2. เวลาอาหารของคุณ", "2. When do you eat?"),
                     text: language("ตั้งเวลาที่คุณทานอาหารแต่ละมื้อและเวลาเข้านอน Yao จะจัดยาตามมื้อ ยาก่อนอาหารก่อน 30 นาที ยาหลังอาหารหลัง 15 นาที เปลี่ยนได้ทุกเมื่อในการตั้งค่า",
                                    "Set when you usually eat each meal and go to bed. Yao puts your medicines around your meals: before-meal ones 30 minutes before, after-meal ones 15 minutes after. Change it any time in Settings.")) {
            VStack(spacing: 8) {
                MealTimesEditor()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
    }

    private var logPage: some View {
        TutorialPage(symbol: "checkmark", color: Theme.greenFill,
                     title: language("3. บันทึกการทานยา", "3. Log your medicines"),
                     text: language("ในหน้า บันทึกการทานยา ยาจะอยู่ตามมื้อ: ก่อนอาหาร มื้ออาหาร และหลังอาหาร ติ๊กช่องหน้ายาแต่ละตัวเมื่อทานแล้ว ยาจะย้ายไปที่ ทานแล้ว แตะอีกครั้งเพื่อยกเลิก กดค้างเพื่อข้าม",
                                    "On the Log page, medicines sit around each meal: before eating, the meal, and after eating. Tick the box next to each medicine when you've taken it. It moves to Taken. Tap it again to undo; press and hold to skip.")) {
            // A picture of a checklist row before and after ticking, so people recognise it later.
            VStack(spacing: 10) {
                sampleRow(ticked: false)
                sampleRow(ticked: true)
            }
            .accessibilityHidden(true)
        }
    }

    private func sampleRow(ticked: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: ticked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 30))
                .foregroundStyle(Theme.green)
            Text("Metformin")
                .font(.title3)
            Spacer()
            if ticked {
                Text(language("ทานแล้ว", "Taken"))
                    .font(.headline)
                    .foregroundStyle(Theme.green)
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var remindersPage: some View {
        TutorialPage(symbol: "bell.fill", color: Theme.accentFill,
                     title: language("4. เตือนและนับยา", "4. Reminders and pill counts"),
                     text: language("Yao ใส่เวลาทานยาไว้ในแอปเตือนความจำได้ ในหน้าของยาแต่ละตัว ใส่จำนวนยาที่มี แล้ว Yao จะนับลดลงทุกครั้งที่ทานและเตือนเมื่อยาใกล้หมด",
                                    "Yao can add your pill times to the Reminders app. On each medicine's page, type how many you have: Yao counts down each time you take one and tells you when it's running low.")) {
            Label(language("Yao ไม่ใช่คำแนะนำทางการแพทย์ ตรวจกับฉลากจริงทุกครั้ง",
                           "Yao is not medical advice. Always check the real label."),
                  systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// One page of the tutorial: a big icon, a title, a few words, and something to show or choose.
private struct TutorialPage<Extra: View>: View {
    let symbol: String
    let color: Color
    let title: String
    /// The app's logo (an image in Assets) instead of the round icon: the welcome page.
    var logo: String? = nil
    let text: String
    @ViewBuilder let extra: () -> Extra

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let logo {
                    Image(logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 120)
                        .background(color.gradient, in: Circle())
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                extra()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 60)   // room for the page dots
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview("English") {
    TutorialView()
        .environment(MedicineStore.preview())
        .environment(\.language, .english)
}

#Preview("ภาษาไทย") {
    TutorialView()
        .environment(MedicineStore.preview())
        .environment(\.language, .thai)
}
