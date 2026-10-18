import SwiftUI

/// How many are left, on the medicine's own screen (this used to be the separate "Medicine Storage" list):
/// the count, a bar, about how many days that lasts, and when Jenny says "Running low".
/// Jenny counts down by itself every time the medicine is logged as Taken. The button sets or refills the count.
struct StockCard: View {
    @Environment(\.language) private var language
    let medicine: Medicine
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text(language("ยังไม่ได้นับ ใส่จำนวนยาที่มี แล้ว Jenny จะนับลดลงให้ทุกครั้งที่ทาน",
                              "Not counted yet. Add how many you have, and Jenny counts down each time you take one."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: edit) {
                Label(medicine.stock == nil ? language("ใส่จำนวนยา", "Add how many") : language("เติมยา หรือแก้จำนวน", "Refill or change"),
                      systemImage: medicine.stock == nil ? "plus" : "pencil")
                    .font(.headline)
                    .foregroundStyle(Theme.red)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            }
            .buttonStyle(.pressable)
        }
    }

    private var countText: some View {
        Text(medicine.stockText(language))
            .font(.title2.bold())
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
    var counted = Medicine.blank
    counted.name = "Metformin"
    counted.slots = [.morning, .evening]
    counted.stock = 8
    counted.stockFull = 60
    return VStack(spacing: 30) {
        StockCard(medicine: counted, edit: {})
        StockCard(medicine: .blank, edit: {})
    }
    .padding()
    .environment(\.language, .thai)
}
