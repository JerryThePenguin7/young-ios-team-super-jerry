import SwiftUI

/// The big, easy-to-read facts about one medicine: what it is, how many each time, meals, warnings.
struct MedicineInfoView: View {
    @Environment(\.language) private var language
    let medicine: Medicine
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize: CGFloat = 42

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
            }

            Text(medicine.amountLine(language))
                .font(.system(size: amountSize, weight: .heavy, design: .rounded))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MedicineInfoView(medicine: MedicineStore.preview().medicines[0])
        .padding()
        .environment(\.language, .english)
}
