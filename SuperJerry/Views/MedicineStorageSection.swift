import SwiftUI

/// "Medicine Storage" under Your Medications: how many of each medicine are left, and about how many days
/// that lasts. Jenny counts down by itself when a dose is logged as Taken.
/// Running low first. Tap a row to set or refill the count and the "Running low" level.
struct MedicineStorageSection: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    let edit: (Medicine) -> Void

    var body: some View {
        let medicines = countable

        VStack(alignment: .leading, spacing: 12) {
            Text(language("คลังยา", "Medicine Storage"))
                .font(.title.bold())
            Text(language("Jenny จะลดจำนวนยาให้เองทุกครั้งที่คุณบันทึกว่าทานแล้ว",
                          "Jenny counts down by itself every time you log Taken."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(medicines) { medicine in
                    if medicine.id != medicines.first?.id { Divider() }
                    Button {
                        edit(medicine)
                    } label: {
                        StorageRow(medicine: medicine)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(language("แตะเพื่อใส่หรือเติมจำนวนยา", "Tap to set or refill the count"))
                }
            }
            .padding(.horizontal, 20)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Running low first, then the fewest days left, then the ones not counted yet.
    private var countable: [Medicine] {
        store.medicines
            .filter(\.canCountStock)
            .sorted { first, second in
                if first.isLowStock != second.isLowStock { return first.isLowStock }
                if (first.stock != nil) != (second.stock != nil) { return first.stock != nil }
                return (first.daysLeft ?? .max) < (second.daysLeft ?? .max)
            }
    }
}

/// One medicine's count: the icon, the name, how many are left, a bar, days left, and the warning level.
private struct StorageRow: View {
    @Environment(\.language) private var language
    let medicine: Medicine

    var body: some View {
        HStack(spacing: 14) {
            PillIcon(medicine: medicine)
            VStack(alignment: .leading, spacing: 6) {
                Text(medicine.displayName(language))
                    .font(.title3)
                if medicine.stock != nil {
                    // The count and "Running low" side by side, or one above the other when there's no room.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            countText
                            if medicine.isLowStock { lowBadge }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            countText
                            if medicine.isLowStock { lowBadge }
                        }
                    }
                    ProgressView(value: medicine.stockFraction)
                        .tint(medicine.isLowStock ? Color.orange : Theme.green)
                        .accessibilityHidden(true)
                    Text([medicine.daysLeftText(language), medicine.lowLevelText(language)]
                            .compactMap { $0 }
                            .joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(language("ยังไม่ได้นับ แตะเพื่อใส่จำนวนยาที่มี",
                                  "Not counted yet. Tap to add how many you have."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: medicine.stock == nil ? "plus" : "pencil")
                .font(.title3.bold())
                .foregroundStyle(Theme.red)
                .frame(width: 44, height: 44)
                .background(Theme.fill, in: Circle())
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
    }

    private var countText: some View {
        Text(medicine.stockText(language))
            .font(.headline)
    }

    /// Dark words on a light orange tint with an orange icon: orange text is too hard to read.
    private var lowBadge: some View {
        Label {
            Text(language("ใกล้หมด", "Running low"))
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.18), in: Capsule())
    }
}

#Preview {
    let store = MedicineStore.preview()
    store.setStock(30, for: store.medicines[0].id)
    store.setStock(4, for: store.medicines[1].id)
    store.setLowAt(10, for: store.medicines[0].id)
    return ScrollView {
        MedicineStorageSection { _ in }
            .padding()
    }
    .background(Theme.background)
    .environment(store)
    .environment(\.language, .english)
}
