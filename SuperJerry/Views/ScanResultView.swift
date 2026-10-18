import SwiftUI
import UIKit

/// After the camera: Vision reads the label on this device, the Thai rules understand it,
/// and Jenny shows it big and reads it aloud. Then save it, edit it, or retake the photo.
struct ScanResultView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoReadAloud") private var autoReadAloud = true

    let image: UIImage
    /// Called when the user wants another photo. The home screen reopens the camera.
    let onRetake: () -> Void

    private enum Phase {
        case reading
        case found(Medicine, timesGuessed: Bool)
        case notFound(scannedText: String)
    }

    @State private var phase = Phase.reading
    @State private var editingMedicine: Medicine?
    @State private var savedFromEditor = false
    @State private var showingScannedText = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                        .accessibilityLabel("Your photo of the label")

                    switch phase {
                    case .reading:
                        ProgressView("กำลังอ่านฉลากยา… · Reading the label…")
                            .controlSize(.large)
                            .frame(maxWidth: .infinity, minHeight: 160)
                    case .found(let medicine, let timesGuessed):
                        foundCard(medicine, timesGuessed: timesGuessed)
                    case .notFound(let scannedText):
                        notFoundCard(scannedText)
                    }
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("ผลการอ่าน · Result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await read() }
            .onDisappear { SpeechReader.shared.stop() }
            .sheet(item: $editingMedicine, onDismiss: {
                if savedFromEditor { dismiss() }
            }) { medicine in
                MedicineEditorView(medicine: medicine, isNew: true, photo: image) {
                    savedFromEditor = true
                }
            }
        }
    }

    // MARK: Reading

    private func read() async {
        guard case .reading = phase else { return }
        do {
            let lines = try await readText(from: image)
            let scannedText = lines.joined(separator: "\n")
            let info = LabelParser.parse(lines)
            if info.isEmpty {
                phase = .notFound(scannedText: scannedText)
            } else {
                let medicine = info.makeMedicine(scannedText: scannedText)
                phase = .found(medicine, timesGuessed: LabelParser.timesAreGuessed(in: lines))
                if autoReadAloud { SpeechReader.shared.speak(medicine.spokenThai) }
            }
        } catch {
            phase = .notFound(scannedText: "")
        }
    }

    // MARK: Found a medicine

    private func foundCard(_ medicine: Medicine, timesGuessed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("อ่านในเครื่อง · Read on this device", systemImage: "lock.shield.fill")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(Theme.red)
                .background(Theme.red.opacity(0.12), in: Capsule())

            MedicineInfoView(medicine: medicine)
            DoseChips(medicine: medicine)

            if timesGuessed {
                Label("เดาเวลาจาก \"วันละ … ครั้ง\" · โปรดตรวจสอบ (times guessed, please check)",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 12) {
                Button {
                    SpeechReader.shared.speak(medicine.spokenThai)
                } label: {
                    BigButtonLabel(title: "อ่านออกเสียง · Read aloud", symbol: "speaker.wave.2.fill")
                }
                if medicine.name.isEmpty {
                    Button {
                        editingMedicine = medicine
                    } label: {
                        BigButtonLabel(title: "ใส่ชื่อยาแล้วบันทึก · Add the name, then save", symbol: "pencil", filled: true)
                    }
                } else {
                    Button {
                        save(medicine)
                    } label: {
                        BigButtonLabel(title: "บันทึกยา · Save medicine", symbol: "square.and.arrow.down.fill", filled: true)
                    }
                }
                HStack(spacing: 12) {
                    Button {
                        editingMedicine = medicine
                    } label: {
                        BigButtonLabel(title: "แก้ไข · Edit", symbol: "pencil")
                    }
                    Button {
                        retake()
                    } label: {
                        BigButtonLabel(title: "ถ่ายใหม่ · Retake", symbol: "camera.fill")
                    }
                }
            }
            .buttonStyle(.plain)

            scannedTextBox(medicine.scannedText)

            Label("ตรวจกับฉลากจริงทุกครั้ง · ไม่ใช่คำแนะนำทางการแพทย์\nAlways check the real label. Not medical advice.",
                  systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: Nothing found

    private func notFoundCard(_ scannedText: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("ไม่พบข้อมูลยา · Jenny couldn't find a medicine label", systemImage: "exclamationmark.triangle.fill")
                .font(.title3.bold())
                .foregroundStyle(.orange)
            Text("ลองถ่ายใหม่ในที่สว่าง ให้ฉลากเต็มรูป และเอียงเล็กน้อยไม่ให้แสงสะท้อน\nTry again in good light. Fill the photo with the label, and tilt it a little to avoid glare.")
                .font(.body)

            Button {
                retake()
            } label: {
                BigButtonLabel(title: "ถ่ายใหม่ · Retake", symbol: "camera.fill", filled: true)
            }
            Button {
                var medicine = Medicine.blank
                medicine.scannedText = scannedText
                editingMedicine = medicine
            } label: {
                BigButtonLabel(title: "พิมพ์เอง · Type it in", symbol: "keyboard")
            }

            if !scannedText.isEmpty {
                scannedTextBox(scannedText)
            }
        }
        .buttonStyle(.plain)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func scannedTextBox(_ text: String) -> some View {
        DisclosureGroup("ดูข้อความที่อ่านได้ · Show scanned text", isExpanded: $showingScannedText) {
            Text(text)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        }
        .tint(Theme.red)
    }

    // MARK: Actions

    private func save(_ medicine: Medicine) {
        var saved = medicine
        saved.photoFile = PhotoStore.save(image)
        store.add(saved)
        dismiss()
    }

    private func retake() {
        onRetake()
        dismiss()
    }
}

#Preview {
    ScanResultView(image: UIImage(systemName: "doc.text.image") ?? UIImage(), onRetake: {})
        .environment(MedicineStore.preview(empty: true))
}
