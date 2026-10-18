import SwiftUI
import PhotosUI
import UIKit

/// A photo waiting to be read on the result screen.
struct ScanPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Home. The camera is the main feature: take a photo of a medicine envelope, Jenny reads it, you save it.
/// Saved medicines are listed below, with their label photo, read aloud, and today's ticks.
struct ContentView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var scanPhoto: ScanPhoto?
    @State private var retakeRequested = false
    @State private var showingCameraDenied = false
    @State private var showingNotificationsOff = false
    @State private var showingSettings = false
    @State private var showingNewMedicine = false

    var body: some View {
        NavigationStack {
            // Redraws every minute so "time to take" and the chips stay up to date.
            TimelineView(.everyMinute) { context in
                content(now: context.date)
            }
            .background(Theme.background)
            .navigationTitle("Jenny")
            .navigationDestination(for: UUID.self) { id in
                MedicineDetailView(medicineID: id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Settings", systemImage: "gearshape") {
                        showingSettings = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add by hand", systemImage: "square.and.pencil") {
                        showingNewMedicine = true
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
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await loadPhoto(item) }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNewMedicine) {
                MedicineEditorView(medicine: .blank, isNew: true)
            }
            .alert("กล้องถูกปิดอยู่ · Camera is off", isPresented: $showingCameraDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Jenny needs the camera to read your medicine labels. Turn it on in Settings ▸ Jenny ▸ Camera.")
            }
            .alert("Notifications are off", isPresented: $showingNotificationsOff) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Turn on notifications for Jenny in the Settings app so it can remind you.")
            }
        }
    }

    /// Health-style order: Time to take (only when due) → camera → Today → My medicines → disclaimer.
    private func content(now: Date) -> some View {
        let doses = store.doses(now: now)
        let due = doses.filter { $0.status == .dueNow || $0.status == .missed }

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                if !due.isEmpty {
                    DueNowCard(doses: due, now: now)
                }

                cameraCard

                if !doses.isEmpty {
                    TodayScheduleCard(doses: doses, now: now)
                }

                if !store.remindersEnabled && store.medicines.contains(where: { !$0.times.isEmpty }) {
                    remindersCard
                }

                medicinesSection

                Label("Jenny helps you read and remember your medicines. It is not medical advice: always check the real label, and ask your pharmacist if unsure. Photos stay on this device.",
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.success, trigger: store.records.count)
    }

    // MARK: The camera (main feature)

    @ViewBuilder
    private var cameraCard: some View {
        if CameraPicker.isAvailable {
            VStack(spacing: 12) {
                Button {
                    openCamera()
                } label: {
                    cameraLabel(subtitle: "Take a photo of your medicine envelope. Jenny reads it out loud.")
                }
                .buttonStyle(.pressable)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("เลือกรูปจากคลังภาพ · Choose from Photos", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.big)
            }
        } else {
            // No camera (e.g. the simulator): the big card picks a photo instead.
            PhotosPicker(selection: $photoItem, matching: .images) {
                cameraLabel(subtitle: "No camera here. Tap to choose a photo of the label.")
            }
            .buttonStyle(.pressable)
        }
    }

    private func cameraLabel(subtitle: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.heroCornerRadius)
        // On iPhone, or with very big text, stack the icon above the words so nothing gets squeezed.
        let stacked = sizeClass == .compact || dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 20))

        return layout {
            Image(systemName: "camera.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Theme.card)
                .frame(width: 72, height: 72)
                .background(.white, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("ถ่ายรูปซองยา")
                    .font(.largeTitle.bold())
                Text(subtitle)
                    .font(.title3.weight(.medium))
                    .opacity(0.9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !stacked {
                Image(systemName: "chevron.right")
                    .font(.title2.bold())
                    .opacity(0.8)
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Theme.card.gradient, in: shape)
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }

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

    // MARK: Reminders

    private var remindersCard: some View {
        SummaryCard(title: "การเตือน · Reminders", symbol: "bell.badge.fill") {
            Text("ให้ Jenny เตือนเมื่อถึงเวลาทานยา\nJenny can remind you at each pill time.")
                .font(.body)
            Button("เปิดการเตือน · Turn on reminders", systemImage: "bell.fill") {
                store.remindersEnabled = true
                Task {
                    if await !store.applyReminderSetting() {
                        showingNotificationsOff = true
                    }
                }
            }
            .buttonStyle(.big)
        }
    }

    // MARK: My medicines

    private var medicinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("ยาของฉัน · My medicines")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !store.medicines.isEmpty {
                    Text("\(store.medicines.count)")
                        .font(.title3.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
            }

            if store.medicines.isEmpty {
                ContentUnavailableView(
                    "ยังไม่มียา · No medicines yet",
                    systemImage: "pills",
                    description: Text("Tap \"ถ่ายรูปซองยา\" above and take a photo of a medicine envelope.")
                )
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
                    ForEach(store.medicines) { medicine in
                        MedicineCard(medicine: medicine)
                    }
                }
            }
        }
    }
}

#Preview("With medicines") {
    ContentView()
        .environment(MedicineStore.preview())
}

#Preview("Empty") {
    ContentView()
        .environment(MedicineStore.preview(empty: true))
}
