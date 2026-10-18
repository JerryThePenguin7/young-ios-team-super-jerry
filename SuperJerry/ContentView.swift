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
    case medicines     // Your Medications and Medicine Storage
}

/// Which log sheet to open: one time's medicines, or the "when needed" ones.
struct LogRequest: Identifiable {
    let id = UUID()
    let kind: DoseLogSheet.Kind
    let day: Date
}

/// Home, laid out like the Health app's Medications page. Two big buttons at the top switch between
/// **Log** (the day and week, then a checklist for each pill time and what's been taken) and
/// **Your Medications** (the medicine stack and Medicine Storage). The red scan button floats at the bottom:
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
    /// "Your Medications" starts as a stack of cards; tap it to spread them out.
    @State private var isStacked = true
    /// The medicine in front of the stack.
    @State private var frontMedicine: UUID?
    @Namespace private var medicinesNamespace
    /// One card in the stack: grows with the text size so nothing is cut off.
    @ScaledMetric(relativeTo: .title3) private var medicineCardHeight: CGFloat = 170
    @State private var medicineToDelete: Medicine?
    /// The medicine whose count is being set in Medicine Storage.
    @State private var stockMedicine: Medicine?
    @AppStorage(TutorialView.seenKey) private var hasSeenTutorial = false
    @State private var showingTutorial = false

    var body: some View {
        NavigationStack {
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
            .sheet(item: $logRequest) { request in
                DoseLogSheet(kind: request.kind, day: request.day)
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await loadPhoto(item) }
            }
            .sheet(isPresented: $showingSettings, onDismiss: showTutorialIfNeeded) {
                SettingsView()
            }
            .sheet(item: $stockMedicine) { medicine in
                StockEditorSheet(medicine: medicine)
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
                    if store.medicines.contains(where: \.canCountStock) {
                        MedicineStorageSection { medicine in
                            stockMedicine = medicine
                        }
                    }
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
            Label(title, systemImage: symbol)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(selected ? Color.white : Theme.red)
                .background(selected ? Theme.card : Theme.fill,
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
        let slots = store.schedule(on: day)
        // Each time's medicines that haven't been logged yet.
        let toLog = slots.compactMap { slot -> DoseSlot? in
            let open = slot.medicines.filter { store.record(for: $0.id, at: slot.time, on: day) == nil }
            return open.isEmpty ? nil : DoseSlot(time: slot.time, medicines: open)
        }
        let logged = store.logged(on: day)
        let hasAsNeeded = store.medicines.contains { $0.asNeeded }

        return VStack(alignment: .leading, spacing: 14) {
            if store.medicines.isEmpty {
                ContentUnavailableView {
                    Label(language("ยังไม่มียา", "No medicines yet"), systemImage: "camera.fill")
                } description: {
                    Text(language("แตะปุ่มสีแดง \"ถ่ายรูปซองยา\" ด้านล่าง เพื่อเพิ่มยาตัวแรก",
                                  "Tap the red \"Scan a medicine label\" button at the bottom to add your first medicine."))
                }
            } else if toLog.isEmpty && !slots.isEmpty && !isFuture {
                Label(language("ติ๊กครบทุกตัวแล้ว", "All checked off"), systemImage: "checkmark.seal.fill")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.green)
            }

            ForEach(toLog) { slot in
                LogTimeCard(time: slot.time, medicines: slot.medicines,
                            status: isToday ? status(of: slot, now: now) : .upcoming,
                            canLog: !isFuture) { medicine in
                    // Today: taken now. An earlier day: taken at the time it was due.
                    let takenAt = isToday ? now : slot.time.date(on: day)
                    withAnimation(.snappy) { store.setLog(.taken(at: takenAt), for: medicine.id, at: slot.time, on: day) }
                } skip: { medicine in
                    withAnimation(.snappy) { store.setLog(.skipped, for: medicine.id, at: slot.time, on: day) }
                } more: {
                    logRequest = LogRequest(kind: .time(slot.time), day: day)
                }
            }

            if isToday && hasAsNeeded {
                asNeededCard(day: day)
            }

            if !logged.isEmpty {
                LoggedCard(logged: logged, now: now) { dose in
                    withAnimation(.snappy) { store.setLog(nil, for: dose.medicine.id, at: dose.record.time, on: day) }
                } open: { time in
                    logRequest = LogRequest(kind: .time(time), day: day)
                }
            }
        }
    }

    /// "Time to take" if any medicine at this time is due now, "Late" if one was missed.
    private func status(of slot: DoseSlot, now: Date) -> DoseStatus {
        let statuses = slot.medicines.map { store.status(of: $0, at: slot.time, now: now) }
        if statuses.contains(.dueNow) { return .dueNow }
        if statuses.contains(.missed) { return .missed }
        return .upcoming
    }

    private func asNeededCard(day: Date) -> some View {
        Button {
            logRequest = LogRequest(kind: .asNeeded, day: day)
        } label: {
            HStack {
                Text(language("ยาเมื่อมีอาการ", "As Needed Medications"))
                    .font(.title3)
                Spacer(minLength: 8)
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.red)
                    .frame(width: 44, height: 44)
                    .background(Theme.fill, in: Circle())
            }
            .padding(20)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
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
                    .foregroundStyle(Theme.red)
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
                    .foregroundStyle(Theme.red)
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
                    description: Text(language("แตะปุ่มสีแดง \"ถ่ายรูปซองยา\" ด้านล่าง แล้วถ่ายรูปซองยา",
                                               "Tap the red \"Scan a medicine label\" button at the bottom and take a photo of a medicine envelope."))
                )
            } else if isStacked && store.medicines.count > 1 {
                CardStack(items: store.medicines, cardHeight: medicineCardHeight, current: $frontMedicine,
                          namespace: medicinesNamespace,
                          title: language("ยาของคุณ \(store.medicines.count) ตัว", "Your \(store.medicines.count) medicines"),
                          itemName: { $0.displayName(language) }) { medicine in
                    MedicineCard(medicine: medicine, height: medicineCardHeight)
                } open: {
                    withAnimation(stackAnimation) { isStacked = false }
                }
                .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(sections) { section in
                        let isOpen = !collapsedGroups.contains(section.group)
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(section, isOpen: isOpen)
                            if isOpen {
                                ForEach(section.medicines) { medicine in
                                    MedicineCard(medicine: medicine, isEditing: isEditing) {
                                        medicineToDelete = medicine
                                    }
                                    .matchedGeometryEffect(id: medicine.id, in: medicinesNamespace)
                                }
                            }
                        }
                    }
                }
                // The cards drop down out of the stack.
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var medicinesTitle: some View {
        Text(language("ยาของคุณ", "Your Medications"))
            .font(.title.bold())
    }

    /// "Stack" and "Edit", once the stack is spread out.
    @ViewBuilder
    private var medicinesButtons: some View {
        if !store.medicines.isEmpty && (!isStacked || store.medicines.count == 1) {
            if store.medicines.count > 1 {
                Button(language("ซ้อน", "Stack")) {
                    withAnimation(stackAnimation) {
                        isEditing = false
                        isStacked = true
                    }
                }
                .font(.title3)
                .tint(Theme.red)
                .padding(.trailing, 12)
            }
            Button(isEditing ? language("เสร็จ", "Done") : language("แก้ไข", "Edit")) {
                withAnimation { isEditing.toggle() }
            }
            .font(.title3)
            .tint(Theme.red)
        }
    }

    /// A springy "drop down", like Apple's. A plain fade for people who turned on Reduce Motion.
    private var stackAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.25)
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
                    .foregroundStyle(Theme.red)
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
