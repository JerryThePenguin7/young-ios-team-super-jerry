import Foundation

/// Everything about a medicine that the user reads or hears, in Thai or in English.
/// Medicines are saved with the Thai words from the label ("เม็ด", "หลังอาหาร", "หยอดตา");
/// these turn them into the chosen language, so the screen never mixes the two.
nonisolated extension Medicine {
    /// The name to show. In English, Thai in brackets is left out: "MAWANG (มะแว้ง)" → "MAWANG".
    func displayName(_ language: AppLanguage) -> String {
        guard !name.isEmpty else { return language("ยา (ไม่ทราบชื่อ)", "Unnamed medicine") }
        guard language == .english else { return name }
        let withoutThai = name
            .replacingOccurrences(of: #"\s*\([^)]*[\u0E00-\u0E7F][^)]*\)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        return withoutThai.isEmpty ? name : withoutThai
    }

    /// "1", "1-2", and a half: "ครึ่ง" or "½".
    func amountText(_ language: AppLanguage) -> String {
        guard language == .english else { return amountText }
        let first = amount == 0.5 ? "½" : String(format: "%g", amount)
        if let amountMax, amountMax > amount { return "\(first)-\(String(format: "%g", amountMax))" }
        return first
    }

    /// "ครั้งละ 1 เม็ด" or "1 tablet each time"; with how it's used: "Both eyes: 1 drop each time".
    func amountLine(_ language: AppLanguage) -> String {
        guard language == .english else { return amountLine }
        guard !unit.isEmpty else { return route.map { Self.routeName($0, .english) } ?? "Use as directed" }
        let each = "\(doseText(.english)) each time"
        return route.map { "\(Self.routeName($0, .english)): \(each)" } ?? each
    }

    /// "1 เม็ด" or "1 tablet", for "1 tablet at 8:00 AM".
    func doseText(_ language: AppLanguage) -> String {
        guard !unit.isEmpty else { return language("ใช้ยา", "Used") }
        let plural = (amountMax ?? amount) > 1
        return "\(amountText(language)) \(Self.unitName(unit, language, plural: plural))"
    }

    /// "ยาเม็ด" or "Tablet", from how it's used and its unit.
    func formName(_ language: AppLanguage) -> String {
        let route = route ?? ""
        let names: (String, String) =
            if route.hasPrefix("หยอดตา") { ("ยาหยอดตา", "Eye drops") }
            else if route == "หยอดหู" { ("ยาหยอดหู", "Ear drops") }
            else if route == "หยอดจมูก" { ("ยาหยอดจมูก", "Nose drops") }
            else if route == "พ่นจมูก" { ("ยาพ่นจมูก", "Nasal spray") }
            else if route == "สูด" || unit == "พัฟ" { ("ยาสูด", "Inhaler") }
            else if route.hasPrefix("ทา") || (unit.isEmpty && route.isEmpty) { ("ยาทา", "Cream") }
            else if route == "อม" { ("ยาอม", "Lozenge") }
            else if route == "เหน็บ" { ("ยาเหน็บ", "Suppository") }
            else if route == "ฉีด" { ("ยาฉีด", "Injection") }
            else if unit == "หยด" { ("ยาหยด", "Drops") }
            else if unit == "แคปซูล" { ("แคปซูล", "Capsule") }
            else if ["ช้อนชา", "ช้อนโต๊ะ", "ml"].contains(unit) { ("ยาน้ำ", "Liquid") }
            else if unit == "ซอง" { ("ยาผง", "Powder") }
            else { ("ยาเม็ด", "Tablet") }
        return language(names.0, names.1)
    }

    /// "Capsule, 100 mg" or "แคปซูล 100 mg"
    func formLine(_ language: AppLanguage) -> String {
        [formName(language), strength].filter { !$0.isEmpty }.joined(separator: language == .thai ? " " : ", ")
    }

    /// An SF Symbol that looks like this kind of medicine.
    var formSymbol: String {
        let route = route ?? ""
        if route.hasPrefix("หยอดตา") { return "eye.fill" }
        if route == "หยอดหู" { return "ear.fill" }
        if route == "สูด" || route == "พ่นจมูก" || unit == "พัฟ" { return "lungs.fill" }
        if route.hasPrefix("ทา") || unit.isEmpty { return "hand.raised.fill" }
        if route == "ฉีด" || unit == "ยูนิต" { return "syringe.fill" }
        if unit == "หยด" || ["ช้อนชา", "ช้อนโต๊ะ", "ml"].contains(unit) { return "drop.fill" }
        if unit == "แคปซูล" { return "capsule.fill" }
        return "pills.fill"
    }

    /// What it's for: "ยาลดความดัน" (from the name list) or the group, e.g. "Diabetes".
    func purpose(_ language: AppLanguage) -> String? {
        if language == .thai, let friendlyName { return friendlyName }
        guard let group, group != .other else { return nil }
        return group.name(language)
    }

    /// "ทุกวัน · เช้า เย็น" or "Every day · Morning, Evening"
    func scheduleText(_ language: AppLanguage) -> String {
        if asNeeded { return language("เมื่อมีอาการ", "When needed") }
        if orderedSlots.isEmpty { return language("ยังไม่ได้ตั้งเวลา", "No time set") }
        let slots = orderedSlots.map { $0.name(language) }.joined(separator: language == .thai ? " " : ", ")
        return language("ทุกวัน · \(slots)", "Every day · \(slots)")
    }

    /// Label warnings in the chosen language. In English, Jenny translates the warnings it knows;
    /// any other line stays as printed on the label.
    func warningLines(_ language: AppLanguage) -> [String] {
        guard language == .english else { return warnings }
        var lines: [String] = []
        for warning in warnings {
            let line = Self.englishWarning(warning) ?? warning
            if !lines.contains(line) { lines.append(line) }
        }
        return lines
    }

    /// What the voice reads, all in one language.
    /// Thai: "ยา Metformin. ยาเบาหวาน. กินครั้งละ 1 เม็ด. ตอนเช้า และตอนเย็น. หลังอาหาร"
    /// English: "Metformin. Diabetes. Take 1 tablet each time. In the morning and in the evening. After meals."
    func spoken(_ language: AppLanguage) -> String {
        guard language == .english else { return spokenThai }
        var parts = [displayName(.english)]
        if let purpose = purpose(.english) { parts.append(purpose) }
        parts.append(route == nil && !unit.isEmpty ? "Take \(amountLine(.english))" : amountLine(.english))
        if asNeeded {
            parts.append("When needed")
        } else if !orderedSlots.isEmpty {
            let times = Self.englishList(orderedSlots.map { $0.spoken(.english) })
            parts.append(times.prefix(1).uppercased() + String(times.dropFirst()))
        }
        if !meal.isEmpty { parts.append(Self.mealName(meal, .english)) }
        // Only the warnings Jenny could translate: an English voice can't read Thai.
        parts += warnings.compactMap(Self.englishWarning)
        return parts.joined(separator: ". ")
    }

    /// "a and b", or "a, b, and c"
    private static func englishList(_ items: [String]) -> String {
        guard items.count > 2, let last = items.last else { return items.joined(separator: " and ") }
        return items.dropLast().joined(separator: ", ") + ", and " + last
    }

    // MARK: Words saved in Thai, shown in either language

    /// "เม็ด" → "tablet" / "tablets"
    static func unitName(_ unit: String, _ language: AppLanguage, plural: Bool = false) -> String {
        guard language == .english else { return unit }
        let names: [String: (one: String, many: String)] = [
            "เม็ด": ("tablet", "tablets"), "แคปซูล": ("capsule", "capsules"), "หยด": ("drop", "drops"),
            "ช้อนชา": ("teaspoon", "teaspoons"), "ช้อนโต๊ะ": ("tablespoon", "tablespoons"), "ml": ("ml", "ml"),
            "ซอง": ("sachet", "sachets"), "พัฟ": ("puff", "puffs"), "ครั้ง": ("spray", "sprays"),
            "ยูนิต": ("unit", "units"),
        ]
        guard let name = names[unit] else { return unit }
        return plural ? name.many : name.one
    }

    /// "หยอดตาทั้ง 2 ข้าง" → "Both eyes". An empty route means by mouth.
    static func routeName(_ route: String, _ language: AppLanguage) -> String {
        guard language == .english else { return route.isEmpty ? "กิน (ทางปาก)" : route }
        return switch route {
        case "": "By mouth"
        case "หยอดตา": "In the eye"
        case "หยอดตาขวา": "Right eye"
        case "หยอดตาซ้าย": "Left eye"
        case "หยอดตาทั้ง 2 ข้าง": "Both eyes"
        case "หยอดหู": "In the ear"
        case "หยอดจมูก": "In the nose"
        case "หยดใต้ลิ้น": "Under the tongue"
        case "พ่นจมูก": "Nasal spray"
        case "สูด": "Inhale"
        case "ทาบาง ๆ": "Apply a thin layer"
        case "อม": "Dissolve in the mouth"
        case "เหน็บ": "Suppository"
        case "ฉีด": "Inject"
        default: route
        }
    }

    /// "หลังอาหาร" → "After meals". Empty means not stated.
    static func mealName(_ meal: String, _ language: AppLanguage) -> String {
        guard language == .english else { return meal.isEmpty ? "ไม่ระบุ" : meal }
        return switch meal {
        case "": "Not stated"
        case "ก่อนอาหาร": "Before meals"
        case "หลังอาหาร": "After meals"
        case "พร้อมอาหาร": "With meals"
        default: meal
        }
    }

    /// English for the warnings printed on Thai labels. nil if Jenny doesn't know this one.
    static func englishWarning(_ thai: String) -> String? {
        let text = MedicineNames.thaiKey(thai)
        let known: [(words: [String], english: String)] = [
            (["ง่วง"], "May make you sleepy. Take care when driving."),
            (["สุรา", "แอลกอฮอล์", "เหล้า"], "Do not drink alcohol."),
            (["จนหมด"], "Take it until it's all finished."),
            (["เคี้ยว", "บดยา", "หักยา", "แบ่งยา"], "Swallow whole. Do not chew or crush."),
            (["เขย่า"], "Shake well before use."),
            (["ตู้เย็น"], "Keep in the fridge."),
            (["ภายนอก"], "For external use only."),
            (["ดื่มน้ำ"], "Drink plenty of water."),
        ]
        let matches = known.filter { item in item.words.contains { text.contains($0) } }.map(\.english)
        return matches.isEmpty ? nil : matches.joined(separator: " ")
    }
}
