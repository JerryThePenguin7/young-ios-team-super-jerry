import SwiftUI

/// The important things to see before taking a medicine, right under its name:
/// expired (or expiring within 30 days), running low, and the label's warnings ("May make you sleepy").
/// Dark words with a colored icon, so they're easy to read. Shows nothing if there's nothing to say.
struct MedicineAlerts: View {
    @Environment(\.language) private var language
    let medicine: Medicine
    var now = Date()
    /// false in the Log: the envelope's "หมายเหตุ" (Note) lines stay on the medicine's own screen.
    var showsNotes = true

    var body: some View {
        let warnings = medicine.warningLines(language, includeNotes: showsNotes)
        let hasAlerts = medicine.isExpired(now: now) || medicine.expiresSoon(now: now)
            || medicine.isLowStock || !warnings.isEmpty

        if hasAlerts {
            VStack(alignment: .leading, spacing: 6) {
                if medicine.isExpired(now: now) || medicine.expiresSoon(now: now) {
                    ExpiryLabel(medicine: medicine, now: now)
                }
                if medicine.isLowStock {
                    alert(language("ยาใกล้หมด", "Running low"), symbol: "exclamationmark.triangle.fill", color: .orange)
                }
                ForEach(warnings, id: \.self) { warning in
                    alert(warning, symbol: "exclamationmark.bubble.fill", color: .orange)
                }
            }
        }
    }

    private func alert(_ text: String, symbol: String, color: Color) -> some View {
        Label {
            Text(text)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
        }
        .font(.callout.weight(.semibold))
    }
}

#Preview {
    var medicine = Medicine.blank
    medicine.name = "Chlorpheniramine"
    medicine.warnings = ["ยานี้อาจทำให้ง่วงนอน ห้ามดื่มสุรา"]
    medicine.expiresOn = Date().addingTimeInterval(-5 * 86400)
    medicine.stock = 2
    return VStack(alignment: .leading, spacing: 30) {
        MedicineAlerts(medicine: medicine)
        MedicineAlerts(medicine: medicine)
            .environment(\.language, .english)
    }
    .padding()
}
