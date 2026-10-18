import SwiftUI
import UIKit

/// Set how many of a medicine are left, e.g. after picking up a refill at the pharmacy.
struct StockEditorSheet: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss

    let medicine: Medicine
    @State private var count: Double

    init(medicine: Medicine) {
        self.medicine = medicine
        _count = State(initialValue: max(medicine.stock ?? 0, 0))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        PillIcon(medicine: medicine, size: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(medicine.displayName(language))
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
                    HStack(spacing: 12) {
                        ForEach([10.0, 30.0, 100.0], id: \.self) { amount in
                            Button("+\(Int(amount))") { count += amount }
                                .buttonStyle(.bordered)
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity)
                        }
                    }
                } header: {
                    Text(language("ตอนนี้มียาเหลือเท่าไร", "How many do you have now?"))
                } footer: {
                    Text(language("ทุกครั้งที่บันทึกว่า ทานแล้ว Jenny จะลดจำนวนลงตามขนาดยา (\(medicine.doseText(.thai)))",
                                  "Each time you log Taken, Jenny takes off one dose (\(medicine.doseText(.english)))."))
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
                    Button(language("บันทึก", "Save")) {
                        store.setStock(count, for: medicine.id)
                        dismiss()
                    }
                }
            }
        }
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
