import Foundation

/// How a medicine is used. Decides the unit (เม็ด, หยด, พัฟ…) and the action word (หยอดตา, ทา, สูด…).
nonisolated enum DosageForm: String, Codable, CaseIterable {
    case tablet, capsule, liquid, powder, lozenge
    case eyeDrops, earDrops, noseDrops, sublingualDrops, nasalSpray, inhaler
    case topical, suppository, injection

    /// The unit printed after "ครั้งละ N". Empty for creams, which have no count.
    var unit: String {
        switch self {
        case .tablet, .lozenge, .suppository: "เม็ด"
        case .capsule: "แคปซูล"
        case .liquid: "ช้อนชา"
        case .powder: "ซอง"
        case .eyeDrops, .earDrops, .noseDrops, .sublingualDrops: "หยด"
        case .nasalSpray: "ครั้ง"
        case .inhaler: "พัฟ"
        case .topical: ""
        case .injection: "ยูนิต"
        }
    }

    /// The action word shown before the amount. nil means "take by mouth" (the default).
    var route: String? {
        switch self {
        case .tablet, .capsule, .liquid, .powder: nil
        case .lozenge: "อม"
        case .eyeDrops: "หยอดตา"
        case .earDrops: "หยอดหู"
        case .noseDrops: "หยอดจมูก"
        case .sublingualDrops: "หยดใต้ลิ้น"
        case .nasalSpray: "พ่นจมูก"
        case .inhaler: "สูด"
        case .topical: "ทาบาง ๆ"
        case .suppository: "เหน็บ"
        case .injection: "ฉีด"
        }
    }

    /// Finds the form from words on the label. Checked in order, most specific first.
    /// `compact` is Thai text with spaces removed; `latin` is lowercased text.
    static func detect(compact: String, latin: String) -> DosageForm? {
        let rules: [(DosageForm, thai: [String], latin: [String])] = [
            (.eyeDrops, ["หยอดตา", "ยาหยอดตา"], ["eye drop", "eyedrop", "ophthalmic", "eye/ear drop"]),
            (.earDrops, ["หยอดหู"], ["ear drop", "otic"]),
            (.noseDrops, ["หยอดจมูก"], ["nasal drop"]),
            (.sublingualDrops, ["หยดใต้ลิ้น", "ใต้ลิ้น"], ["sublingual"]),
            (.nasalSpray, ["พ่นจมูก"], ["nasal spray", "nasal"]),
            (.inhaler, ["สูด", "พ่นปาก", "พ่นเข้าปาก", "พัฟ"], ["inhaler", "puff", "evohaler", "accuhaler", "turbuhaler", "inhalation"]),
            (.suppository, ["เหน็บ"], ["suppositor"]),
            (.topical, ["ทาบาง", "ทาบริเวณ", "ทาที่", "ยาทา", "ทาผิว", "ทาแผล", "ครีม", "ขี้ผึ้ง", "เจล", "โลชั่น"],
             ["cream", "ointment", " gel", "lotion", "apply"]),
            (.lozenge, ["ยาอม", "อมครั้งละ", "อมวันละ", "อมเม็ด", "อมช้า"], ["lozenge"]),
            (.injection, ["ฉีด", "ยูนิต"], ["inject", "units"]),
            (.liquid, ["ช้อนชา", "ช้อนโต๊ะ", "ยาน้ำ", "ไซรัป", "ยาแขวนตะกอน"], ["syrup", "suspension", "elixir", "mixture", "tsp"]),
            (.powder, ["ยาผง", "ละลายน้ำ"], ["sachet", "powder"]),
            (.capsule, ["แคปซูล"], ["capsule"]),
            (.tablet, ["เม็ด"], ["tablet"]),
        ]
        let paddedLatin = " \(latin)"
        for rule in rules {
            if rule.thai.contains(where: { compact.contains($0) }) { return rule.0 }
            if rule.latin.contains(where: { paddedLatin.contains($0) }) { return rule.0 }
        }
        return nil
    }
}
