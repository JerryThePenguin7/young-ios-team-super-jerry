import SwiftUI
import UIKit

/// Fix what the camera read, or type a medicine in by hand.
struct MedicineEditorView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss

    private let isNew: Bool
    /// The label photo to keep with a new medicine.
    private let photo: UIImage?
    private let onSaved: () -> Void

    @State private var medicine: Medicine
    @State private var warningsText: String
    @State private var duplicateCheck: DuplicateCheck?

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
                Section(language("ยา", "Medicine")) {
                    TextField(language("ชื่อยา เช่น Metformin", "Name, e.g. Metformin"), text: $medicine.name)
                        .font(.title3)
                    TextField(language("ขนาดยา เช่น 500 mg", "Strength, e.g. 500 mg"), text: $medicine.strength)
                }

                Section {
                    TextField(language("พิมพ์ให้ตรงกับฉลากทุกคำ", "Type it exactly as printed on the label"),
                              text: directionsBinding, axis: .vertical)
                        .font(.title3)
                        .lineLimit(2...8)
                } header: {
                    Text(language("วิธีใช้ตามฉลาก (ทุกคำ)", "Directions, word for word from the label"))
                } footer: {
                    Text(language("Jenny แสดงและอ่านออกเสียงตามนี้ทุกคำ ไม่ย่อ แก้ให้ตรงกับฉลากถ้าอ่านผิด",
                                  "Jenny shows and reads these exact words, never shortened. Fix them if the camera misread the label."))
                }

                Section(language("ครั้งละ (ใช้นับยาและเตือน)", "Each time (for counting and reminders)")) {
                    Picker(language("วิธีใช้", "How it's used"), selection: routeBinding) {
                        ForEach(routeOptions, id: \.self) { route in
                            Text(Medicine.routeName(route, language)).tag(route)
                        }
                    }
                    Stepper(value: $medicine.amount, in: 0.5...20, step: 0.5) {
                        Text(medicine.amountLine(language))
                            .font(.title3.bold())
                            .foregroundStyle(Theme.accent)
                    }
                    .disabled(medicine.unit.isEmpty)
                    Toggle(language("จำนวนนี้ต่อข้าง (ข้างละ)", "This amount is for each side (each eye, ear or nostril)"),
                           isOn: Binding(get: { medicine.perSide == true }, set: { medicine.perSide = $0 ? true : nil }))
                    Picker(language("หน่วย", "Unit"), selection: $medicine.unit) {
                        ForEach(unitOptions, id: \.self) { unit in
                            Text(unit.isEmpty ? language("ไม่นับจำนวน (ยาทา)", "No count (cream)")
                                              : Medicine.unitName(unit, language, plural: true)).tag(unit)
                        }
                    }
                }

                Section {
                    Toggle(language("ใช้เมื่อมีอาการเท่านั้น", "Only when needed"), isOn: $medicine.asNeeded)
                    if medicine.asNeeded {
                        // "ห่างกันอย่างน้อย 6 ชม.": Jenny shows when the next dose is allowed.
                        Picker(language("ทานห่างกันอย่างน้อย", "At least this long apart"), selection: $medicine.hoursApart) {
                            Text(language("ไม่ระบุ", "Not set")).tag(Double?.none)
                            ForEach(hourOptions, id: \.self) { hours in
                                Text(language("\(String(format: "%g", hours)) ชั่วโมง", "\(String(format: "%g", hours)) hours"))
                                    .tag(Double?.some(hours))
                            }
                        }
                    } else {
                        ForEach(TimeSlot.allCases, id: \.self) { slot in
                            Toggle(isOn: slotBinding(slot)) {
                                Label("\(slot.mealName(language)) (\(slot.mealTime.label(language)))", systemImage: slot.symbol)
                            }
                        }
                    }
                } header: {
                    Text(language("เวลาทานยา", "When"))
                } footer: {
                    Text(language("Jenny เตือนตามเวลาเหล่านี้ ยาที่ใช้เมื่อมีอาการจะไม่มีการเตือน",
                                  "Jenny reminds you at these times. \"Only when needed\" medicines have no reminders."))
                }

                Section(language("กลุ่มยา", "Group")) {
                    Picker(language("ยานี้ใช้สำหรับ", "What it's for"), selection: groupBinding) {
                        ForEach(MedicineGroup.allCases, id: \.self) { group in
                            Label(group.name(language), systemImage: group.symbol).tag(group)
                        }
                    }
                }

                Section(language("อาหาร", "Meals")) {
                    Picker(language("ก่อนหรือหลังอาหาร", "Before or after meals"), selection: $medicine.meal) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Text(Medicine.mealName(meal, language)).tag(meal)
                        }
                    }
                }

                Section {
                    Toggle(language("มีวันหมดอายุ", "Has an expiry date"), isOn: hasExpiryBinding)
                    if let expiresOn = medicine.expiresOn {
                        DatePicker(language("หมดอายุ", "Expires"), selection: expiryBinding(default: expiresOn),
                                   displayedComponents: .date)
                    }
                } header: {
                    Text(language("วันหมดอายุ", "Expiry date"))
                } footer: {
                    Text(language("ดูจากฉลาก เช่น EXP หรือ หมดอายุ", "As printed on the label, e.g. after EXP."))
                }

                Section {
                    TextField(language("คำเตือน บรรทัดละหนึ่งข้อ", "Warnings, one per line"), text: $warningsText, axis: .vertical)
                        .lineLimit(2...6)
                } header: {
                    Text(language("คำเตือน", "Warnings"))
                } footer: {
                    Text(language("พิมพ์ตามที่เขียนบนฉลาก", "Type them as printed on the label."))
                }
            }
            .tint(Theme.accent)
            .duplicateMedicineAlert(check: $duplicateCheck) { _ in
                save(evenIfSaved: true)
            }
            .navigationTitle(isNew ? language("เพิ่มยา", "New medicine") : language("แก้ไขยา", "Edit medicine"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language("ยกเลิก", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language("บันทึก", "Save")) { save() }
                        .disabled(medicine.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    /// Common gaps between "when needed" doses, plus the label's own number if it's a different one.
    private var hourOptions: [Double] {
        var options: [Double] = [4, 6, 8, 12, 24]
        if let hours = medicine.hoursApart, !options.contains(hours) { options.append(hours) }
        return options.sorted()
    }

    /// The usual units, plus whatever the label said if it's something else.
    private var unitOptions: [String] {
        Medicine.units.contains(medicine.unit) ? Medicine.units : [medicine.unit] + Medicine.units
    }

    private var routeOptions: [String] {
        let route = medicine.route ?? ""
        return Medicine.routes.contains(route) ? Medicine.routes : Medicine.routes + [route]
    }

    /// Choosing how it's used also picks the usual unit: หยอดตา → หยด, สูด → พัฟ, ทา → no count.
    private var routeBinding: Binding<String> {
        Binding(
            get: { medicine.route ?? "" },
            set: { route in
                medicine.route = route.isEmpty ? nil : route
                if route.contains("หยอด") || route.contains("หยด") {
                    medicine.unit = "หยด"
                } else if route == "สูด" {
                    medicine.unit = "พัฟ"
                } else if route.hasPrefix("พ่นจมูก") {
                    medicine.unit = "ครั้ง"
                } else if route.hasPrefix("ทา") {
                    medicine.unit = ""
                } else if route == "ฉีด" {
                    medicine.unit = "ยูนิต"
                } else if medicine.unit.isEmpty || medicine.unit == "หยด" || medicine.unit == "พัฟ" {
                    medicine.unit = "เม็ด"
                }
            }
        )
    }

    private var groupBinding: Binding<MedicineGroup> {
        Binding(get: { medicine.group ?? .other }, set: { medicine.group = $0 })
    }

    private var mealOptions: [String] {
        Medicine.meals.contains(medicine.meal) ? Medicine.meals : Medicine.meals + [medicine.meal]
    }

    private var directionsBinding: Binding<String> {
        Binding(get: { medicine.labelDirections ?? "" }, set: { medicine.labelDirections = $0 })
    }

    private var hasExpiryBinding: Binding<Bool> {
        Binding(
            get: { medicine.expiresOn != nil },
            set: { medicine.expiresOn = $0 ? Calendar.current.date(byAdding: .year, value: 1, to: Date()) : nil }
        )
    }

    private func expiryBinding(default date: Date) -> Binding<Date> {
        Binding(get: { medicine.expiresOn ?? date }, set: { medicine.expiresOn = $0 })
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

    /// Asks first if a new medicine is already saved (Add anyway / Cancel).
    private func save(evenIfSaved: Bool = false) {
        var result = medicine
        result.name = medicine.name.trimmingCharacters(in: .whitespaces)
        result.strength = medicine.strength.trimmingCharacters(in: .whitespaces)
        result.slots = result.orderedSlots
        if let amountMax = result.amountMax, amountMax <= result.amount { result.amountMax = nil }
        result.warnings = warningsText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let directions = (result.labelDirections ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        result.labelDirections = directions.isEmpty ? nil : directions

        if isNew && !evenIfSaved, let saved = store.duplicate(of: result) {
            duplicateCheck = DuplicateCheck(saved: saved, new: result)
            return
        }
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
        .environment(\.language, .english)
}
