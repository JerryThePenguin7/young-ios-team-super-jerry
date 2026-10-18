import SwiftUI

/// One saved medicine: the label photo, how and when to take it, today's ticks, read aloud, edit, and delete.
struct MedicineDetailView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
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
            .navigationTitle(medicine.displayName(language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(language("แก้ไข", "Edit")) {
                        editingMedicine = medicine
                    }
                }
            }
            .sheet(item: $editingMedicine) { medicine in
                MedicineEditorView(medicine: medicine, isNew: false)
            }
            .confirmationDialog(language("ลบยานี้?", "Delete this medicine?"), isPresented: $showingDeleteConfirmation,
                                titleVisibility: .visible) {
                Button(language("ลบ", "Delete"), role: .destructive) {
                    store.delete(medicine)
                    dismiss()
                }
            }
            .onDisappear { SpeechReader.shared.stop() }
        } else {
            ContentUnavailableView(language("ไม่พบยา", "Medicine not found"), systemImage: "pills")
        }
    }

    private func content(_ medicine: Medicine, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            header(medicine)

            card(title: language("วิธีใช้", "How to take")) {
                Text(medicine.amountLine(language))
                    .font(.title.bold())
                    .foregroundStyle(Theme.red)
                if !medicine.meal.isEmpty {
                    Label(Medicine.mealName(medicine.meal, language), systemImage: "fork.knife")
                        .font(.title3.weight(.semibold))
                }
                ForEach(medicine.warningLines(language), id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }

            card(title: language("วันนี้", "Today")) {
                Label(medicine.scheduleText(language), systemImage: "calendar")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                DoseChips(medicine: medicine, now: now)
            }

            Button {
                SpeechReader.shared.read(medicine, in: language)
            } label: {
                BigButtonLabel(title: language("อ่านออกเสียง", "Read aloud"), symbol: "speaker.wave.2.fill", filled: true)
            }
            .buttonStyle(.plain)

            if !medicine.scannedText.isEmpty {
                DisclosureGroup(language("ข้อความที่อ่านได้จากฉลาก", "Text read from the label"), isExpanded: $showingScannedText) {
                    Text(medicine.scannedText)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
                .padding(20)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .tint(Theme.red)
            }

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label(language("ลบยานี้", "Delete this medicine"), systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)

            Label(language("ตรวจกับฉลากจริงทุกครั้ง ไม่ใช่คำแนะนำทางการแพทย์",
                           "Always check the real label. Not medical advice."),
                  systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    /// The label photo (or a big icon), then the name, kind and strength, and the group.
    private func header(_ medicine: Medicine) -> some View {
        VStack(spacing: 16) {
            if let file = medicine.photoFile, let photo = PhotoStore.load(file) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .accessibilityLabel(language("รูปฉลากยา", "Photo of the label"))
            } else {
                PillIcon(medicine: medicine, size: 110)
            }
            VStack(spacing: 6) {
                Text(medicine.displayName(language))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(medicine.formLine(language))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if let purpose = medicine.purpose(language) {
                    Label(purpose, systemImage: (medicine.group ?? .other).symbol)
                        .font(.headline)
                        .foregroundStyle(Theme.red)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    let store = MedicineStore.preview()
    NavigationStack {
        MedicineDetailView(medicineID: store.medicines[1].id)
    }
    .environment(store)
    .environment(\.language, .english)
}
