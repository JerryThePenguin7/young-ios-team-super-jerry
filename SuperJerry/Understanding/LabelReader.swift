import Foundation

/// Where the medicine's name came from, so the result screen can ask the user to check guesses.
nonisolated enum NameSource {
    case nameList     // found in Jenny's medicine name list
    case saved        // a name the user saved before
    case label        // read by the rules ("Amlodipine 5 mg")
    case guess        // a likely name, but not certain
    case none
}

/// Everything Jenny read from one label.
nonisolated struct LabelReading {
    var medicine: Medicine
    var nameSource: NameSource
    var unitGuessed: Bool
    var timesGuessed: Bool
    /// nil when the reader couldn't group it; the AI then tries (see MedicineGrouper).
    var groupSource: GroupSource?
}

/// Jenny's label reader. The Thai rules (LabelParser) find the times, meals and warnings.
/// This adds what they miss: the name (from the name list, saved medicines, or a careful guess),
/// how it's used (eye drops, cream, inhaler…), the right unit (หยด, พัฟ, ช้อนชา…), and ranges like "1-2".
nonisolated enum LabelReader {
    /// nil when the photo has nothing that looks like a medicine label.
    static func read(_ lines: [String], saved: [Medicine] = [],
                     names: [MedicineNameEntry] = MedicineNames.all) -> LabelReading? {
        let info = LabelParser.parse(lines)
        let text = lines.joined(separator: "\n")
        let compact = MedicineNames.thaiKey(text)
        let latin = text.lowercased()

        let amount = findAmount(compact: compact, latin: latin)
        let detectedForm = DosageForm.detect(compact: compact, latin: latin)
        let (name, nameSource, entry) = findName(lines: lines, parserName: info.drugName, saved: saved, names: names)

        // Is there anything medicine-like on this photo at all?
        let hasEvidence = info.hasAnyTime || info.asNeeded || amount != nil || detectedForm != nil
            || compact.contains("วันละ") || nameSource == .nameList || nameSource == .saved
        guard hasEvidence, !(name.isEmpty && amount == nil && !info.hasAnyTime && !info.asNeeded) else { return nil }

        // Unit: printed next to the amount > how it's used > the name list > a medicine saved before > เม็ด (a guess).
        let savedMatch = saved.first { MedicineNames.matchKey($0.name) == MedicineNames.matchKey(name) }
        let form = detectedForm ?? entry?.form
        var unit = info.unit
        var unitGuessed = false
        if let printed = amount?.unit {
            unit = printed
        } else if let form {
            unit = form.unit
        } else if let savedMatch {
            unit = savedMatch.unit
        } else {
            unit = "เม็ด"
            unitGuessed = true
        }
        let route = eyeSide(compact: compact, form: form) ?? form?.route ?? savedMatch?.route

        // Times: the rules' slots, or "วันละ 3-4 ครั้ง" / "ทุก 6 ชั่วโมง" that the rules don't handle.
        var slots = info.slots
        var timesGuessed = LabelParser.timesAreGuessed(in: lines)
        if slots.isEmpty && !info.asNeeded, let perDay = timesPerDay(compact: compact) {
            slots = defaultSlots(perDay)
            timesGuessed = true
        }

        let medicine = Medicine(
            name: name,
            strength: info.strength.isEmpty ? percentStrength(text) : info.strength,
            amount: amount?.value ?? info.amountPerDose,
            unit: unit,
            slots: slots,
            meal: info.mealTiming.thai,
            asNeeded: info.asNeeded,
            warnings: info.warnings,
            scannedText: text,
            photoFile: nil,
            route: route,
            amountMax: amount?.max
        )
        var reading = LabelReading(medicine: medicine, nameSource: nameSource, unitGuessed: unitGuessed,
                                   timesGuessed: timesGuessed)
        if let group = entry?.group ?? savedMatch?.group {
            reading.medicine.group = group
            reading.groupSource = .nameList
        } else if let group = ruleGroup(route: route, name: name, form: form) {
            reading.medicine.group = group
            reading.groupSource = .rules
        }
        return reading
    }

    /// A group from how it's used or how it's named, for medicines that aren't in the name list.
    static func ruleGroup(route: String?, name: String, form: DosageForm? = nil) -> MedicineGroup? {
        let route = route ?? form?.route ?? ""
        if route.contains("หยอดตา") || route.contains("หยอดหู") { return .eyesEars }
        if route.hasPrefix("ทา") { return .skin }
        if route == "สูด" || route == "พ่นจมูก" { return .breathing }
        let thaiName = MedicineNames.thaiKey(name)
        let herbalWords = ["ยาหอม", "ยาแผนไทย", "สมุนไพร", "ยาธาตุ", "ยาเขียว", "ยาประสะ"]
        if herbalWords.contains(where: { thaiName.contains($0) }) { return .herbal }
        if thaiName.contains("แก้ไอ") { return .breathing }
        return nil
    }

    // MARK: Name

    private static func findName(lines: [String], parserName: String, saved: [Medicine],
                                 names: [MedicineNameEntry]) -> (String, NameSource, MedicineNameEntry?) {
        // Names the user saved before: they may have typed a name that isn't in any list.
        let savedEntries = saved.filter { !$0.name.isEmpty }.map { MedicineNameEntry(name: $0.name) }
        func listEntry(for name: String) -> MedicineNameEntry? { MedicineNames.correct(name, entries: names)?.entry }

        // 1. The rules found "Name 5 mg": fix its spelling from saved names or the list.
        if !parserName.isEmpty && !notNames.contains(parserName.uppercased()) {
            if let match = MedicineNames.correct(parserName, entries: savedEntries) {
                return (match.entry.name, .saved, listEntry(for: match.entry.name))
            }
            if let match = MedicineNames.correct(parserName, entries: names) {
                return (match.entry.name, .nameList, match.entry)
            }
            return (parserName, .label, nil)
        }
        // 2. A name the user saved before, anywhere on the label.
        if let match = MedicineNames.bestMatch(in: lines, entries: savedEntries), match.distance == 0 {
            return (match.entry.name, .saved, listEntry(for: match.entry.name))
        }
        // 3. Any name from the list anywhere on the label (MAWANG, มะแว้ง, Tears Naturale…).
        if let match = MedicineNames.bestMatch(in: lines, entries: names) {
            return (match.entry.name, .nameList, match.entry)
        }
        // 4. A careful guess: a short line that isn't the hospital, the patient, or the instructions.
        if let guess = guessName(lines) { return (guess, .guess, nil) }
        return ("", .none, nil)
    }

    /// Words that the "Name 5 mg" rule can pick up by mistake, like "Amoxicillin Suspension 125 mg".
    /// Then the name is looked up in the list instead.
    private static let notNames: Set<String> = [
        "TOTAL", "BOTTLE", "EACH", "TAKE", "DOSE", "VOLUME", "CONTAINS", "NET",
        "SYRUP", "SUSPENSION", "SOLUTION", "ELIXIR", "MIXTURE", "DROPS", "DROP", "CREAM", "OINTMENT", "LOTION",
        "TABLET", "TABLETS", "CAPSULE", "CAPSULES", "INJECTION", "SPRAY", "INHALER", "EVOHALER", "ACCUHALER",
        "TURBUHALER", "RESPIMAT", "POWDER", "SACHET",
    ]

    /// Lines with these are the hospital, the patient, or the date, not the medicine.
    private static let skipThai = [
        "โรงพยาบาล", "รพ.", "คลินิก", "ร้านขายยา", "เภสัช", "โทร", "ชื่อ", "นาย", "นาง", "น.ส.", "ด.ช.", "ด.ญ.",
        "เด็กชาย", "เด็กหญิง", "วันที่",
    ]
    private static let skipLatin: Set<String> = [
        "HOSPITAL", "CLINIC", "PHARMACY", "TEL", "HN", "DATE", "EXP", "MFG", "LOT", "REG", "PATIENT",
        "MR", "MRS", "MS", "MISS", "DR",
    ]
    /// Lines with these are instructions or warnings, not the name.
    private static let instructionWords = [
        "รับประทาน", "ครั้งละ", "วันละ", "หลังอาหาร", "ก่อนอาหาร", "ก่อนนอน", "หยอด", "ทาบาง", "ชั่วโมง",
        "เม็ด", "คำเตือน", "ห้าม", "ควร", "เช้า", "เย็น", "ง่วง", "ทำให้", "อาจ", "ใช้", "นี้", "เก็บ", "ภายนอก",
    ]
    private static let latinNotNames: Set<String> = [
        "TABLET", "TABLETS", "CAPSULE", "CAPSULES", "TAKE", "DAILY", "WITH", "AFTER", "BEFORE", "MEAL", "MEALS",
        "FOOD", "TIMES", "ONCE", "TWICE", "EACH", "DROPS", "DROP", "CREAM", "HOSPITAL", "CLINIC", "PHARMACY",
        "WATER", "ORAL", "MORNING", "EVENING", "NIGHT", "BEDTIME", "SHAKE", "WELL", "STORE", "KEEP", "USE",
        "ONLY", "EXTERNAL", "DOCTOR", "PATIENT", "NAME", "DATE", "EXPIRY", "QTY",
    ]

    private static func guessName(_ lines: [String]) -> String? {
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let compact = MedicineNames.thaiKey(trimmed)
            guard !trimmed.isEmpty,
                  !skipThai.contains(where: { compact.contains($0) }),
                  Set(MedicineNames.latinWords(trimmed)).isDisjoint(with: skipLatin),
                  !instructionWords.contains(where: { compact.contains($0) }) else { continue }

            // A Thai name like "ยาแก้ไอ…" or "ยาหอม…".
            if compact.hasPrefix("ยา") && (4...30).contains(compact.count) { return trimmed }

            // A short Latin name, often in capitals like "MAWANG".
            let words = MedicineNames.latinWords(trimmed).filter { $0.count >= 4 && !latinNotNames.contains($0) }
            let letters = trimmed.filter { $0.isLetter }.count
            if (1...3).contains(words.count) && letters * 2 >= trimmed.count {
                return words.map { String($0.prefix(1)) + $0.dropFirst().lowercased() }.joined(separator: " ")
            }
        }
        return nil
    }

    // MARK: Amount and unit

    private nonisolated struct Amount {
        var value: Double
        var max: Double?
        var unit: String?
    }

    private static let thaiUnits = "เม็ด|แคปซูล|ช้อนชา|ช้อนโต๊ะ|ซอง|หยด|พัฟ|ครั้ง|มล\\.?|ml|ซีซี|cc|ยูนิต"

    /// "ครั้งละ 1-2 เม็ด", "ข้างละ 1 หยด", "หยอดตา 2 หยด", "2 puffs", "1 tab".
    private static func findAmount(compact: String, latin: String) -> Amount? {
        let number = "(\\d+/\\d+|\\d+(?:\\.\\d+)?|ครึ่ง|½)"
        if let match = firstMatch("(?:ครั้งละ|ข้างละ|ทีละ)\(number)(?:-(\\d+(?:\\.\\d+)?))?(\(thaiUnits))?", in: compact) {
            return Amount(value: parseNumber(match[1]) ?? 1, max: match[2].flatMap { Double($0) },
                          unit: match[3].map(thaiUnit))
        }
        // Drops and puffs often skip "ครั้งละ": "หยอดตา 2 หยด".
        if let match = firstMatch("\(number)(?:-(\\d+(?:\\.\\d+)?))?(หยด|พัฟ)", in: compact) {
            return Amount(value: parseNumber(match[1]) ?? 1, max: match[2].flatMap { Double($0) }, unit: match[3])
        }
        // No "ml" here: "15 ml" in English is usually the bottle size, not the dose.
        let latinUnits = "tabs?|tablets?|caps?|capsules?|drops?|gtts?|puffs?|tsp|teaspoons?"
        if let match = firstMatch("\\b(\\d+(?:\\.\\d+)?)(?:\\s*-\\s*(\\d+(?:\\.\\d+)?))?\\s*(\(latinUnits))\\b", in: latin) {
            return Amount(value: Double(match[1] ?? "") ?? 1, max: match[2].flatMap { Double($0) },
                          unit: match[3].map(latinUnit))
        }
        return nil
    }

    private static func parseNumber(_ text: String?) -> Double? {
        guard let text else { return nil }
        if text == "ครึ่ง" || text == "½" { return 0.5 }
        let parts = text.split(separator: "/").compactMap { Double($0) }
        if parts.count == 2, parts[1] != 0 { return parts[0] / parts[1] }
        return Double(text)
    }

    private static func thaiUnit(_ unit: String) -> String {
        switch unit {
        case "มล", "มล.", "ซีซี", "cc": "ml"
        default: unit
        }
    }

    private static func latinUnit(_ unit: String) -> String {
        if unit.hasPrefix("tab") { return "เม็ด" }
        if unit.hasPrefix("cap") { return "แคปซูล" }
        if unit.hasPrefix("drop") || unit.hasPrefix("gtt") { return "หยด" }
        if unit.hasPrefix("puff") { return "พัฟ" }
        if unit == "tsp" || unit.hasPrefix("teaspoon") { return "ช้อนชา" }
        return "ml"
    }

    /// "หยอดตาขวา", "หยอดตาซ้าย", or "หยอดตาทั้ง 2 ข้าง" for eye drops.
    private static func eyeSide(compact: String, form: DosageForm?) -> String? {
        guard form == .eyeDrops else { return nil }
        if compact.contains("ทั้ง2ข้าง") || compact.contains("ทั้งสองข้าง") || compact.contains("ข้างละ") {
            return "หยอดตาทั้ง 2 ข้าง"
        }
        if compact.contains("ตาขวา") { return "หยอดตาขวา" }
        if compact.contains("ตาซ้าย") { return "หยอดตาซ้าย" }
        return nil
    }

    /// "0.5%" for eye drops and creams, which print a percentage instead of mg.
    private static func percentStrength(_ text: String) -> String {
        firstMatch("(\\d+(?:\\.\\d+)?)\\s?%", in: text).flatMap { $0[1] }.map { "\($0)%" } ?? ""
    }

    // MARK: Times

    /// "วันละ 3-4 ครั้ง" → 3, "วันละครั้ง" → 1, "ทุก 6 ชั่วโมง" → 4.
    private static func timesPerDay(compact: String) -> Int? {
        if let match = firstMatch("วันละ(\\d)(?:-(\\d))?ครั้ง", in: compact), let count = match[1].flatMap({ Int($0) }) {
            return count
        }
        if compact.contains("วันละครั้ง") || compact.contains("วันละหนึ่งครั้ง") { return 1 }
        if let match = firstMatch("ทุก(\\d+)ชั่วโมง", in: compact), let hours = match[1].flatMap({ Int($0) }), hours > 0 {
            return max(1, min(4, 24 / hours))
        }
        return nil
    }

    private static func defaultSlots(_ perDay: Int) -> [TimeSlot] {
        switch perDay {
        case ...1: [.morning]
        case 2: [.morning, .evening]
        case 3: [.morning, .noon, .evening]
        default: TimeSlot.allCases
        }
    }

    // MARK: Regex helper

    /// The first match's capture groups (index 0 = the whole match). nil groups didn't take part.
    private static func firstMatch(_ pattern: String, in text: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (0..<match.numberOfRanges).map { index in
            Range(match.range(at: index), in: text).map { String(text[$0]) }
        }
    }
}
