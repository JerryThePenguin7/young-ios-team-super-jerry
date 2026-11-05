import SwiftUI

/// A round icon for one medicine (like the Health app's pill icons): a symbol for its kind,
/// e.g. pills for tablets, an eye for eye drops, lungs for an inhaler.
struct PillIcon: View {
    let medicine: Medicine
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: medicine.formSymbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.accentFill.gradient, in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    let store = MedicineStore.preview()
    HStack {
        ForEach(store.medicines) { medicine in
            PillIcon(medicine: medicine)
        }
    }
    .padding()
}
