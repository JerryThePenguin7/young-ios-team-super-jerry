import SwiftUI
import UIKit

/// The photo of a medicine's label (so every envelope is easy to tell apart), or a pill icon if there's none.
struct MedicinePhoto: View {
    let file: String?
    var size: CGFloat = 84

    var body: some View {
        Group {
            if let file, let image = PhotoStore.load(file) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "pills.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(Theme.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.fill)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHidden(true)
    }
}

#Preview {
    MedicinePhoto(file: nil)
        .padding()
}
