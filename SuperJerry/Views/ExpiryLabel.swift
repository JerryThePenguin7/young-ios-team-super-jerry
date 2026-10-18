import SwiftUI

/// The expiry date from the label: "หมดอายุ 31 ธ.ค. 2570" / "Expires 31 Dec 2027".
/// Expired: a red icon and "Expired"; within 30 days: an orange icon. Dark words, so it's easy to read.
struct ExpiryLabel: View {
    @Environment(\.language) private var language
    let medicine: Medicine
    var now = Date()

    var body: some View {
        if let text = medicine.expiryText(language, now: now) {
            Label {
                Text(text)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(color)
            }
            .font(medicine.isExpired(now: now) ? Font.headline : Font.subheadline.weight(.semibold))
            .padding(.horizontal, isWarning ? 10 : 0)
            .padding(.vertical, isWarning ? 5 : 0)
            .background(isWarning ? color.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var isWarning: Bool {
        medicine.isExpired(now: now) || medicine.expiresSoon(now: now)
    }

    private var symbol: String {
        medicine.isExpired(now: now) ? "exclamationmark.octagon.fill" : "calendar.badge.clock"
    }

    private var color: Color {
        if medicine.isExpired(now: now) { return .red }
        if medicine.expiresSoon(now: now) { return .orange }
        return .secondary
    }
}

#Preview {
    var fine = Medicine.blank
    fine.expiresOn = Date().addingTimeInterval(400 * 86400)
    var soon = fine
    soon.expiresOn = Date().addingTimeInterval(10 * 86400)
    var expired = fine
    expired.expiresOn = Date().addingTimeInterval(-10 * 86400)
    return VStack(alignment: .leading, spacing: 16) {
        ExpiryLabel(medicine: fine)
        ExpiryLabel(medicine: soon)
        ExpiryLabel(medicine: expired)
    }
    .padding()
    .environment(\.language, .english)
}
