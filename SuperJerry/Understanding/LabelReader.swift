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
        let route = bothSides(compact: compact, form: form) ?? form?.route ?? savedMatch?.route

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
        // The label's own words for how to use it. Shown and read aloud word for word, never summarised.
        let directions = directionLines(lines, warnings: info.warnings)
        reading.medicine.labelDirections = directions.isEmpty ? nil : directions.joined(separator: "\n")
        reading.medicine.perSide = compact.contains("ข้างละ") ? true : nil
        reading.medicine.expiresOn = expiryDate(in: text)
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
        if route == "สูด" || route.hasPrefix("พ่นจมูก") { return .breathing }
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

    /// Words that the "Name 5 mg" rule can pick up by mistake.
    private static let notNames: Set<String> = ["TOTAL", "BOTTLE", "EACH", "TAKE", "DOSE", "VOLUME", "CONTAINS", "NET"]

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

    /// "ที" is a puff or spray: "ข้างละ 2 ที". It only counts right after ครั้งละ/ข้างละ/ทีละ and a number.
    private static let thaiUnits = "เม็ด|แคปซูล|ช้อนชา|ช้อนโต๊ะ|ซอง|หยด|พัฟ|ครั้ง|มล\\.?|ml|ซีซี|cc|ยูนิต|ที"

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

    /// "หยอดตาทั้ง 2 ข้าง", "พ่นจมูกทั้ง 2 ข้าง", "หยอดหูทั้ง 2 ข้าง"…, or "หยอดตาขวา" / "หยอดตาซ้าย".
    private static func bothSides(compact: String, form: DosageForm?) -> String? {
        guard let form, [.eyeDrops, .earDrops, .noseDrops, .nasalSpray].contains(form), let route = form.route else { return nil }
        let both = ["ทั้ง2ข้าง", "ทั้งสองข้าง", "2ข้าง", "สองข้าง", "ข้างละ"]
        if both.contains(where: { compact.contains($0) }) { return "\(route)ทั้ง 2 ข้าง" }
        if form == .eyeDrops {
            if compact.contains("ตาขวา") { return "หยอดตาขวา" }
            if compact.contains("ตาซ้าย") { return "หยอดตาซ้าย" }
        }
        return nil
    }

    // MARK: Directions, word for word

    /// Words that mean a line says how to use the medicine.
    private static let directionWords = [
        "รับประทาน", "ครั้งละ", "วันละ", "ข้างละ", "ทีละ", "หยอด", "หยด", "พ่น", "สูด", "ทาบาง", "ทาบริเวณ", "ทาที่",
        "ทาวันละ", "ทาแผล", "ทาผิว", "อมครั้งละ", "อมวันละ", "อมใต้ลิ้น", "อมช้า", "เหน็บ", "ฉีด", "ก่อนอาหาร",
        "หลังอาหาร", "พร้อมอาหาร", "ก่อนนอน", "เช้า", "กลางวัน", "เที่ยง", "เย็น", "ชั่วโมง", "เมื่อมีอาการ",
        "เวลามีอาการ", "ละลายน้ำ", "เขย่า", "เก็บ",
    ]
    private static let latinDirectionWords = [
        "take ", " tab", " cap", "drop", "puff", "spray", "apply", "inhale", "times a day", "daily", "every ",
        " hours", "before meal", "after meal", "bedtime", " bid", " tid", " qid", " prn", "shake",
    ]

    /// The lines that say how to use it, exactly as printed (just trimmed), in label order.
    /// Warnings are left out: they're kept, word for word, in `warnings`.
    static func directionLines(_ lines: [String], warnings: [String]) -> [String] {
        lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !warnings.contains(trimmed) else { return nil }
            let compact = MedicineNames.thaiKey(trimmed)
            let latin = " \(trimmed.lowercased())"
            if skipThai.contains(where: { compact.contains($0) }) || expiryDate(in: trimmed) != nil { return nil }
            let saysHow = directionWords.contains { compact.contains($0) }
                || latinDirectionWords.contains { latin.contains($0) }
            return saysHow ? trimmed : nil
        }
    }

    // MARK: Expiry date

    /// The expiry date after "EXP", "หมดอายุ", "ใช้ก่อน"…: "EXP 12/2027", "หมดอายุ 31/12/2569",
    /// "Exp. Date: 2027-03", "EXP DEC 2026", "หมดอายุ 5 มี.ค. 70". Thai Buddhist years (2569, or "69") become 2026.
    /// A month without a day means the end of that month.
    static func expiryDate(in text: String) -> Date? {
        let flat = LabelParser.normalize(text).replacingOccurrences(of: "\n", with: " ")
        let keyword = "(?:\\bexp(?:iry|ires|ired|iration)?\\.?\\s*(?:date)?|\\buse\\s*by|\\bbest\\s*before|วันหมดอายุ|วันที่หมดอายุ|หมดอายุ|วันสิ้นอายุ|ควรใช้ก่อน|ใช้ก่อน|ใช้ได้ถึง)"
        guard let regex = try? NSRegularExpression(pattern: keyword + "\\s*[:：.\\-]?\\s*", options: [.caseInsensitive]) else { return nil }
        for match in regex.matches(in: flat, range: NSRange(flat.startIndex..., in: flat)) {
            guard let end = Range(match.range, in: flat)?.upperBound else { continue }
            let tail = String(flat[end...].prefix(30))
            if let date = parseDate(tail) { return date }
        }
        return nil
    }

    private static let latinMonths = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
    /// Full names first, so "มีนาคม" isn't read as "มี.ค." plus junk. Dots are removed before matching.
    private static let thaiMonths: [(String, Int)] = [
        ("มกราคม", 1), ("กุมภาพันธ์", 2), ("มีนาคม", 3), ("เมษายน", 4), ("พฤษภาคม", 5), ("มิถุนายน", 6),
        ("กรกฎาคม", 7), ("สิงหาคม", 8), ("กันยายน", 9), ("ตุลาคม", 10), ("พฤศจิกายน", 11), ("ธันวาคม", 12),
        ("มีค", 3), ("เมย", 4), ("มิย", 6), ("มค", 1), ("กพ", 2), ("พค", 5), ("กค", 7), ("สค", 8), ("กย", 9),
        ("ตค", 10), ("พย", 11), ("ธค", 12),
    ]

    /// A date at the very start of `tail`.
    private static func parseDate(_ tail: String) -> Date? {
        let sep = "[/.\\-]"
        // 2027-12-31 or 2027/12
        if let m = firstMatch("^(\\d{4})\(sep)(\\d{1,2})(?:\(sep)(\\d{1,2}))?", in: tail) {
            return makeDate(day: m[3].flatMap { Int($0) }, month: m[2].flatMap { Int($0) }, year: m[1].flatMap { Int($0) })
        }
        // 31/12/2026 or 31.12.69
        if let m = firstMatch("^(\\d{1,2})\(sep)(\\d{1,2})\(sep)(\\d{2,4})", in: tail) {
            return makeDate(day: m[1].flatMap { Int($0) }, month: m[2].flatMap { Int($0) }, year: m[3].flatMap { Int($0) })
        }
        // 12/2027 or 12-69
        if let m = firstMatch("^(\\d{1,2})(?:\(sep)|\\s)(\\d{2,4})\\b", in: tail) {
            return makeDate(day: nil, month: m[1].flatMap { Int($0) }, year: m[2].flatMap { Int($0) })
        }
        // DEC 2026, 31 Dec 2026, Dec. 31, 2026 is rare on Thai labels so it isn't handled.
        if let m = firstMatch("^(\\d{1,2})?\\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\\.?[\\s,\\-/]*(\\d{2,4})", in: tail),
           let monthName = m[2]?.lowercased(), let month = latinMonths.firstIndex(of: String(monthName.prefix(3))) {
            return makeDate(day: m[1].flatMap { Int($0) }, month: month + 1, year: m[3].flatMap { Int($0) })
        }
        // 5 มี.ค. 2570 or ธ.ค. 69
        let thai = tail.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " ", with: "")
        if let m = firstMatch("^(\\d{1,2})?([^\\d]+?)(\\d{2,4})", in: thai), let word = m[2],
           let month = thaiMonths.first(where: { word == $0.0 })?.1 {
            return makeDate(day: m[1].flatMap { Int($0) }, month: month, year: m[3].flatMap { Int($0) })
        }
        return nil
    }

    /// Checks the numbers and turns Thai Buddhist years into ordinary ones. No day = the last day of the month.
    private static func makeDate(day: Int?, month: Int?, year: Int?) -> Date? {
        guard let month, (1...12).contains(month), var year else { return nil }
        if year < 100 { year = year >= 60 ? 2500 + year - 543 : 2000 + year }   // "69" on a Thai label is 2569
        if year > 2400 { year -= 543 }                                            // 2569 → 2026
        guard (2000...2100).contains(year) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count else { return nil }
        let day = day ?? daysInMonth
        guard (1...daysInMonth).contains(day) else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
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
