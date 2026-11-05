import Foundation

/// Helpers on the Thai rules' result, used by LabelReader.
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
}

nonisolated extension LabelParser {
    /// True when the label only said "วันละ 2 ครั้ง" (twice a day) without naming the times,
    /// so the parser had to guess them. The result screen then asks the user to check.
    static func timesAreGuessed(in lines: [String]) -> Bool {
        let info = parse(lines)
        guard info.hasAnyTime else { return false }
        let compact = normalize(lines.joined(separator: "\n")).replacingOccurrences(of: " ", with: "")
        let latin = lines.joined(separator: "\n").lowercased().replacingOccurrences(of: ".", with: "")
        let namedTimes = ["เช้า", "กลางวัน", "เที่ยง", "เย็น", "ก่อนนอน", "ก่อนเข้านอน"].contains { compact.contains($0) }
        return !namedTimes && !latin.contains(#/\bhs\b/#)
    }
}
