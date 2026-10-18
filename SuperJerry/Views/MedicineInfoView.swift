import SwiftUI

/// The big, easy-to-read facts about one medicine: what it is, how many each time, meals, warnings.
struct MedicineInfoView: View {
    let medicine: Medicine
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize: CGFloat = 46

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name.isEmpty ? "ไม่พบชื่อยา · No name found" : medicine.name)
                    .font(.largeTitle.bold())
                if !medicine.strength.isEmpty {
                    Text(medicine.strength)
                        .font(.title2.weight(.semibold))
                }
                if let friendly = medicine.friendlyName {
                    Text(friendly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Text(medicine.amountLine)
                .font(.system(size: amountSize, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.red)

            if !medicine.meal.isEmpty {
                Label("\(medicine.meal) · \(medicine.mealEnglish)", systemImage: "fork.knife")
                    .font(.title3.weight(.semibold))
            }

            ForEach(medicine.warnings, id: \.self) { warning in
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
}
