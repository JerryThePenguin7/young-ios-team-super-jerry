import Foundation

// These value types are `nonisolated` so they can be used anywhere,
// including by JSON saving (the app defaults to MainActor).

/// One saved medicine: what its envelope label says, plus the label's photo and scanned text.
nonisolated struct Medicine: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String            // "Metformin"
    var strength: String        // "500 mg"
    var amount: Double          // 1, 0.5, 2
    var unit: String            // "เม็ด"
    var slots: [TimeSlot]       // morning, noon, evening, bedtime
    var meal: String            // "หลังอาหาร", "ก่อนอาหาร", "พร้อมอาหาร", or ""
    var asNeeded: Bool          // "เมื่อมีอาการ": no fixed times
    var warnings: [String]
    var scannedText: String     // what the camera read, so family can compare it with the label
    var photoFile: String?      // photo of the label, kept on this device only
    var addedAt = Date()
    var route: String?          // how it's used: "หยอดตา", "ทาบาง ๆ", "สูด"… nil = by mouth
    var amountMax: Double?      // "ครั้งละ 1-2 เม็ด" → amount 1, amountMax 2
    var group: MedicineGroup?   // what it's for; nil until Jenny (or the AI) has grouped it
    var stock: Double?          // how many are left (shown on the medicine's screen); nil = not counted
    var stockFull: Double?      // how many there were at the last refill, for the bar
    var lowAt: Double?          // "Running low" at this many left, set by the user; nil = about a week's worth
    /// How to use it, word for word as printed on the label ("พ่นจมูก 2 ข้าง ข้างละ 2 ที").
    /// Shown and read aloud instead of Jenny's own summary, because a summary can drop something important.
    var labelDirections: String?
    var perSide: Bool?          // "ข้างละ 2 ที": the amount is for each side (each eye, ear or nostril)
    var expiresOn: Date?        // the expiry date printed on the label
    var hoursApart: Double?     // "ห่างกันอย่างน้อย 6 ชม.": the least time between "when needed" doses

    static let units = ["เม็ด", "แคปซูล", "หยด", "ช้อนชา", "ช้อนโต๊ะ", "ml", "ซอง", "พัฟ", "ที", "ครั้ง", "ยูนิต", ""]
    static let meals = ["", "ก่อนอาหาร", "หลังอาหาร", "พร้อมอาหาร"]
    static let routes = ["", "หยอดตา", "หยอดตาขวา", "หยอดตาซ้าย", "หยอดตาทั้ง 2 ข้าง", "หยอดหู", "หยอดหูทั้ง 2 ข้าง",
                         "หยอดจมูก", "หยอดจมูกทั้ง 2 ข้าง", "หยดใต้ลิ้น", "พ่นจมูก", "พ่นจมูกทั้ง 2 ข้าง", "สูด",
                         "ทาบาง ๆ", "อม", "เหน็บ", "ฉีด"]

    /// An empty medicine for typing one in by hand.
    static var blank: Medicine {
        Medicine(name: "", strength: "", amount: 1, unit: "เม็ด", slots: [.morning], meal: "",
                 asNeeded: false, warnings: [], scannedText: "", photoFile: nil)
    }

    /// The clock times Jenny reminds at, from the user's meal times. "When needed" medicines have none.
    var times: [DoseTime] { times(meals: .current) }

    func times(meals: MealTimes) -> [DoseTime] {
        asNeeded ? [] : orderedSlots.map { doseTime(for: $0, meals: meals) }
    }

    /// Where this medicine sits around the meal: "ก่อนอาหาร" → before. Bedtime isn't a meal, so it's just "at".
    func mealPart(at slot: TimeSlot) -> MealPart {
        slot == .bedtime ? .at : MealPart(meal: meal)
    }

    /// When to take it at this meal: ก่อนอาหาร 30 minutes before, หลังอาหาร 15 minutes after,
    /// otherwise at the meal (or at bedtime). Breakfast at 07:00 → 06:30 before, 07:15 after.
    func doseTime(for slot: TimeSlot, meals: MealTimes = .current) -> DoseTime {
        let mealTime = meals.time(of: slot)
        switch mealPart(at: slot) {
        case .before: return mealTime.adding(minutes: -MealTimes.minutesBefore)
        case .after: return mealTime.adding(minutes: MealTimes.minutesAfter)
        case .with, .at: return mealTime
        }
    }

    var orderedSlots: [TimeSlot] {
        TimeSlot.allCases.filter { slots.contains($0) }
    }

    /// "1", "ครึ่ง" (half), or "1-2"
    var amountText: String {
        let first = amount == 0.5 ? "ครึ่ง" : String(format: "%g", amount)
        if let amountMax, amountMax > amount { return "\(first)-\(String(format: "%g", amountMax))" }
        return first
    }

    /// Jenny's short summary: "ครั้งละ 1 เม็ด", "พ่นจมูกทั้ง 2 ข้าง ข้างละ 2 ที", or "ทาบาง ๆ" for creams (no count).
    /// When the label's own words are known (`labelDirections`), show those instead.
    var amountLine: String {
        guard !unit.isEmpty else { return route ?? "ใช้ตามแพทย์สั่ง" }
        let each = "\(perSide == true ? "ข้างละ" : "ครั้งละ") \(amountText) \(unit)"
        return route.map { "\($0) \(each)" } ?? each
    }

    /// How much is used each time, for counting what's left: "ข้างละ 2 ที" in both nostrils is 4.
    var unitsPerDose: Double {
        amount * (perSide == true ? 2 : 1)
    }

    /// The label's own words, if Jenny read them.
    var directions: String? {
        guard let labelDirections, !labelDirections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return labelDirections
    }

    var friendlyName: String? { MedicineNames.friendlyName(for: name) }

    var mealEnglish: String {
        switch meal {
        case "ก่อนอาหาร": "Before meals"
        case "หลังอาหาร": "After meals"
        case "พร้อมอาหาร": "With meals"
        default: ""
        }
    }

    /// What the Thai voice says. With the label's words: "ยา Otrivin. พ่นจมูก 2 ข้าง ข้างละ 2 ที วันละ 2 ครั้ง เช้า เย็น".
    /// Without them: "ยา Metformin. ยาเบาหวาน. กินครั้งละ 1 เม็ด. ตอนเช้า และตอนเย็น. หลังอาหาร"
    var spokenThai: String {
        var parts = ["ยา \(name.isEmpty ? "ไม่ทราบชื่อ" : name)"]
        if let friendlyName { parts.append(friendlyName) }
        if let directions {
            // Word for word, so nothing on the label is lost.
            parts += directions.split(whereSeparator: \.isNewline).map(String.init)
        } else {
            parts.append(route == nil && !unit.isEmpty ? "กิน\(amountLine)" : amountLine)
            if asNeeded {
                parts.append("เมื่อมีอาการ")
            } else if !orderedSlots.isEmpty {
                parts.append(orderedSlots.map(\.spokenThai).joined(separator: " และ"))
            }
            if let apart = apartText(.thai) { parts.append(apart) }
            if !meal.isEmpty { parts.append(meal) }
        }
        parts += cleanWarnings()
        return parts.joined(separator: ". ")
    }
}

