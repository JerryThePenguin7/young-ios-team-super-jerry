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

    /// Health-style: the label photo, then cards for the medicine, today's times, and the scanned text.
    private func content(_ medicine: Medicine, now: Date) -> some View {
        VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            if let file = medicine.photoFile, let photo = PhotoStore.load(file) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .accessibilityLabel("Photo of the label")
            }

            SummaryCard(title: "ยา · Medicine", symbol: "pills.fill") {
                MedicineInfoView(medicine: medicine)
            }

            Button("อ่านออกเสียง · Read aloud", systemImage: "speaker.wave.2.fill") {
                SpeechReader.shared.speak(medicine.spokenThai)
            }
            .buttonStyle(.bigProminent)

            SummaryCard(title: "วันนี้ · Today", symbol: "calendar") {
                DoseChips(medicine: medicine, now: now)
                if !medicine.times.isEmpty {
                    Text("แตะเมื่อทานแล้ว · Tap a time when you've taken it")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !medicine.scannedText.isEmpty {
                SummaryCard(title: "ข้อความจากฉลาก · Label text", symbol: "text.viewfinder") {
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

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("ลบยานี้ · Delete this medicine", systemImage: "trash")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: Theme.buttonCornerRadius))

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
