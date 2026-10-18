import SwiftUI
import UIKit

/// Set how many of a medicine are left (e.g. after picking up a refill at the pharmacy),
/// and at how many left Jenny should say "Running low".
struct StockEditorSheet: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss

    let medicine: Medicine
    @State private var count: Double
    @State private var lowAt: Double

    init(medicine: Medicine) {
        self.medicine = medicine
        _count = State(initialValue: max(medicine.stock ?? 0, 0))
        _lowAt = State(initialValue: medicine.lowStockLevel.rounded(.up))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        PillIcon(medicine: medicine, size: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(medicine.title(language))
                                .font(.title3.bold())
                            Text(medicine.formLine(language))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Stepper(value: $count, in: 0...9999, step: 1) {
                        Text(countText)
                            .font(.title.bold())
                            .foregroundStyle(Theme.red)
                    }
                    TextField(language("พิมพ์จำนวน", "Type a number"), value: $count, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                    quickButtons([10, 30, 100], title: { "+\(Int($0))" }) { count += $0 }
                } header: {
                    Text(language("ตอนนี้มียาเหลือเท่าไร", "How many do you have now?"))
                } footer: {
                    Text(language("ทุกครั้งที่บันทึกว่า ทานแล้ว Jenny จะลดจำนวนลงตามขนาดยา (\(medicine.doseText(.thai)))",
                                  "Each time you log Taken, Jenny takes off one dose (\(medicine.doseText(.english)))."))
                }

                Section {
                    Stepper(value: $lowAt, in: 0...999, step: 1) {
                        Text(lowText)
                            .font(.title3.bold())
                    }
                    quickButtons([5, 10, 20], title: { "\(Int($0))" }) { lowAt = $0 }
                } header: {
                    Text(language("เตือนเมื่อยาใกล้หมด", "Warn me when it's running low"))
                } footer: {
                    Text(language("Jenny จะขึ้นว่า \"ใกล้หมด\" เมื่อเหลือเท่านี้หรือน้อยกว่า ตั้งให้ยาแต่ละตัวต่างกันได้",
                                  "Jenny shows \"Running low\" when this many or fewer are left. Each medicine can have its own number."))
                }

                if medicine.stock != nil {
                    Section {
                        Button(language("หยุดนับยานี้", "Stop counting this medicine"), role: .destructive) {
                            store.setStock(nil, for: medicine.id)
                            dismiss()
                        }
                    }
                }
            }
            .tint(Theme.red)
            .navigationTitle(language("คลังยา", "Medicine Storage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language("ยกเลิก", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language("บันทึก", "Save")) { save() }
                }
            }
        }
    }

    private func save() {
        // Only what changed, so the bar doesn't restart at full when just the warning level changes.
        if medicine.stock == nil || count != max(medicine.stock ?? 0, 0) {
            store.setStock(count, for: medicine.id)
        }
        if medicine.lowAt != nil || lowAt != medicine.lowStockLevel.rounded(.up) {
            store.setLowAt(lowAt, for: medicine.id)
        }
        dismiss()
    }

    /// A row of quick buttons, e.g. +10 +30 +100. They stack up when the text is very big.
    private func quickButtons(_ values: [Double], title: @escaping (Double) -> String,
                              action: @escaping (Double) -> Void) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { quickButtonList(values, title: title, action: action) }
            VStack(spacing: 8) { quickButtonList(values, title: title, action: action) }
        }
    }

    private func quickButtonList(_ values: [Double], title: @escaping (Double) -> String,
                                 action: @escaping (Double) -> Void) -> some View {
        ForEach(values, id: \.self) { value in
            Button {
                action(value)
            } label: {
                Text(title(value))
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.bordered)
        }
    }

    /// "เมื่อเหลือ 10 เม็ด" or "At 10 tablets left"
    private var lowText: String {
        let number = String(format: "%g", lowAt)
        return language("เมื่อเหลือ \(number) \(medicine.unit)",
                        "At \(number) \(Medicine.unitName(medicine.unit, .english, plural: lowAt != 1)) left")
    }

    /// "30 เม็ด" or "30 tablets"
    private var countText: String {
        let number = String(format: "%g", count)
        return language("\(number) \(medicine.unit)",
                        "\(number) \(Medicine.unitName(medicine.unit, .english, plural: count != 1))")
    }
}

#Preview {
    let store = MedicineStore.preview()
    StockEditorSheet(medicine: store.medicines[0])
        .environment(store)
        .environment(\.language, .english)
}