/// A time of day, like 08:00 or 21:30.
nonisolated struct DoseTime: Codable, Hashable, Comparable {
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int = 0) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    var minutesFromMidnight: Int { hour * 60 + minute }

    /// 07:00 - 30 minutes = 06:30. Stays within the same day (never before 00:00 or after 23:59).
    func adding(minutes: Int) -> DoseTime {
        let total = min(max(minutesFromMidnight + minutes, 0), 23 * 60 + 59)
        return DoseTime(hour: total / 60, minute: total % 60)
    }

    static func < (lhs: DoseTime, rhs: DoseTime) -> Bool {
        lhs.minutesFromMidnight < rhs.minutesFromMidnight
    }

    func date(on day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    /// "8:00 AM" in English, "08:00 น." in Thai.
    func label(_ language: AppLanguage) -> String {
        language.time(date(on: Date()))
    }
}

/// What the user logged for one dose: taken or skipped, and when.
nonisolated struct DoseRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var medicineID: UUID
    var time: DoseTime
    /// Start of the day the dose belongs to.
    var day: Date
    /// When it was logged (the time it was taken).
    var takenAt: Date
    /// true = the user chose "Skipped". Optional so files saved by older versions still load.
    var skipped: Bool? = nil
    /// The meal this dose belongs to (nil for "when needed" doses). When meal times change, the tick moves with
    /// its meal instead of getting lost (`MedicineStore.setMealTimes`).
    var slot: TimeSlot? = nil

    var isSkipped: Bool { skipped == true }
}

