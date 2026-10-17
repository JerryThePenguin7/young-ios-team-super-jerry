import SwiftUI

/// Add or edit one medicine by hand.
struct MedicineEditorView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let original: Medicine
    private let isNew: Bool
    @State private var name: String
    @State private var dose: String
    @State private var note: String
    @State private var times: [EditableTime]

    /// A DatePicker needs a Date and a stable id, so times are edited in this shape.
    struct EditableTime: Identifiable {
        let id = UUID()
        var date: Date
    }

    init(medicine: Medicine, isNew: Bool) {
        original = medicine
        self.isNew = isNew
        _name = State(initialValue: medicine.name)
        _dose = State(initialValue: medicine.dose)
        _note = State(initialValue: medicine.note)
        _times = State(initialValue: medicine.times.sorted().map { EditableTime(date: $0.date(on: Date())) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medicine") {
                    TextField("Name, e.g. Paracetamol", text: $name)
                    TextField("Dose, e.g. 500 mg · 1 tablet", text: $dose)
                    TextField("Note, e.g. After meals", text: $note)
                }

                Section {
                    ForEach($times) { $time in
                        DatePicker("Time", selection: $time.date, displayedComponents: .hourAndMinute)
                    }
                    .onDelete { offsets in
                        for index in offsets.sorted(by: >) {
                            times.remove(at: index)
                        }
                    }
                    Button("Add a time", systemImage: "plus.circle.fill") {
                        times.append(EditableTime(date: DoseTime(hour: 12).date(on: Date())))
                    }
                } header: {
                    Text("When to take it")
                } footer: {
                    Text("Swipe left on a time to remove it.")
                }

                if !isNew {
                    Section {
                        Button("Delete medicine", systemImage: "trash", role: .destructive) {
                            store.delete(original)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New medicine" : "Edit medicine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !times.isEmpty
    }

    private func save() {
        let doseTimes = times.map { time in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: time.date)
            return DoseTime(hour: parts.hour ?? 8, minute: parts.minute ?? 0)
        }
        var medicine = original
        medicine.name = name.trimmingCharacters(in: .whitespaces)
        medicine.dose = dose.trimmingCharacters(in: .whitespaces)
        medicine.note = note.trimmingCharacters(in: .whitespaces)
        medicine.times = Set(doseTimes).sorted()

        if isNew {
            store.add([medicine])
        } else {
            store.update(medicine)
        }
        dismiss()
    }
}

#Preview("New") {
    MedicineEditorView(
        medicine: Medicine(name: "", dose: "", note: "", times: [DoseTime(hour: 8)]),
        isNew: true
    )
    .environment(MedicineStore(inMemory: true))
}

#Preview("Edit") {
    MedicineEditorView(
        medicine: Medicine(name: "Metformin", dose: "500 mg · 1 tablet", note: "After meals",
                           times: [DoseTime(hour: 8), DoseTime(hour: 18)]),
        isNew: false
    )
    .environment(MedicineStore(inMemory: true))
}
