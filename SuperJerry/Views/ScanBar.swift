import SwiftUI
import PhotosUI

/// The camera, floating at the bottom of the home screen where a thumb can reach it (Liquid Glass, iOS 26).
/// A big red "scan" button and a round Photos button. The full red box (CameraCard) is shown instead
/// when there are no medicines yet, so first-time users see what Jenny does.
struct ScanBar: View {
    @Environment(\.language) private var language
    @Binding var photoItem: PhotosPickerItem?
    let takePhoto: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // No camera (e.g. the simulator)? Then the big button picks a photo instead.
            if CameraPicker.isAvailable {
                Button(action: takePhoto) {
                    mainLabel
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.card)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.red)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(language("เลือกจากคลังภาพ", "Choose from Photos"))
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    mainLabel
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.card)
            }
        }
        .controlSize(.large)
        .frame(maxWidth: 560)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }

    private var mainLabel: some View {
        Label(language("ถ่ายรูปซองยา", "Scan a medicine label"), systemImage: "camera.fill")
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .lineLimit(2)   // wraps onto a second line with big text instead of cutting words off
            .frame(maxWidth: .infinity, minHeight: 44)
    }
}

#Preview {
    ScrollView {
        ForEach(0..<12) { _ in
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.surface)
                .frame(height: 100)
                .padding(.horizontal)
        }
    }
    .background(Theme.background)
    .safeAreaInset(edge: .bottom) {
        ScanBar(photoItem: .constant(nil), takePhoto: {})
    }
    .environment(\.language, .thai)
}