/// What the user chooses in the log sheet.
nonisolated enum DoseLog: Hashable {
    case taken(at: Date)
    case skipped

    init(_ record: DoseRecord) {
        self = record.isSkipped ? .skipped : .taken(at: record.takenAt)
    }

    var isTaken: Bool {
        if case .taken = self { return true }
        return false
    }
}

nonisolated enum DoseStatus: Hashable {
    case taken(at: Date)
    case skipped
    case dueNow
    case missed
    case upcoming

    var isLogged: Bool {
        switch self {
        case .taken, .skipped: true
        default: false
        }
    }

    /// "Time to take" starts this many minutes before the dose.
    static let dueMinutesBefore = 30

    /// Due from 30 minutes before the time; missed once it's more than 60 minutes late.
    static func make(time: DoseTime, record: DoseRecord?, day: Date, now: Date) -> DoseStatus {
        if let record { return record.isSkipped ? .skipped : .taken(at: record.takenAt) }
        let minutesLate = now.timeIntervalSince(time.date(on: day)) / 60
        if minutesLate > 60 { return .missed }
        if minutesLate >= -Double(dueMinutesBefore) { return .dueNow }
        return .upcoming
    }

    /// Before "Time to take" (e.g. a dinner medicine ticked at 10:00): probably a slip of the finger, so Jenny asks first.
    static func isTooEarly(time: DoseTime, day: Date, now: Date) -> Bool {
        now.timeIntervalSince(time.date(on: day)) / 60 < -Double(dueMinutesBefore)
    }
}

/// The medicines to take at one time of day, e.g. 08:00: Amlodipine and Metformin.
nonisolated struct DoseSlot: Identifiable, Hashable {
    var time: DoseTime
    var medicines: [Medicine]

    var id: Int { time.minutesFromMidnight }
}

/// One meal in the Log ("มื้อเช้า", 07:00), with its medicines split by where they sit around the meal.
nonisolated struct MealSchedule: Identifiable, Hashable {
    var slot: TimeSlot
    /// When the user eats it (or goes to bed).
    var mealTime: DoseTime
    /// Before eating, with food, at the meal, after eating: only the ones with medicines, in that order.
    var parts: [MealPartSchedule]

    var id: TimeSlot { slot }
    var medicines: [Medicine] { parts.flatMap(\.medicines) }
}

/// The medicines due at one moment around a meal: "ก่อนอาหาร · 06:30".
nonisolated struct MealPartSchedule: Identifiable, Hashable {
    var part: MealPart
    /// When these medicines are due: 06:30 before a 07:00 breakfast.
    var time: DoseTime
    var medicines: [Medicine]

    var id: MealPart { part }
}

/// One logged dose, for the "Logged" card.
nonisolated struct LoggedDose: Identifiable, Hashable {
    var medicine: Medicine
    var record: DoseRecord

    var id: UUID { record.id }
}

/// Everything logged at one meal ("มื้อเช้า"), or one "when needed" time ("10:15").
nonisolated struct LoggedTime: Identifiable, Hashable {
    /// The earliest dose time in the group.
    var time: DoseTime
    var doses: [LoggedDose]
    /// The meal, or nil for "when needed" doses.
    var slot: TimeSlot? = nil

    var id: String { slot.map { "meal-\($0.rawValue)" } ?? "time-\(time.minutesFromMidnight)" }
    /// The latest log, for "1 hr ago".
    var loggedAt: Date { doses.map(\.record.takenAt).max() ?? Date() }
}
