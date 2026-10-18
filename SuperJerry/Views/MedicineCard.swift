import SwiftUI

/// One saved medicine on the home screen: its label photo, what and how many, its times, and read aloud.
/// Doses are ticked in the Today card, so the times here only show when to take it.
struct MedicineCard: View {
    let medicine: Medicine
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: medicine.id) {
                // With very big text, the photo goes above the words so nothing gets squeezed.
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
                layout {
                    MedicinePhoto(file: medicine.photoFile, size: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicine.name.isEmpty ? "ยา (ไม่ทราบชื่อ)" : medicine.name)
                            .font(.title3.bold())
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .foregroundStyle(.secondary)
                        }
                        Text(medicine.amountLine)
                            .font(.title3.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(Theme.red)
                        if !medicine.meal.isEmpty {
                            Label(medicine.meal, systemImage: "fork.knife")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if !dynamicTypeSize.isAccessibilitySize {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)

            DoseChips(medicine: medicine)

            Button("อ่านออกเสียง · Read aloud", systemImage: "speaker.wave.2.fill") {
                SpeechReader.shared.speak(medicine.spokenThai)
            }
            .buttonStyle(.big)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
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
            MedicineCard(medicine: store.medicines[1])
                .padding()
        }
        .background(Theme.background)
    }
    .environment(store)
}
