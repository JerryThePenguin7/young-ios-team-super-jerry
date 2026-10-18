import SwiftUI
import PhotosUI
import UIKit

/// A photo waiting to be read on the result screen.
struct ScanPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// One group of medicines on the home screen, e.g. "หัวใจ หลอดเลือด และความดัน (2)".
struct MedicineSection: Identifiable {
    let group: MedicineGroup
    let medicines: [Medicine]
    var id: MedicineGroup { group }
}

/// Home. The camera is the main feature: take a photo of a medicine envelope, Jenny reads it, you save it.
/// Saved medicines are listed below, with their label photo, read aloud, and today's ticks.
struct ContentView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.openURL) private var openURL

    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var scanPhoto: ScanPhoto?
    @State private var retakeRequested = false
    @State private var showingCameraDenied = false
    @State private var remindersResult: AppleReminders.Result?
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
            .remindersAlert(result: $remindersResult)
        }
    }

    private func content(now: Date) -> some View {
        let due = store.doses(now: now).filter { $0.status == .dueNow || $0.status == .missed }

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                cameraCard

                if !due.isEmpty {
                    dueBanner(due, now: now)
                }

                if !store.remindersEnabled && store.medicines.contains(where: { !$0.times.isEmpty }) {
                    remindersButton
                }

                medicinesSection(now: now)

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

    /// The big red box: take a photo, or choose one from Photos. Both buttons live inside it.
    private var cameraCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 52, weight: .semibold))
            Text("ถ่ายรูปซองยา")
                .font(.largeTitle.bold())
            Text("Take a photo of your medicine envelope, or choose one from your photos.")
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .opacity(0.9)

            // Side by side on iPad, one above the other on a narrow iPhone.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { cameraButtons }
                VStack(spacing: 12) { cameraButtons }
            }
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.card.gradient, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    @ViewBuilder
    private var cameraButtons: some View {
        // No camera (e.g. the simulator)? Then "Choose from Photos" becomes the main button.
        if CameraPicker.isAvailable {
            Button {
                openCamera()
            } label: {
                boxButton(title: "ถ่ายรูป · Take photo", symbol: "camera.fill", main: true)
            }
            .buttonStyle(.plain)
        }
        PhotosPicker(selection: $photoItem, matching: .images) {
            boxButton(title: "เลือกรูปจากคลังภาพ · Choose from Photos", symbol: "photo.on.rectangle",
                      main: !CameraPicker.isAvailable)
        }
        .buttonStyle(.plain)
    }

    /// White button for the main action, white-outlined for the other one.
    private func boxButton(title: String, symbol: String, main: Bool) -> some View {
        Label(title, systemImage: symbol)
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 12)
            .foregroundStyle(main ? Theme.card : Color.white)
            .background(main ? Color.white : Color.white.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(main ? 0 : 0.85), lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    // MARK: Time to take

    private func dueBanner(_ due: [ScheduledDose], now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ถึงเวลาทานยา · Time to take", systemImage: "bell.fill")
                .font(.title2.bold())
                .foregroundStyle(Theme.red)

            ForEach(due) { dose in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dose.medicine.name)
                            .font(.title3.bold())
                        Text(dose.status == .missed
                             ? "\(dose.medicine.amountLine) · \(dose.time.label) · เลยเวลา (late)"
                             : "\(dose.medicine.amountLine) · \(dose.time.label)")
                            .foregroundStyle(dose.status == .missed ? Color.orange : Color.secondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        store.toggleTaken(dose.medicine, at: dose.time, now: now)
                    } label: {
                        Label("ทานแล้ว", systemImage: "checkmark")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .frame(minHeight: 50)
                            .foregroundStyle(.white)
                            .background(Theme.card, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark \(dose.medicine.name) as taken")
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.red, lineWidth: 2)
        }
    }

    private var remindersButton: some View {
        Button {
            store.remindersEnabled = true
            Task { remindersResult = await store.applyReminderSetting() }
        } label: {
            BigButtonLabel(title: "เพิ่มในแอปเตือนความจำ · Add to Apple Reminders", symbol: "checklist")
        }
        .buttonStyle(.plain)
    }

    // MARK: My medicines

    private func medicinesSection(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(store.medicines.isEmpty ? "ยาของฉัน · My medicines" : "ยาของฉัน · My medicines (\(store.medicines.count))")
                .font(.title2.bold())

            if store.medicines.isEmpty {
                ContentUnavailableView(
                    "ยังไม่มียา · No medicines yet",
                    systemImage: "pills",
                    description: Text("Tap \"ถ่ายรูป\" in the red box and take a photo of a medicine envelope.")
                )
            } else {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Label("\(section.group.thai) · \(section.group.english) (\(section.medicines.count))",
                              systemImage: section.group.symbol)
                            .font(.title3.bold())
                            .foregroundStyle(Theme.red)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
                            ForEach(section.medicines) { medicine in
                                MedicineCard(medicine: medicine, now: now)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Medicines grouped by what they're for, in a fixed order. Not grouped yet → "อื่น ๆ · Other".
    private var sections: [MedicineSection] {
        MedicineGroup.allCases.compactMap { group -> MedicineSection? in
            let medicines = store.medicines.filter { ($0.group ?? .other) == group }
            return medicines.isEmpty ? nil : MedicineSection(group: group, medicines: medicines)
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
