import SwiftUI
import UIKit

/// After the camera: Vision reads the label on this device, the Thai rules understand it,
/// and Jenny shows it big and reads it aloud. Then save it, edit it, or retake the photo.
struct ScanResultView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoReadAloud") private var autoReadAloud = true

    let image: UIImage
    /// Called when the user wants another photo. The home screen reopens the camera.
    let onRetake: () -> Void

    private enum Phase {
        case reading
        case found(LabelReading)
        case notFound(scannedText: String)
    }

    @State private var phase = Phase.reading
    @State private var editingMedicine: Medicine?
    @State private var savedFromEditor = false
    @State private var showingScannedText = false
    @State private var isGrouping = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                        .accessibilityLabel(language("รูปฉลากยาของคุณ", "Your photo of the label"))

                    switch phase {
                    case .reading:
                        ProgressView(language("กำลังอ่านฉลากยา…", "Reading the label…"))
                            .controlSize(.large)
                            .frame(maxWidth: .infinity, minHeight: 160)
                    case .found(let reading):
                        foundCard(reading)
                    case .notFound(let scannedText):
                        notFoundCard(scannedText)
                    }
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle(language("ผลการอ่านฉลาก", "Label result"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language("ยกเลิก", "Cancel")) { dismiss() }
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
            if let reading = LabelReader.read(lines, saved: store.medicines) {
                phase = .found(reading)
                if autoReadAloud { SpeechReader.shared.read(reading.medicine, in: language) }
                if reading.medicine.group == nil { await groupWithAI(reading) }
            } else {
                phase = .notFound(scannedText: lines.joined(separator: "\n"))
            }
        } catch {
            phase = .notFound(scannedText: "")
        }
    }

    /// Jenny doesn't know this medicine: ask Core AI (iOS 27) or Apple Intelligence which group it's in.
    private func groupWithAI(_ reading: LabelReading) async {
        isGrouping = true
        defer { isGrouping = false }
        guard let result = await MedicineGrouper.group(for: reading.medicine),
              case .found(var current) = phase else { return }
        current.medicine.group = result.group
        current.groupSource = result.source
        phase = .found(current)
    }

    // MARK: Found a medicine

    private func foundCard(_ reading: LabelReading) -> some View {
        let medicine = reading.medicine
        return VStack(alignment: .leading, spacing: 20) {
            // Side by side on iPad, stacked on a narrow iPhone.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { badges(for: reading) }
                VStack(alignment: .leading, spacing: 8) { badges(for: reading) }
            }

            MedicineInfoView(medicine: medicine)
            DoseChips(medicine: medicine)
            groupLine(reading)

            if reading.nameSource == .guess {
                checkNote(language("ชื่อยาเป็นการเดา โปรดตรวจสอบ", "The name is a guess. Please check it."))
            }
            if reading.unitGuessed {
                checkNote(language("ไม่พบหน่วยยา จึงใช้ \"\(medicine.unit)\" ไว้ก่อน โปรดตรวจสอบ",
                                   "No unit on the label, so Jenny used \"\(Medicine.unitName(medicine.unit, .english))\". Please check it."))
            }
            if reading.timesGuessed {
                checkNote(language("เดาเวลาจาก \"วันละ … ครั้ง\" โปรดตรวจสอบ",
                                   "The times are a guess from \"… times a day\". Please check them."))
            }

            VStack(spacing: 12) {
                Button {
                    SpeechReader.shared.read(medicine, in: language)
                } label: {
                    BigButtonLabel(title: language("อ่านออกเสียง", "Read aloud"), symbol: "speaker.wave.2.fill")
                }
                if medicine.name.isEmpty {
                    Button {
                        editingMedicine = medicine
                    } label: {
                        BigButtonLabel(title: language("ใส่ชื่อยาแล้วบันทึก", "Add the name, then save"), symbol: "pencil", filled: true)
                    }
                } else {
                    Button {
                        save(medicine)
                    } label: {
                        BigButtonLabel(title: language("บันทึกยา", "Save medicine"), symbol: "square.and.arrow.down.fill", filled: true)
                    }
                }
                HStack(spacing: 12) {
                    Button {
                        editingMedicine = medicine
                    } label: {
                        BigButtonLabel(title: language("แก้ไข", "Edit"), symbol: "pencil")
                    }
                    Button {
                        retake()
                    } label: {
                        BigButtonLabel(title: language("ถ่ายใหม่", "Retake"), symbol: "camera.fill")
                    }
                }
            }
            .buttonStyle(.plain)

            scannedTextBox(medicine.scannedText)

            Label(language("ตรวจกับฉลากจริงทุกครั้ง ไม่ใช่คำแนะนำทางการแพทย์",
                           "Always check the real label. Not medical advice."),
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
            Label(language("ไม่พบข้อมูลยาในรูปนี้", "Jenny couldn't find a medicine label"), systemImage: "exclamationmark.triangle.fill")
                .font(.title3.bold())
                .foregroundStyle(.orange)
            Text(language("ลองถ่ายใหม่ในที่สว่าง ให้ฉลากเต็มรูป และเอียงเล็กน้อยไม่ให้แสงสะท้อน",
                          "Try again in good light. Fill the photo with the label, and tilt it a little to avoid glare."))
                .font(.body)

            Button {
                retake()
            } label: {
                BigButtonLabel(title: language("ถ่ายใหม่", "Retake"), symbol: "camera.fill", filled: true)
            }
            Button {
                var medicine = Medicine.blank
                medicine.scannedText = scannedText
                editingMedicine = medicine
            } label: {
                BigButtonLabel(title: language("พิมพ์เอง", "Type it in"), symbol: "keyboard")
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

    /// "Group: Heart & blood pressure" and who grouped it (the name list, how it's used, or the AI).
    @ViewBuilder
    private func groupLine(_ reading: LabelReading) -> some View {
        if let group = reading.medicine.group {
            VStack(alignment: .leading, spacing: 2) {
                Label(language("กลุ่ม: \(group.thai)", "Group: \(group.english)"), systemImage: group.symbol)
                    .font(.headline)
                    .foregroundStyle(Theme.red)
                if let source = reading.groupSource {
                    Text(source.label(language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else if isGrouping {
            HStack(spacing: 8) {
                ProgressView()
                Text(language("กำลังจัดกลุ่มด้วย AI ในเครื่อง…", "Grouping with on-device AI…"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Label(language("กลุ่ม: อื่น ๆ (เปลี่ยนได้ที่ แก้ไข)", "Group: Other (change it with Edit)"), systemImage: MedicineGroup.other.symbol)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func badges(for reading: LabelReading) -> some View {
        badge(language("อ่านในเครื่องนี้", "Read on this device"), symbol: "lock.shield.fill")
        if reading.nameSource == .nameList {
            badge(language("พบในรายชื่อยา", "In the medicine list"), symbol: "checkmark.seal.fill")
        } else if reading.nameSource == .saved {
            badge(language("ชื่อที่เคยบันทึก", "Saved before"), symbol: "clock.arrow.circlepath")
        }
    }

    private func badge(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(Theme.red)
            .background(Theme.fill, in: Capsule())
    }

    private func checkNote(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)
    }

    private func scannedTextBox(_ text: String) -> some View {
        DisclosureGroup(language("ข้อความที่อ่านได้จากฉลาก", "Text read from the label"), isExpanded: $showingScannedText) {
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
        .environment(\.language, .english)
}
