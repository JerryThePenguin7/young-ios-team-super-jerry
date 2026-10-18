import SwiftUI
import UIKit

/// One medicine in "Your Medications" (like the Health app): the label photo on the left, then the name,
/// kind and strength, and when to take it. Tap it for details; the speaker reads it aloud.
struct MedicineCard: View {
    @Environment(\.language) private var language
    let medicine: Medicine
    /// A fixed height, for the stack (all its cards are the same size). nil = as tall as the content.
    var height: CGFloat? = nil
    /// Edit mode on the home screen: show a delete button instead.
    var isEditing = false
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            NavigationLink(value: medicine.id) {
                HStack(spacing: 0) {
                    photo
                    info
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isEditing)

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
                VStack(spacing: 8) {
                    Button {
                        SpeechReader.shared.read(medicine, in: language)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.red)
                            .frame(width: 48, height: 48)
                            .background(Theme.fill, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(language("อ่านออกเสียง", "Read aloud"))

                    NavigationLink(value: medicine.id) {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                            .frame(width: 48, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHidden(true)
                }
                .padding(.trailing, 12)
            }
        }
        .frame(height: height, alignment: .top)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
        .frame(width: 120, height: height ?? 150)
        .clipped()
        .accessibilityHidden(true)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medicine.displayName(language))
                .font(.title3.bold())
                .lineLimit(height == nil ? nil : 2)   // in the stack every card is the same height
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
        .padding(16)
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
