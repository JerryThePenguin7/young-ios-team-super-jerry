import SwiftUI
import PhotosUI

/// The big red box, Jenny's main feature: take a photo of a medicine envelope, or choose one from Photos.
struct CameraCard: View {
    @Environment(\.language) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var photoItem: PhotosPickerItem?
    let takePhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // With very big text, the icon goes above the words so they aren't squeezed.
            let header = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 16))
            header {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.2), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(language("ถ่ายรูปซองยา", "Scan a medicine label"))
                        .font(.title2.bold())
                    Text(language("Jenny จะอ่านฉลาก อ่านออกเสียง และบันทึกยาให้คุณ",
                                  "Jenny reads the label, reads it aloud, and saves the medicine."))
                        .font(.subheadline.weight(.medium))
                        .opacity(0.9)
                        // Wrap instead of cutting the sentence off with "…".
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Always one above the other: side by side, the labels got cut off ("เลือกจากคลัง…") on iPad.
            VStack(spacing: 12) { buttons }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card.gradient, in: RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous))
    }

    @ViewBuilder
    private var buttons: some View {
        // No camera (e.g. the simulator)? Then "Choose from Photos" becomes the main button.
        if CameraPicker.isAvailable {
            Button(action: takePhoto) {
                boxButton(title: language("ถ่ายรูป", "Take photo"), symbol: "camera.fill", main: true)
            }
            .buttonStyle(.pressable)
        }
        PhotosPicker(selection: $photoItem, matching: .images) {
            boxButton(title: language("เลือกจากคลังภาพ", "Choose from Photos"), symbol: "photo.on.rectangle",
                      main: !CameraPicker.isAvailable)
        }
        .buttonStyle(.pressable)
    }

    /// White button for the main action, white-outlined for the other one.
    private func boxButton(title: String, symbol: String, main: Bool) -> some View {
        Label(title, systemImage: symbol)
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)   // wrap instead of "…"
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 12)
            .foregroundStyle(main ? Theme.card : Color.white)
            .background(main ? Color.white : Color.white.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .strokeBorder(Color.white.opacity(main ? 0 : 0.85), lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
    }
}

#Preview {
    CameraCard(photoItem: .constant(nil), takePhoto: {})
        .padding()
        .environment(\.language, .english)
}
