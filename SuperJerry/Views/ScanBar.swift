import SwiftUI
import PhotosUI

/// The camera: one big red "Scan a medicine label" button floating at the bottom of the home screen,
/// where a thumb can reach it (Liquid Glass, iOS 26). Tapping it asks how: take a photo, or choose one
/// from Photos. Shown from the very first launch.
struct ScanBar: View {
    @Environment(\.language) private var language
    @Binding var photoItem: PhotosPickerItem?
    let takePhoto: () -> Void

    @State private var showingChoice = false
    @State private var showingPhotos = false

    var body: some View {
        Button {
            // No camera (e.g. the simulator)? Then go straight to Photos.
            if CameraPicker.isAvailable {
                showingChoice = true
            } else {
                showingPhotos = true
            }
        } label: {
            Label(language("ถ่ายรูปซองยา", "Scan a medicine label"), systemImage: "camera.fill")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)   // wraps onto a second line with big text instead of cutting words off
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.card)
        .controlSize(.large)
        .confirmationDialog(language("เพิ่มยาจากรูปซองยา", "Add a medicine from its label"),
                            isPresented: $showingChoice, titleVisibility: .visible) {
            Button(language("ถ่ายรูป", "Take photo"), action: takePhoto)
            Button(language("เลือกจากคลังภาพ", "Choose from Photos")) { showingPhotos = true }
            Button(language("ยกเลิก", "Cancel"), role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotos, selection: $photoItem, matching: .images)
        .accessibilityHint(language("ถ่ายรูปหรือเลือกรูปซองยา", "Take or choose a photo of a medicine envelope"))
        .frame(maxWidth: 560)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
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
