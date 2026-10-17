import SwiftUI
import PhotosUI
import UIKit

/// Photograph a Thai medicine envelope → Vision reads the text on the device → Thai rules understand it
/// → big card + Thai voice → add it to Jenny's medicines. Works with no internet.
struct ScanView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var cameraImage: UIImage?
    @State private var showingCamera = false
    @State private var isReading = false
    @State private var scan: EnvelopeScan?
    @State private var problem: String?
    @State private var editingMedicine: Medicine?
    @State private var savedFromEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isReading {
                        ProgressView("กำลังอ่านซองยา… · Reading the envelope…")
                            .controlSize(.large)
                            .frame(maxWidth: .infinity, minHeight: 240)
                    } else if let scan {
                        ScanResultCard(
                            scan: scan,
                            onAdd: { add(scan) },
                            onEdit: { editingMedicine = scan.info.makeMedicine() },
                            onScanAgain: { startOver() }
                        )
                    } else {
                        choosePhoto
                    }

                    if let problem {
                        Label(problem, systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("สแกนซองยา · Scan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker(image: $cameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await read(item) }
            }
            .onChange(of: cameraImage) { _, image in
                guard let image else { return }
                Task { await read(image) }
            }
            .sheet(item: $editingMedicine, onDismiss: {
                if savedFromEditor { dismiss() }
            }) { medicine in
                MedicineEditorView(medicine: medicine, isNew: true) {
                    savedFromEditor = true
                }
            }
        }
    }

    // MARK: Step 1: pick a photo

    private var choosePhoto: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Theme.red)
                .padding(.top, 24)
            Text("ถ่ายรูปซองยา ให้เห็นฉลากชัด ๆ\nTake a photo of the envelope's label")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            if CameraPicker.isAvailable {
                Button {
                    showingCamera = true
                } label: {
                    bigLabel("ถ่ายรูป · Take photo", symbol: "camera.fill", filled: true)
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                bigLabel("เลือกรูป · Choose photo", symbol: "photo.on.rectangle", filled: !CameraPicker.isAvailable)
            }

            Menu {
                ForEach(SampleLabels.all) { sample in
                    Button(sample.lines.first ?? "Sample \(sample.id)") {
                        show(sample.lines)
                    }
                }
            } label: {
                bigLabel("ลองซองยาตัวอย่าง · Try a sample", symbol: "doc.text.magnifyingglass", filled: false)
            }

            Text("Tip: good light, fill the photo with the sticker, and tilt it a little to avoid glare. The sample envelopes are made up.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
        .padding(24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func bigLabel(_ title: String, symbol: String, filled: Bool) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 60)
            .foregroundStyle(filled ? Color.white : Theme.red)
            .background(filled ? Theme.card : Theme.red.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Step 2: read it

    private func read(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            problem = "เปิดรูปนี้ไม่ได้ · Couldn't open that photo."
            return
        }
        await read(image)
    }

    private func read(_ image: UIImage) async {
        isReading = true
        problem = nil
        defer { isReading = false }
        do {
            let lines = try await readText(from: image)
            show(lines)
        } catch {
            problem = "อ่านรูปไม่ได้ ลองใหม่ในที่สว่าง · Couldn't read the photo. Try again in good light."
        }
    }

    private func show(_ lines: [String]) {
        let result = EnvelopeScan(lines: lines)
        if result.info.isEmpty {
            scan = nil
            problem = "ไม่พบข้อมูลยาในรูปนี้ ลองถ่ายใหม่ให้เห็นฉลากชัด ๆ · No medicine found. Try a clearer photo of the label."
        } else {
            scan = result
            problem = nil
        }
    }

    // MARK: Step 3: add it

    private func add(_ scan: EnvelopeScan) {
        store.add([scan.info.makeMedicine()])
        dismiss()
    }

    private func startOver() {
        scan = nil
        problem = nil
        photoItem = nil
        cameraImage = nil
    }
}

#Preview {
    ScanView()
        .environment(MedicineStore(inMemory: true))
}
