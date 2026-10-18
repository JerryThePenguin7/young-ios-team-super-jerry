import SwiftUI

/// One saved medicine on the home screen: its label photo, what and how many, today's ticks, and read aloud.
struct MedicineCard: View {
    let medicine: Medicine
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavigationLink(value: medicine.id) {
                HStack(alignment: .top, spacing: 14) {
                    MedicinePhoto(file: medicine.photoFile)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicine.name.isEmpty ? "ยา (ไม่ทราบชื่อ)" : medicine.name)
                            .font(.title2.bold())
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .foregroundStyle(.secondary)
                        }
                        Text(medicine.amountLine)
                            .font(.title3.bold())
                            .foregroundStyle(Theme.red)
                        if !medicine.meal.isEmpty {
                            Text(medicine.meal)
                                .font(.headline)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            DoseChips(medicine: medicine, now: now)

            Button {
                SpeechReader.shared.speak(medicine.spokenThai)
            } label: {
                BigButtonLabel(title: "อ่านออกเสียง · Read aloud", symbol: "speaker.wave.2.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.red.opacity(0.15))
        }
    }

    /// "500 mg · ยาเบาหวาน"
    private var subtitle: String {
        [medicine.strength, medicine.friendlyName ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

#Preview {
    let store = MedicineStore.preview()
    NavigationStack {
        ScrollView {
            MedicineCard(medicine: store.medicines[1], now: Date())
                .padding()
        }
        .background(Theme.background)
    }
    .environment(store)
}
