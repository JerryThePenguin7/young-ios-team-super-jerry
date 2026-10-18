import SwiftUI

/// One saved medicine: the label photo, the big facts, today's ticks, read aloud, edit, and delete.
struct MedicineDetailView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let medicineID: UUID

    @State private var editingMedicine: Medicine?
    @State private var showingDeleteConfirmation = false
    @State private var showingScannedText = false

    var body: some View {
        if let medicine = store.medicine(id: medicineID) {
            TimelineView(.everyMinute) { context in
                ScrollView {
                    content(medicine, now: context.date)
                }
            }
            .background(Theme.background)
            .navigationTitle(medicine.name.isEmpty ? "ยา · Medicine" : medicine.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit", systemImage: "pencil") {
                        editingMedicine = medicine
                    }
                }
            }
            .sheet(item: $editingMedicine) { medicine in
                MedicineEditorView(medicine: medicine, isNew: false)
            }
            .confirmationDialog("ลบยานี้? · Delete this medicine?", isPresented: $showingDeleteConfirmation,
                                titleVisibility: .visible) {
                Button("ลบ · Delete", role: .destructive) {
                    store.delete(medicine)
                    dismiss()
                }
            }
            .onDisappear { SpeechReader.shared.stop() }
        } else {
            ContentUnavailableView("ไม่พบยา · Medicine not found", systemImage: "pills")
        }
    }

    private func content(_ medicine: Medicine, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if let file = medicine.photoFile, let photo = PhotoStore.load(file) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    .accessibilityLabel("Photo of the label")
            }

            VStack(alignment: .leading, spacing: 20) {
                MedicineInfoView(medicine: medicine)
                DoseChips(medicine: medicine, now: now)

                Button {
                    SpeechReader.shared.speak(medicine.spokenThai)
                } label: {
                    BigButtonLabel(title: "อ่านออกเสียง · Read aloud", symbol: "speaker.wave.2.fill", filled: true)
                }
                .buttonStyle(.plain)

                if !medicine.scannedText.isEmpty {
                    DisclosureGroup("ดูข้อความที่อ่านได้ · Show scanned text", isExpanded: $showingScannedText) {
                        Text(medicine.scannedText)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                    .tint(Theme.red)
                }
            }
            .padding(24)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("ลบยานี้ · Delete this medicine", systemImage: "trash")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)

            Label("ตรวจกับฉลากจริงทุกครั้ง · ไม่ใช่คำแนะนำทางการแพทย์\nAlways check the real label. Not medical advice.",
                  systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let store = MedicineStore.preview()
    NavigationStack {
        MedicineDetailView(medicineID: store.medicines[1].id)
    }
    .environment(store)
}
