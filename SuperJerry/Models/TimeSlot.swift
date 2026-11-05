import Foundation

/// The 4 times of day printed on Thai medicine envelopes: เช้า, กลางวัน, เย็น, ก่อนนอน.
/// In the Log they are meals (มื้อเช้า, มื้อกลางวัน, มื้อเย็น) and bedtime, at the times the user eats (`MealTimes`).
nonisolated enum TimeSlot: String, CaseIterable, Codable, Hashable {
    case morning, noon, evening, bedtime

    /// As on the label: "เช้า", "กลางวัน", "เย็น", "ก่อนนอน".
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

    /// The Log's card titles: "มื้อเช้า", "มื้อกลางวัน", "มื้อเย็น", "ก่อนนอน" / "Breakfast", "Lunch", "Dinner", "Bedtime".
    func mealName(_ language: AppLanguage) -> String {
        switch self {
        case .morning: language("มื้อเช้า", "Breakfast")
        case .noon: language("มื้อกลางวัน", "Lunch")
        case .evening: language("มื้อเย็น", "Dinner")
        case .bedtime: language("ก่อนนอน", "Bedtime")
        }
    }

    /// The food itself, for "ก่อนอาหารเช้า" / "Before breakfast". Empty at bedtime.
    func foodName(_ language: AppLanguage) -> String {
        switch self {
        case .morning: language("อาหารเช้า", "breakfast")
        case .noon: language("อาหารกลางวัน", "lunch")
        case .evening: language("อาหารเย็น", "dinner")
        case .bedtime: ""
        }
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

    /// When the user eats this meal (or goes to bed). A medicine's own time is a little before or after it:
    /// see `Medicine.doseTime(for:)`.
    var mealTime: DoseTime { MealTimes.current.time(of: self) }

    var symbol: String {
        switch self {
        case .morning: "sunrise.fill"
        case .noon: "sun.max.fill"
        case .evening: "sunset.fill"
        case .bedtime: "moon.stars.fill"
        }
    }

    /// Older versions of Yao used fixed times (8:00, 12:00, 18:00, 21:00). Which slot was this hour?
    static func legacy(hour: Int) -> TimeSlot? {
        switch hour {
        case 8: .morning
        case 12: .noon
        case 18: .evening
        case 21: .bedtime
        default: nil
        }
    }
}
