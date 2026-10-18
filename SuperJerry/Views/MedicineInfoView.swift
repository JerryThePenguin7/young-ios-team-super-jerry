import SwiftUI

/// The big, easy-to-read facts about one medicine: what it is, how to use it (in the label's own words),
/// meals, warnings, and the expiry date.
struct MedicineInfoView: View {
    @Environment(\.language) private var language
    let medicine: Medicine

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name.isEmpty ? language("ไม่พบชื่อยา", "No name found") : medicine.name)
                    .font(.largeTitle.bold())
                Text(medicine.formLine(language))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let purpose = medicine.purpose(language) {
                    Text(purpose)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                ExpiryLabel(medicine: medicine)
                    .padding(.top, 4)
            }

            DirectionsView(medicine: medicine)

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MedicineInfoView(medicine: MedicineStore.preview().medicines[0])
        .padding()
        .environment(\.language, .english)
}
