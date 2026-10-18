import SwiftUI
import PhotosUI
import UIKit

/// A photo waiting to be read on the result screen.
struct ScanPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// One group of medicines in "Your Medications", e.g. "Diabetes".
struct MedicineSection: Identifiable {
    let group: MedicineGroup
    let medicines: [Medicine]
    var id: MedicineGroup { group }
}

/// The two halves of the home screen, switched with the two big buttons at the top.
enum HomeTab: Hashable {
    case log           // the day's checklist
    case medicines     // Your Medications (how many are left is on each medicine's screen)
}

/// Which log sheet to open: one meal's medicines, or the "when needed" ones.
struct LogRequest: Identifiable {
    let id = UUID()
    let kind: DoseLogSheet.Kind
    let day: Date
}

/// Home, laid out like the Health app's Medications page. Two big buttons at the top switch between
/// **Log** (the day and week, then a checklist for each pill time and what's been taken) and
/// **Your Medications** (every medicine, by group). The red scan button floats at the bottom:
/// Jenny's main feature, photo → read the label → read aloud → save.
struct ContentView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var scanPhoto: ScanPhoto?
    @State private var retakeRequested = false
    @State private var showingCameraDenied = false
    @State private var remindersResult: AppleReminders.Result?
    @State private var showingSettings = false
    @State private var showingNewMedicine = false
    /// The day shown in the log. nil means today (so it stays right after midnight).
    @State private var selectedDay: Date?
    @State private var logRequest: LogRequest?
    @State private var isEditing = false
    /// Groups in "Your Medications" that are folded closed.
    @State private var collapsedGroups: Set<MedicineGroup> = []
    @State private var tab = HomeTab.log
    /// The medicine screens open on top of home (tap a card, or a name in the "…" sheet).
    @State private var path: [UUID] = []
    /// A name tapped in the "…" sheet: opened in Your Medications once the sheet has closed.
    @State private var medicineToOpen: UUID?
    @State private var medicineToDelete: Medicine?
    @AppStorage(TutorialView.seenKey) private var hasSeenTutorial = false
    @State private var showingTutorial = false

    var body: some View {
        NavigationStack(path: $path) {
            // Redraws every minute so "Time to take" and "1 hr ago" stay up to date.
            TimelineView(.everyMinute) { context in
                content(now: context.date)
            }
            .background(Theme.background)
            .navigationTitle(language("ยาของฉัน", "Medications"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                MedicineDetailView(medicineID: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AppearanceMenu()
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(language("เพิ่มยาเอง", "Add by hand"), systemImage: "square.and.pencil") {
                        showingNewMedicine = true
                    }
                    Button(language("ตั้งค่า", "Settings"), systemImage: "gearshape") {
                        showingSettings = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera, onDismiss: {
                // Read the photo only after the camera has fully closed.
                if let cameraImage {
                    scanPhoto = ScanPhoto(image: cameraImage)
                    self.cameraImage = nil
                }
            }) {
                CameraPicker(image: $cameraImage)
                    .ignoresSafeArea()
            }
            .sheet(item: $scanPhoto, onDismiss: {
                if retakeRequested {
                    retakeRequested = false
                    openCamera()
                }
            }) { photo in
                ScanResultView(image: photo.image) {
                    retakeRequested = true
                }
            }
            .sheet(item: $logRequest, onDismiss: openTappedMedicine) { request in
                DoseLogSheet(kind: request.kind, day: request.day) { id in
                    medicineToOpen = id
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await loadPhoto(item) }
            }
            .sheet(isPresented: $showingSettings, onDismiss: showTutorialIfNeeded) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingTutorial) {
                TutorialView()
            }
            .onAppear(perform: showTutorialIfNeeded)
            .sheet(isPresented: $showingNewMedicine) {
                MedicineEditorView(medicine: .blank, isNew: true)
            }
            .alert(language("กล้องถูกปิดอยู่", "Camera is off"), isPresented: $showingCameraDenied) {
                Button(language("เปิดการตั้งค่า", "Open Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button(language("ยกเลิก", "Cancel"), role: .cancel) {}
            } message: {
                Text(language("Jenny ต้องใช้กล้องเพื่ออ่านฉลากยา เปิดได้ที่ การตั้งค่า ▸ Jenny ▸ กล้อง",
                              "Jenny needs the camera to read your medicine labels. Turn it on in Settings ▸ Jenny ▸ Camera."))
            }
            .confirmationDialog(language("ลบยานี้?", "Delete this medicine?"),
                                isPresented: deleteDialogShown, titleVisibility: .visible,
                                presenting: medicineToDelete) { medicine in
                Button(language("ลบ \(medicine.displayName(.thai))", "Delete \(medicine.displayName(.english))"),
                       role: .destructive) {
                    store.delete(medicine)
                    if store.medicines.isEmpty { isEditing = false }
                }
            }
            .remindersAlert(result: $remindersResult)
        }
    }

    private func content(now: Date) -> some View {
        let day = selectedDay ?? Calendar.current.startOfDay(for: now)

        return ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                switch tab {
                case .log:
                    WeekStrip(selectedDay: dayBinding(now: now), now: now)
                    logSection(day: day, now: now)
                    if !store.remindersEnabled && store.medicines.contains(where: { !$0.times.isEmpty }) {
                        remindersCard
                    }
                case .medicines:
                    yourMedications
                }

                Label(language("Jenny ช่วยอ่านและจำยาของคุณ ไม่ใช่คำแนะนำทางการแพทย์ ตรวจกับฉลากจริงทุกครั้ง และถามเภสัชกรเมื่อไม่แน่ใจ รูปถ่ายเก็บไว้ในเครื่องนี้เท่านั้น",
                               "Jenny helps you read and remember your medicines. It is not medical advice: always check the real label, and ask your pharmacist if unsure. Photos stay on this device."),
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        // The two big buttons stay at the top while the page scrolls.
        .safeAreaInset(edge: .top) {
            tabButtons
        }
        // The camera, from the very first launch.
        .safeAreaInset(edge: .bottom) {
            ScanBar(photoItem: $photoItem, takePhoto: openCamera)
        }
        .sensoryFeedback(.success, trigger: store.records.count)
    }

    /// "Log" and "Your Medications": two big buttons that switch the page, the chosen one filled red.
    private var tabButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { tabButtonList }
            VStack(spacing: 8) { tabButtonList }
        }
        .frame(maxWidth: 800)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
        // Pinned at the top: with the very biggest text they'd fill half the screen, so they stop growing here.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    @ViewBuilder
    private var tabButtonList: some View {
        tabButton(.log, title: language("บันทึกการทานยา", "Log"), symbol: "checklist")
        tabButton(.medicines, title: language("ยาของคุณ", "Your Medications"), symbol: "pills.fill")
    }

    private func tabButton(_ target: HomeTab, title: String, symbol: String) -> some View {
        let selected = tab == target
        return Button {
            withAnimation(.snappy) { tab = target }
        } label: {
            // The icon above the words, both centered, so "Your Medications" fits on one line.
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.title3)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 60)
                .foregroundStyle(selected ? Color.white : Theme.accent)
                .background(selected ? Theme.accentFill : Theme.fill,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Tapping today stores nil, so "today" moves on by itself after midnight.
    private func dayBinding(now: Date) -> Binding<Date> {
        Binding(
            get: { selectedDay ?? Calendar.current.startOfDay(for: now) },
            set: { day in selectedDay = Calendar.current.isDate(day, inSameDayAs: now) ? nil : day }
        )
    }

    // MARK: The camera and the log

    private func logSection(day: Date, now: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let isFuture = !isToday && day > now
        let meals = store.meals(on: day)
        // Each meal's medicines that haven't been logged yet.
        let toLog = meals.compactMap { meal -> MealSchedule? in
            let parts = meal.parts.compactMap { part -> MealPartSchedule? in
                let open = part.medicines.filter { store.record(for: $0.id, at: part.time, on: day) == nil }
                return open.isEmpty ? nil : MealPartSchedule(part: part.part, time: part.time, medicines: open)
            }
            return parts.isEmpty ? nil : MealSchedule(slot: meal.slot, mealTime: meal.mealTime, parts: parts)
        }
        let logged = store.logged(on: day)
        let asNeeded = store.medicines
            .filter(\.asNeeded)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        return VStack(alignment: .leading, spacing: 14) {
            if store.medicines.isEmpty {
                ContentUnavailableView {
                    Label(language("ยังไม่มียา", "No medicines yet"), systemImage: "camera.fill")
                } description: {
                    Text(language("แตะปุ่มสีเขียว \"ถ่ายรูปซองยา\" ด้านล่าง เพื่อเพิ่มยาตัวแรก",
                                  "Tap the green \"Scan a medicine label\" button at the bottom to add your first medicine."))
                }
            } else if toLog.isEmpty && !meals.isEmpty && !isFuture {
                Label(language("ติ๊กครบทุกตัวแล้ว", "All checked off"), systemImage: "checkmark.seal.fill")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.green)
            }

            // Medicines with no set time, like paracetamol, come first: they can be needed at any moment.
            if isToday && !asNeeded.isEmpty {
                AsNeededCard(medicines: asNeeded, now: now) { medicine in
                    withAnimation(.snappy) { store.logAsNeeded(medicine) }
                } more: {
                    logRequest = LogRequest(kind: .asNeeded, day: day)
                }
            }

            ForEach(toLog) { meal in
                MealCard(meal: meal, status: isToday ? status(of: meal, now: now) : .upcoming,
                         canLog: !isFuture) { medicine in
                    // Today: taken now. An earlier day: taken at the time it was due.
                    let takenAt = isToday ? now : medicine.doseTime(for: meal.slot).date(on: day)
                    withAnimation(.snappy) { store.setLog(.taken(at: takenAt), for: medicine, at: meal.slot, on: day) }
                } skip: { medicine in
                    withAnimation(.snappy) { store.setLog(.skipped, for: medicine, at: meal.slot, on: day) }
                } more: {
                    logRequest = LogRequest(kind: .meal(meal.slot), day: day)
                }
            }

            if !logged.isEmpty {
                LoggedCard(logged: logged, now: now) { dose in
                    withAnimation(.snappy) {
                        store.setLog(nil, for: dose.medicine.id, at: dose.record.time, slot: dose.record.slot, on: day)
                    }
                } open: { group in
                    // A meal opens its sheet; a "when needed" time opens the "when needed" sheet.
                    logRequest = LogRequest(kind: group.slot.map { DoseLogSheet.Kind.meal($0) } ?? .asNeeded, day: day)
                }
            }
        }
    }

    /// "Time to take" if any medicine in this meal is due now, "Late" if one was missed.
    private func status(of meal: MealSchedule, now: Date) -> DoseStatus {
        let statuses = meal.parts.flatMap { part in
            part.medicines.map { store.status(of: $0, at: part.time, now: now) }
        }
        if statuses.contains(.dueNow) { return .dueNow }
        if statuses.contains(.missed) { return .missed }
        return .upcoming
    }

    private var remindersCard: some View {
        Button {
            store.remindersEnabled = true
            Task { remindersResult = await store.applyReminderSetting() }
        } label: {
            // With very big text, the icon goes above the words so they aren't squeezed.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 16))
            layout {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 48, height: 48)
                    .background(Theme.fill, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(language("เตือนในแอปเตือนความจำ", "Remind me in Reminders"))
                        .font(.headline)
                    Text(language("Jenny จะใส่เวลาทานยาทุกเวลาไว้ในแอปเตือนความจำของ Apple",
                                  "Jenny adds each pill time to Apple's Reminders app."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.fill, in: Circle())
            }
            .padding(20)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Your medications

    private var yourMedications: some View {
        VStack(alignment: .leading, spacing: 16) {
            // The title and its buttons side by side, or one above the other with very big text.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    medicinesTitle
                    Spacer(minLength: 8)
                    medicinesButtons
                }
                VStack(alignment: .leading, spacing: 8) {
                    medicinesTitle
                    HStack { medicinesButtons }
                }
            }

            if store.medicines.isEmpty {
                ContentUnavailableView(
                    language("ยังไม่มียา", "No medicines yet"),
                    systemImage: "pills",
                    description: Text(language("แตะปุ่มสีเขียว \"ถ่ายรูปซองยา\" ด้านล่าง แล้วถ่ายรูปซองยา",
                                               "Tap the green \"Scan a medicine label\" button at the bottom and take a photo of a medicine envelope."))
                )
            } else {
                ForEach(sections) { section in
                    let isOpen = !collapsedGroups.contains(section.group)
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(section, isOpen: isOpen)
                        if isOpen {
                            ForEach(section.medicines) { medicine in
                                MedicineCard(medicine: medicine, isEditing: isEditing) {
                                    medicineToDelete = medicine
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var medicinesTitle: some View {
        Text(language("ยาของคุณ", "Your Medications"))
            .font(.title.bold())
    }

    /// "Edit", to delete medicines.
    @ViewBuilder
    private var medicinesButtons: some View {
        if !store.medicines.isEmpty {
            Button(isEditing ? language("เสร็จ", "Done") : language("แก้ไข", "Edit")) {
                withAnimation { isEditing.toggle() }
            }
            .font(.title3)
            .tint(Theme.accent)
        }
    }

    /// A group's header ("❤️ Heart & blood pressure  2  ⌄"). Tap it to fold the group open or closed.
    private func sectionHeader(_ section: MedicineSection, isOpen: Bool) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                if isOpen {
                    collapsedGroups.insert(section.group)
                } else {
                    collapsedGroups.remove(section.group)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Label(section.group.name(language), systemImage: section.group.symbol)
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Spacer(minLength: 8)
                Text("\(section.medicines.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isOpen ? 0 : -90))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(isOpen ? language("แสดงอยู่", "Expanded") : language("ซ่อนอยู่", "Collapsed"))
        .accessibilityHint(language("แตะเพื่อแสดงหรือซ่อนยากลุ่มนี้", "Tap to show or hide these medicines"))
    }

    /// Medicines grouped by what they're for, in a fixed order. Not grouped yet → "Other".
    private var sections: [MedicineSection] {
        MedicineGroup.allCases.compactMap { group -> MedicineSection? in
            let medicines = store.medicines.filter { ($0.group ?? .other) == group }
            return medicines.isEmpty ? nil : MedicineSection(group: group, medicines: medicines)
        }
    }

    /// A name was tapped in the "…" sheet: switch to Your Medications and open that medicine.
    private func openTappedMedicine() {
        guard let id = medicineToOpen else { return }
        medicineToOpen = nil
        tab = .medicines
        path = [id]
    }

    /// First launch, or "Show the tutorial again" in Settings. Not in Xcode Previews, so they show the home screen.
    private func showTutorialIfNeeded() {
        let inPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if !hasSeenTutorial && !inPreview { showingTutorial = true }
    }

    private var deleteDialogShown: Binding<Bool> {
        Binding(get: { medicineToDelete != nil }, set: { if !$0 { medicineToDelete = nil } })
    }

    // MARK: Photos

    private func openCamera() {
        Task {
            if await CameraPicker.requestAccess() {
                showingCamera = true
            } else {
                showingCameraDenied = true
            }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        scanPhoto = ScanPhoto(image: image)
    }
}

#Preview("English") {
    ContentView()
        .environment(MedicineStore.preview())
        .environment(\.language, .english)
}

#Preview("ภาษาไทย") {
    ContentView()
        .environment(MedicineStore.preview())
        .environment(\.language, .thai)
}

#Preview("Empty") {
    ContentView()
        .environment(MedicineStore.preview(empty: true))
}
