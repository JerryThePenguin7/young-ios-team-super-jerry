import SwiftUI
import UIKit

/// Fix what the camera read, or type a medicine in by hand.
struct MedicineEditorView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let isNew: Bool
    /// The label photo to keep with a new medicine.
    private let photo: UIImage?
    private let onSaved: () -> Void

    @State private var medicine: Medicine
    @State private var warningsText: String

    init(medicine: Medicine, isNew: Bool, photo: UIImage? = nil, onSaved: @escaping () -> Void = {}) {
        self.isNew = isNew
        self.photo = photo
        self.onSaved = onSaved
        _medicine = State(initialValue: medicine)
        _warningsText = State(initialValue: medicine.warnings.joined(separator: "\n"))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ยา · Medicine") {
                    TextField("ชื่อยา · Name, e.g. Metformin", text: $medicine.name)
                        .font(.title3)
                    TextField("ขนาด · Strength, e.g. 500 mg", text: $medicine.strength)
                }

                Section("ครั้งละ · Each time") {
                    Stepper(value: $medicine.amount, in: 0.5...10, step: 0.5) {
                        Text(medicine.amountLine)
                            .font(.title3.bold())
                            .foregroundStyle(Theme.red)
                    }
                    Picker("หน่วย · Unit", selection: $medicine.unit) {
                        ForEach(unitOptions, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                }

                Section {
                    Toggle("เมื่อมีอาการ · Only when needed", isOn: $medicine.asNeeded)
                    if !medicine.asNeeded {
                        ForEach(TimeSlot.allCases, id: \.self) { slot in
                            Toggle(isOn: slotBinding(slot)) {
                                Label("\(slot.thai) · \(slot.english) (\(slot.time.label))", systemImage: slot.symbol)
                            }
                        }
                    }
                } header: {
                    Text("เวลาทานยา · When")
                } footer: {
                    Text("Jenny reminds you at these times. \"Only when needed\" medicines have no reminders.")
                }

                Section("อาหาร · Meals") {
                    Picker("ก่อน/หลังอาหาร · Meals", selection: $medicine.meal) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Text(meal.isEmpty ? "ไม่ระบุ · Not stated" : meal).tag(meal)
                        }
                    }
                }

                Section {
                    TextField("คำเตือน · Warnings, one per line", text: $warningsText, axis: .vertical)
                        .lineLimit(2...6)
                } header: {
                    Text("คำเตือน · Warnings")
                }
            }
            .tint(Theme.red)
            .navigationTitle(isNew ? "เพิ่มยา · New medicine" : "แก้ไข · Edit medicine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(medicine.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    /// The usual units, plus whatever the label said if it's something else.
    private var unitOptions: [String] {
        Medicine.units.contains(medicine.unit) ? Medicine.units : [medicine.unit] + Medicine.units
    }

    private var mealOptions: [String] {
        Medicine.meals.contains(medicine.meal) ? Medicine.meals : Medicine.meals + [medicine.meal]
    }

    private func slotBinding(_ slot: TimeSlot) -> Binding<Bool> {
        Binding(
            get: { medicine.slots.contains(slot) },
            set: { isOn in
                if isOn {
                    medicine.slots.append(slot)
                } else {
                    medicine.slots.removeAll { $0 == slot }
                }
            }
        )
    }

    private func save() {
        var result = medicine
        result.name = medicine.name.trimmingCharacters(in: .whitespaces)
        result.strength = medicine.strength.trimmingCharacters(in: .whitespaces)
        result.slots = result.orderedSlots
        result.warnings = warningsText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if isNew {
            if let photo { result.photoFile = PhotoStore.save(photo) }
            store.add(result)
        } else {
            store.update(result)
        }
        onSaved()
        dismiss()
    }
}

#Preview("From a scan") {
    MedicineEditorView(medicine: MedicineStore.preview().medicines[1], isNew: true)
        .environment(MedicineStore.preview(empty: true))
}

#Preview("By hand") {
    MedicineEditorView(medicine: .blank, isNew: true)
        .environment(MedicineStore.preview(empty: true))
}
