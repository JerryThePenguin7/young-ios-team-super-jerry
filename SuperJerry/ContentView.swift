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

/// Which log sheet to open: one time's medicines, or the "when needed" ones.
struct LogRequest: Identifiable {
    let id = UUID()
    let kind: DoseLogSheet.Kind
    let day: Date
}

/// Home, laid out like the Health app's Medications page: the day and week at the top, then the camera
/// (Jenny's main feature: photo → read the label → read aloud → save), the day's log, and your medicines.
/// On iPad the log and your medicines sit side by side.
struct ContentView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var sizeClass
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
    /// "Your Medications" starts as a stack of cards; tap it to spread them out.
    @State private var isStacked = true
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
                WeekStrip(selectedDay: dayBinding(now: now), now: now)

                // First time: the full red box explains what Jenny does. After that, the camera
                // floats at the bottom (ScanBar) so the day's log comes first.
                if store.medicines.isEmpty {
                    CameraCard(photoItem: $photoItem, takePhoto: openCamera)
                }

                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 28) {
                        logColumn(day: day, now: now)
                        medicinesColumn
                    }
                } else {
                    logColumn(day: day, now: now)
                    medicinesColumn
                }

                Label(language("Jenny ช่วยอ่านและจำยาของคุณ ไม่ใช่คำแนะนำทางการแพทย์ ตรวจกับฉลากจริงทุกครั้ง และถามเภสัชกรเมื่อไม่แน่ใจ รูปถ่ายเก็บไว้ในเครื่องนี้เท่านั้น",
                               "Jenny helps you read and remember your medicines. It is not medical advice: always check the real label, and ask your pharmacist if unsure. Photos stay on this device."),
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            if !store.medicines.isEmpty {
                ScanBar(photoItem: $photoItem, takePhoto: openCamera)
            }
        }
        .sensoryFeedback(.success, trigger: store.records.count)
    }

    /// Tapping today stores nil, so "today" moves on by itself after midnight.
    private func dayBinding(now: Date) -> Binding<Date> {
        Binding(
            get: { selectedDay ?? Calendar.current.startOfDay(for: now) },
            set: { day in selectedDay = Calendar.current.isDate(day, inSameDayAs: now) ? nil : day }
        )
    }

    // MARK: The camera and the log

    private func logColumn(day: Date, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            logSection(day: day, now: now)
            if !store.remindersEnabled && store.medicines.contains(where: { !$0.times.isEmpty }) {
                remindersCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

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
            Text(language("บันทึกการทานยา", "Log"))
                .font(.title.bold())

            if store.medicines.isEmpty {
                Text(language("ถ่ายรูปซองยาในกล่องสีแดงเพื่อเพิ่มยาตัวแรก",
                              "Take a photo of a medicine envelope in the red box to add your first medicine."))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else if toLog.isEmpty && !slots.isEmpty && !isFuture {
                Label(language("บันทึกครบทุกเวลาแล้ว", "Everything is logged"), systemImage: "checkmark.seal.fill")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.green)
            }

            ForEach(toLog) { slot in
                LogTimeCard(time: slot.time, medicines: slot.medicines,
                            status: isToday ? status(of: slot, now: now) : .upcoming,
                            canLog: !isFuture) {
                    logRequest = LogRequest(kind: .time(slot.time), day: day)
                }
            }

            if isToday && hasAsNeeded {
                asNeededCard(day: day)
            }

            if !logged.isEmpty {
                LoggedCard(logged: logged, now: now) { time in
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

    private var medicinesColumn: some View {
        VStack(alignment: .leading, spacing: 28) {
            yourMedications
            if store.medicines.contains(where: \.canCountStock) {
                MedicineStorageSection { medicine in
                    stockMedicine = medicine
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var yourMedications: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(language("ยาของคุณ", "Your Medications"))
                    .font(.title.bold())
                Spacer()
                if !store.medicines.isEmpty && !isStacked {
                    Button(language("ซ้อน", "Stack"), systemImage: "square.stack.3d.down.right") {
                        withAnimation(reduceMotion ? nil : .snappy) {
                            isEditing = false
                            isStacked = true
                        }
                    }
                    .labelStyle(.titleOnly)
                    .font(.title3)
                    .tint(Theme.red)
                    Button(isEditing ? language("เสร็จ", "Done") : language("แก้ไข", "Edit")) {
                        withAnimation { isEditing.toggle() }
                    }
                    .font(.title3)
                    .tint(Theme.red)
                    .padding(.leading, 12)
                }
            }

            if store.medicines.isEmpty {
                ContentUnavailableView(
                    language("ยังไม่มียา", "No medicines yet"),
                    systemImage: "pills",
                    description: Text(language("แตะ \"ถ่ายรูป\" ในกล่องสีแดง แล้วถ่ายรูปซองยา",
                                               "Tap \"Take photo\" in the red box and take a photo of a medicine envelope."))
                )
            } else if isStacked {
                MedicineStack(medicines: store.medicines) {
                    withAnimation(reduceMotion ? nil : .snappy) { isStacked = false }
                }
                .transition(.opacity)
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
