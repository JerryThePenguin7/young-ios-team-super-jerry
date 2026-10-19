import Foundation

/// When the user eats. Yao's pill times follow the meals instead of fixed clock times, because nobody eats
/// at the same time: ก่อนอาหาร is 30 minutes before the meal (the user can pick 10 to 60), หลังอาหาร 15 minutes after,
/// ก่อนนอน at bedtime. Set in the tutorial and in Settings, and saved on this device.
nonisolated struct MealTimes: Hashable {
    var breakfast = DoseTime(hour: 7)
    var lunch = DoseTime(hour: 12)
    var dinner = DoseTime(hour: 17, minute: 30)
    var bedtime = DoseTime(hour: 21)

    /// ก่อนอาหาร: this many minutes before the meal. Picked in Settings (`beforeChoices`).
    var minutesBefore = 30
    /// หลังอาหาร: this many minutes after the meal.
    static let minutesAfter = 15

    /// What Settings offers for ก่อนอาหาร. Most labels mean 15 to 30 minutes before eating.
    static let beforeChoices = [10, 15, 20, 30, 45, 60]

    func time(of slot: TimeSlot) -> DoseTime {
        switch slot {
        case .morning: breakfast
        case .noon: lunch
        case .evening: dinner
        case .bedtime: bedtime
        }
    }

    mutating func set(_ time: DoseTime, for slot: TimeSlot) {
        switch slot {
        case .morning: breakfast = time
        case .noon: lunch = time
        case .evening: dinner = time
        case .bedtime: bedtime = time
        }
    }

    // MARK: Saving

    /// The user's meal times, or the defaults (07:00, 12:00, 17:30, 21:00) until they set them.
    /// Kept as plain numbers (minutes after midnight), so reading them is quick: Yao reads them often.
    static var current: MealTimes {
        get {
            var meals = MealTimes()
            for slot in TimeSlot.allCases {
                if let minutes = UserDefaults.standard.object(forKey: key(for: slot)) as? Int {
                    meals.set(DoseTime(hour: minutes / 60, minute: minutes % 60), for: slot)
                }
            }
            if let minutes = UserDefaults.standard.object(forKey: beforeKey) as? Int, minutes > 0 {
                meals.minutesBefore = minutes
            }
            return meals
        }
        set {
            for slot in TimeSlot.allCases {
                UserDefaults.standard.set(newValue.time(of: slot).minutesFromMidnight, forKey: key(for: slot))
            }
            UserDefaults.standard.set(newValue.minutesBefore, forKey: beforeKey)
        }
    }

    private static func key(for slot: TimeSlot) -> String { "mealTime.\(slot.rawValue)" }
    private static let beforeKey = "mealTime.minutesBefore"
}

/// Where a dose sits around a meal, in the order the Log shows them:
/// before eating, with food, at the meal (the label doesn't say which), then after eating.
nonisolated enum MealPart: Int, CaseIterable, Hashable {
    case before, with, at, after

    /// From the label's words: "ก่อนอาหาร", "พร้อมอาหาร", "หลังอาหาร", or nothing.
    init(meal: String) {
        switch meal {
        case "ก่อนอาหาร": self = .before
        case "พร้อมอาหาร": self = .with
        case "หลังอาหาร": self = .after
        default: self = .at
        }
    }

    /// "ก่อนอาหาร" or "Before eating". nil at the meal itself (the meal's time says it all).
    func name(_ language: AppLanguage) -> String? {
        switch self {
        case .before: language("ก่อนอาหาร", "Before eating")
        case .with: language("พร้อมอาหาร", "With food")
        case .after: language("หลังอาหาร", "After eating")
        case .at: nil
        }
    }
}
