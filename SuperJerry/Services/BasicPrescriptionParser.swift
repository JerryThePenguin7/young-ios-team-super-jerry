import Foundation

/// Jenny's offline backup reader. It uses simple text rules (no AI), so it works on every device,
/// including the Intel Macs' simulator. Write one medicine per line, e.g.
/// "Metformin 500mg 1 tablet twice a day after meals" or "พาราเซตามอล 500 มก. วันละ 3 ครั้ง หลังอาหาร".
nonisolated enum BasicPrescriptionParser {
    static func parse(_ text: String) -> [Medicine] {
        text.components(separatedBy: CharacterSet(charactersIn: "\n;"))
            .compactMap { parseLine($0) }
    }

    static func parseLine(_ rawLine: String) -> Medicine? {
        // Drop list markers like "-", "•", "1." or "2)".
        let line = rawLine
            .replacingOccurrences(of: #"^\s*([-•*]|\d+[.)])\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        let name = medicineName(in: line)
        guard !name.isEmpty else { return nil }

        let doseText = dose(in: line)
        let foundTimes = times(in: line)
        // Skip lines with no dose and no timing, like "Dr. Somchai Clinic".
        guard !doseText.isEmpty || foundTimes != nil else { return nil }

        return Medicine(name: name, dose: doseText, note: note(in: line), times: foundTimes ?? [DoseTime(hour: 8)])
    }

    // MARK: Name

    private static let leadingWords: Set<String> = ["take", "กิน", "ทาน"]
    private static let stopWords: Set<String> = [
        "tablet", "tablets", "tab", "tabs", "capsule", "capsules", "pill", "pills",
        "once", "twice", "every", "after", "before", "with", "at", "in", "daily", "x",
        "morning", "evening", "night", "bedtime", "-", "–", ":",
        "เม็ด", "วันละ", "ครั้งละ", "หลังอาหาร", "ก่อนอาหาร", "ก่อนนอน",
    ]

    /// The first few words, up to the first number or instruction word.
    static func medicineName(in line: String) -> String {
        var words: [String] = []
        for word in line.split(separator: " ") {
            let lower = word.lowercased()
            if words.isEmpty && leadingWords.contains(lower) { continue }
            if stopWords.contains(lower) { break }
            if let digit = word.firstIndex(where: { $0.isNumber }) {
                // "พาราเซตามอล500มก" → keep "พาราเซตามอล"
                let beforeNumber = String(word[..<digit])
                if !beforeNumber.isEmpty { words.append(beforeNumber) }
                break
            }
            words.append(String(word))
            if words.count == 3 { break }
        }
        let name = words.joined(separator: " ")
            .trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    // MARK: Dose

    static func dose(in line: String) -> String {
        let patterns = [
            #"\d+(\.\d+)?\s?(mcg|mg|ml|iu|g)(?![a-z])"#,
            #"\d+(\.\d+)?\s?(มก|มล)\.?"#,
            #"(\d+/\d+|\d+(\.\d+)?)\s?(tablets?|tabs?|capsules?|pills?|drops?|puffs?|teaspoons?|tsp|เม็ด|แคปซูล|ช้อนชา)"#,
        ]
        return patterns.compactMap { firstMatch($0, in: line) }.joined(separator: " · ")
    }

    // MARK: Note

    private static let notes: [(keyword: String, note: String)] = [
        ("after meal", "After meals"),
        ("after food", "After meals"),
        ("after breakfast", "After breakfast"),
        ("after dinner", "After dinner"),
        ("before breakfast", "Before breakfast"),
        ("before meal", "Before meals"),
        ("before food", "Before meals"),
        ("with food", "With food"),
        ("empty stomach", "On an empty stomach"),
        ("bedtime", "At bedtime"),
        ("หลังอาหาร", "หลังอาหาร · After meals"),
        ("ก่อนอาหาร", "ก่อนอาหาร · Before meals"),
        ("ก่อนนอน", "ก่อนนอน · At bedtime"),
    ]

    static func note(in line: String) -> String {
        let lower = line.lowercased()
        return notes.first { lower.contains($0.keyword) }?.note ?? ""
    }

    // MARK: Times

    private static let partsOfDay: [(keywords: [String], time: DoseTime)] = [
        (["morning", "breakfast", "เช้า"], DoseTime(hour: 8)),
        (["noon", "lunch", "midday", "กลางวัน", "เที่ยง"], DoseTime(hour: 12)),
        (["evening", "dinner", "เย็น"], DoseTime(hour: 18)),
        (["bedtime", "before bed", "night", "ก่อนนอน"], DoseTime(hour: 21)),
    ]

    /// nil when the line says nothing about when to take it.
    static func times(in line: String) -> [DoseTime]? {
        let lower = line.lowercased()

        let clock = clockTimes(in: lower)
        if !clock.isEmpty { return clock }

        let fromWords = partsOfDay
            .filter { part in part.keywords.contains { lower.contains($0) } }
            .map { $0.time }
        let perDay = timesPerDay(in: lower)

        if let perDay, fromWords.count < perDay { return defaultTimes(count: perDay) }
        if !fromWords.isEmpty { return fromWords }
        if let perDay { return defaultTimes(count: perDay) }
        return nil
    }

    /// "8:00", "20:30", "8:30 pm", "9am", "8.00 น."
    static func clockTimes(in lower: String) -> [DoseTime] {
        let patterns = [
            #"\b([01]?\d|2[0-3]):[0-5]\d(\s?(am|pm))?"#,
            #"\b(1[0-2]|0?[1-9])\s?(am|pm)\b"#,
            #"\b([01]?\d|2[0-3])\.[0-5]\d\s?น"#,
        ]
        var found = Set<DoseTime>()
        for pattern in patterns {
            for match in allMatches(pattern, in: lower) {
                let parts = numbers(in: match)
                guard var hour = parts.first else { continue }
                let minute = parts.count > 1 ? parts[1] : 0
                if match.contains("pm") && hour < 12 { hour += 12 }
                if match.contains("am") && hour == 12 { hour = 0 }
                found.insert(DoseTime(hour: hour, minute: minute))
            }
        }
        return found.sorted()
    }

    static func timesPerDay(in lower: String) -> Int? {
        if let match = firstMatch(#"every\s?\d+\s?(hours?|hrs?|h)\b"#, in: lower),
           let hours = numbers(in: match).first, hours > 0 {
            return max(1, 24 / hours)
        }
        if let match = firstMatch(#"\d+\s?(x|times)\b"#, in: lower) ?? firstMatch(#"วันละ\s?\d+"#, in: lower),
           let count = numbers(in: match).first, count > 0 {
            return count
        }
        if lower.contains("four times") { return 4 }
        if lower.contains("three times") || lower.contains("thrice") { return 3 }
        if lower.contains("twice") || lower.contains("two times") { return 2 }
        if lower.contains("once") || lower.contains("วันละครั้ง") || lower.contains("daily") { return 1 }
        return nil
    }

    /// Spreads the doses across waking hours.
    static func defaultTimes(count: Int) -> [DoseTime] {
        switch count {
        case ...1: return [DoseTime(hour: 8)]
        case 2: return [DoseTime(hour: 8), DoseTime(hour: 20)]
        case 3: return [DoseTime(hour: 8), DoseTime(hour: 13), DoseTime(hour: 18)]
        case 4: return [8, 12, 16, 20].map { DoseTime(hour: $0) }
        default:
            let n = min(count, 8)
            return (0..<n).map { DoseTime(hour: 6 + $0 * 16 / (n - 1)) }
        }
    }

    // MARK: Text helpers

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) else {
            return nil
        }
        return String(text[range])
    }

    private static func allMatches(_ pattern: String, in text: String) -> [String] {
        var results: [String] = []
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive], range: searchRange),
              !range.isEmpty {
            results.append(String(text[range]))
            searchRange = range.upperBound..<text.endIndex
        }
        return results
    }

    /// "8:30 pm" → [8, 30]
    private static func numbers(in text: String) -> [Int] {
        text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
    }
}
