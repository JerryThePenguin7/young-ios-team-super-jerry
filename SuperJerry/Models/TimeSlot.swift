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

    func name(_ language: AppLanguage) -> String {
        language(thai, english)
    }

    /// "ตอนเช้า", "ตอนกลางวัน", "ตอนเย็น", "ก่อนนอน"
    var spokenThai: String {
        self == .bedtime ? thai : "ตอน\(thai)"
    }

    /// For reading aloud: "ตอนเช้า" or "in the morning".
    func spoken(_ language: AppLanguage) -> String {
        switch (language, self) {
        case (.thai, _): spokenThai
        case (.english, .morning): "in the morning"
        case (.english, .noon): "at noon"
        case (.english, .evening): "in the evening"
        case (.english, .bedtime): "at bedtime"
        }
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
