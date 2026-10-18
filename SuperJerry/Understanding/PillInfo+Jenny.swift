import Foundation

/// Connects the label reader (PillInfo from LabelParser) to Jenny's saved medicines.
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

    /// Nothing useful was read: a blurry photo, or not a medicine label.
    var isEmpty: Bool { drugName.isEmpty && !hasAnyTime && !asNeeded }

    func makeMedicine(scannedText: String) -> Medicine {
        Medicine(
            name: drugName,
            strength: strength,
            amount: amountPerDose,
            unit: unit,
            slots: slots,
            meal: mealTiming.thai,
            asNeeded: asNeeded,
            warnings: warnings,
            scannedText: scannedText,
            photoFile: nil
        )
    }
}

nonisolated extension LabelParser {
    /// True when the label only said "วันละ 2 ครั้ง" (twice a day) without naming the times,
    /// so the parser had to guess them. The result screen then asks the user to check.
    static func timesAreGuessed(in lines: [String]) -> Bool {
        let info = parse(lines)
        guard info.hasAnyTime else { return false }
        let compact = normalize(lines.joined(separator: "\n")).replacingOccurrences(of: " ", with: "")
        let latin = lines.joined(separator: "\n").lowercased().replacingOccurrences(of: ".", with: "")
        let namedTimes = ["เช้า", "กลางวัน", "เที่ยง", "เย็น", "ก่อนนอน"].contains { compact.contains($0) }
        return !namedTimes && !latin.contains(#/\bhs\b/#)
    }
}
