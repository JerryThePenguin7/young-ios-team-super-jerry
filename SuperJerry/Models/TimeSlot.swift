import Foundation

/// The 4 times of day printed on Thai medicine envelopes, and the clock time Jenny uses for each.
nonisolated enum TimeSlot: String, CaseIterable, Codable, Hashable {
    case morning, noon, evening, bedtime

    var thai: String {
        switch self {
        case .morning: "เช้า"
        case .noon: "กลางวัน"
        case .evening: "เย็น"
        case .bedtime: "ก่อนนอน"
        }
    }

    var english: String {
        switch self {
        case .morning: "Morning"
        case .noon: "Noon"
        case .evening: "Evening"
        case .bedtime: "Bedtime"
        }
    }

    /// "ตอนเช้า", "ตอนกลางวัน", "ตอนเย็น", "ก่อนนอน"
    var spokenThai: String {
        self == .bedtime ? thai : "ตอน\(thai)"
    }

    var time: DoseTime {
        switch self {
        case .morning: DoseTime(hour: 8)
        case .noon: DoseTime(hour: 12)
        case .evening: DoseTime(hour: 18)
        case .bedtime: DoseTime(hour: 21)
        }
    }

    var symbol: String { time.periodSymbol }

    /// The slot that reminds at this clock time, if any.
    static func at(_ time: DoseTime) -> TimeSlot? {
        allCases.first { $0.time == time }
    }
}
