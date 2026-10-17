import Foundation
import FoundationModels

/// When to take a medicine relative to meals.
@Generable
nonisolated enum MealTiming {
    case before, after, with, anytime
}

/// Everything we read from one medicine envelope. Filled by LabelParser (rules) or by a language model.
@Generable
nonisolated struct PillInfo: Equatable {
    @Guide(description: "Drug name in English exactly as printed, e.g. Amlodipine. Empty if not printed.")
    var drugName: String
    @Guide(description: "Strength exactly as printed, e.g. 5 mg. Empty if not printed.")
    var strength: String
    @Guide(description: "How many units each time, e.g. 1 or 0.5. Use 1 if not printed.")
    var amountPerDose: Double
    @Guide(description: "Unit in Thai as printed: เม็ด, แคปซูล, ช้อนชา, ช้อนโต๊ะ, or ซอง")
    var unit: String
    var morning: Bool
    var noon: Bool
    var evening: Bool
    var bedtime: Bool
    var mealTiming: MealTiming
    @Guide(description: "True only if the label says to take it when needed, e.g. เมื่อมีอาการ")
    var asNeeded: Bool
    @Guide(description: "Warnings printed on the label, copied in Thai, short")
    var warnings: [String]
}

nonisolated extension PillInfo {
    static let empty = PillInfo(drugName: "", strength: "", amountPerDose: 1, unit: "เม็ด",
                                morning: false, noon: false, evening: false, bedtime: false,
                                mealTiming: .anytime, asNeeded: false, warnings: [])

    /// What we tell a language model before giving it a label.
    static let extractionInstructions = """
    You read Thai medicine envelope labels. Copy facts exactly as printed.
    Never guess a drug, dose, or time that is not printed. If something is missing, leave it empty or false.
    """

    var hasAnyTime: Bool { morning || noon || evening || bedtime }

    var amountText: String { amountPerDose == 0.5 ? "ครึ่ง" : String(format: "%g", amountPerDose) }

    /// One line for debugging, e.g. "Metformin 500 mg · 1 เม็ด · เช้า+เย็น · หลังอาหาร"
    var summary: String {
        var times: [String] = []
        if morning { times.append("เช้า") }
        if noon { times.append("กลางวัน") }
        if evening { times.append("เย็น") }
        if bedtime { times.append("ก่อนนอน") }
        let when = asNeeded ? "เมื่อมีอาการ" : (times.isEmpty ? "(no time)" : times.joined(separator: "+"))

        var parts = ["\(drugName.isEmpty ? "(no name)" : drugName) \(strength)", "\(amountText) \(unit)", when]
        if mealTiming != .anytime { parts.append(mealTiming.thai) }
        if !warnings.isEmpty { parts.append("⚠️ " + warnings.joined(separator: " / ")) }
        return parts.joined(separator: " · ")
    }
}

nonisolated extension MealTiming {
    var thai: String {
        switch self {
        case .before: "ก่อนอาหาร"
        case .after: "หลังอาหาร"
        case .with: "พร้อมอาหาร"
        case .anytime: ""
        }
    }
}
