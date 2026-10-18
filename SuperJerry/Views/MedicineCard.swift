import SwiftUI
import UIKit

/// One medicine in "Your Medications" (like the Health app): the label photo on the left, then the name
/// with a read-aloud speaker next to it, the kind and strength, and when to take it. Tap it for details.
struct MedicineCard: View {
    @Environment(\.language) private var language
    let medicine: Medicine
    /// Edit mode on the home screen: show a delete button instead.
    var isEditing = false
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            link { photo }

            VStack(alignment: .leading, spacing: 4) {
                // The name with the read-aloud button right next to it.
                HStack(alignment: .center, spacing: 4) {
                    link {
                        Text(medicine.displayName(language))
                            .font(.title3.bold())
                            .multilineTextAlignment(.leading)
                    }
                    if !isEditing { readAloudButton }
                }
                link { details }
            }
            .padding(.vertical, 16)
            .padding(.leading, 16)

            if isEditing {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white, .red)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language("ลบยานี้", "Delete this medicine"))
            } else {
                // The arrow, in the middle on the right.
                link {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                        .frame(width: 44)
                        .frame(maxHeight: .infinity)
                }
                .accessibilityHidden(true)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    /// The speaker, with no circle around it. 44 pt so it's still easy to tap.
    private var readAloudButton: some View {
        Button {
            SpeechReader.shared.read(medicine, in: language)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title3)
                .foregroundStyle(Theme.red)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language("อ่านออกเสียง", "Read aloud"))
    }

    /// Opens the medicine. The card is split into a few links so the speaker button can sit between them.
    private func link<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationLink(value: medicine.id) {
            content()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isEditing)
    }

    /// The label photo, or a big pill icon on red if there's no photo.
    private var photo: some View {
        Group {
            if let file = medicine.photoFile, let image = PhotoStore.load(file) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: medicine.formSymbol)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.card.gradient)
            }
        }
        .frame(width: 120, height: 150)
        .clipped()
        .accessibilityHidden(true)
    }

    /// Everything under the name: kind and strength, when, meals, and warnings about expiry or running low.
    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medicine.formLine(language))
                .foregroundStyle(.secondary)
            Label(medicine.scheduleText(language), systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !medicine.meal.isEmpty {
                Label(Medicine.mealName(medicine.meal, language), systemImage: "fork.knife")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if medicine.isExpired() || medicine.expiresSoon() {
                ExpiryLabel(medicine: medicine)
            }
            if medicine.isLowStock {
                // Dark words with an orange icon: orange text is too hard to read.
                Label {
                    Text(language("ยาใกล้หมด", "Running low"))
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let store = MedicineStore.preview()
    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                MedicineCard(medicine: store.medicines[1])
                MedicineCard(medicine: store.medicines[2], isEditing: true)
            }
            .padding()
        }
        .background(Theme.background)
    }
    .environment(store)
    .environment(\.language, .english)
}
