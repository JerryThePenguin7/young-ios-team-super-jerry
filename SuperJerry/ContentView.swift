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

    @ViewBuilder
    private var cameraCard: some View {
        if CameraPicker.isAvailable {
            VStack(spacing: 12) {
                Button {
                    openCamera()
                } label: {
                    cameraLabel(subtitle: "Take a photo of your medicine envelope")
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    BigButtonLabel(title: "เลือกรูปจากคลังภาพ · Choose from Photos", symbol: "photo.on.rectangle")
                }
                .buttonStyle(.plain)
            }
        } else {
            // No camera (e.g. the simulator): the big card picks a photo instead.
            PhotosPicker(selection: $photoItem, matching: .images) {
                cameraLabel(subtitle: "No camera here. Tap to choose a photo of the label.")
            }
            .buttonStyle(.plain)
        }
    }

    private func cameraLabel(subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56, weight: .semibold))
            Text("ถ่ายรูปซองยา")
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 240)
        .background(Theme.card.gradient, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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
            Task {
                if await !store.applyReminderSetting() {
                    showingNotificationsOff = true
                }
            }
        } label: {
            BigButtonLabel(title: "ให้ Jenny เตือนเวลาทานยา · Remind me at pill times", symbol: "bell.badge.fill")
        }
        .buttonStyle(.plain)
    }

    // MARK: My medicines

    private func medicinesSection(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.medicines.isEmpty ? "ยาของฉัน · My medicines" : "ยาของฉัน · My medicines (\(store.medicines.count))")
                .font(.title2.bold())

            if store.medicines.isEmpty {
                ContentUnavailableView(
                    "ยังไม่มียา · No medicines yet",
                    systemImage: "pills",
                    description: Text("Tap \"ถ่ายรูปซองยา\" above and take a photo of a medicine envelope.")
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
                    ForEach(store.medicines) { medicine in
                        MedicineCard(medicine: medicine, now: now)
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
