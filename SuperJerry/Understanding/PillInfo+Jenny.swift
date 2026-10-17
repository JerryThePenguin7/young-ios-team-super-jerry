import Foundation

/// Connects the envelope reader (PillInfo from LabelParser) to Jenny's medicine list and Thai voice.
nonisolated extension PillInfo {
    var slots: [TimeSlot] {
        TimeSlot.allCases.filter { slot in
            switch slot {
            case .morning: morning
            case .noon: noon
            case .evening: evening
            case .bedtime: bedtime
            }
        }
    }

    /// "ครั้งละ 1 เม็ด" (1 tablet each time)
    var amountLine: String { "ครั้งละ \(amountText) \(unit)" }

    /// Nothing useful was read: a blurry photo, or not a medicine label.
    var isEmpty: Bool { drugName.isEmpty && !hasAnyTime && !asNeeded }

    /// One of Jenny's medicines. "When needed" medicines get no fixed times, so they don't nag.
    func makeMedicine() -> Medicine {
        var notes: [String] = []
        if !mealTiming.thai.isEmpty { notes.append(mealTiming.thai) }
        if asNeeded { notes.append("เมื่อมีอาการ") }
        notes += warnings

        return Medicine(
            name: drugName.isEmpty ? "ยา (ไม่ทราบชื่อ)" : drugName,
            dose: [strength, amountLine].filter { !$0.isEmpty }.joined(separator: " · "),
            note: notes.joined(separator: " · "),
            times: asNeeded ? [] : slots.map(\.time)
        )
    }

    /// What the Thai voice says, e.g. "ยา Metformin. ยาเบาหวาน. กินครั้งละ 1 เม็ด. ตอนเช้า และตอนเย็น. หลังอาหาร"
    var spokenThai: String {
        var parts = ["ยา \(drugName)"]
        if let friendly = DrugDictionary.friendlyName(for: drugName) { parts.append(friendly) }
        parts.append("กินครั้งละ \(amountText) \(unit)")
        if asNeeded {
            parts.append("เมื่อมีอาการ")
        } else if !slots.isEmpty {
            parts.append(slots.map { $0 == .bedtime ? "ก่อนนอน" : "ตอน\($0.thai)" }.joined(separator: " และ"))
        }
        if !mealTiming.thai.isEmpty { parts.append(mealTiming.thai) }
        parts += warnings
        return parts.joined(separator: ". ")
    }
}

nonisolated extension LabelParser {
    /// True when the label only said "วันละ 2 ครั้ง" (twice a day) without naming the times,
    /// so the parser had to guess them. The result card then asks the user to check.
    static func timesAreGuessed(in lines: [String]) -> Bool {
        let info = parse(lines)
        guard info.hasAnyTime else { return false }
        let compact = normalize(lines.joined(separator: "\n")).replacingOccurrences(of: " ", with: "")
        let latin = lines.joined(separator: "\n").lowercased().replacingOccurrences(of: ".", with: "")
        let namedTimes = ["เช้า", "กลางวัน", "เที่ยง", "เย็น", "ก่อนนอน"].contains { compact.contains($0) }
        return !namedTimes && !latin.contains(#/\bhs\b/#)
    }
}
