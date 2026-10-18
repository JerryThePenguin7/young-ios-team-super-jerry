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

    static let units = ["เม็ด", "แคปซูล", "ช้อนชา", "ช้อนโต๊ะ", "ซอง", "ml"]
    static let meals = ["", "ก่อนอาหาร", "หลังอาหาร", "พร้อมอาหาร"]

    /// An empty medicine for typing one in by hand.
    static var blank: Medicine {
        Medicine(name: "", strength: "", amount: 1, unit: "เม็ด", slots: [.morning], meal: "",
                 asNeeded: false, warnings: [], scannedText: "", photoFile: nil)
    }

    /// The clock times Jenny reminds at. "When needed" medicines have none.
    var times: [DoseTime] {
        asNeeded ? [] : orderedSlots.map(\.time)
    }

    var orderedSlots: [TimeSlot] {
        TimeSlot.allCases.filter { slots.contains($0) }
    }

    var amountText: String { amount == 0.5 ? "ครึ่ง" : String(format: "%g", amount) }

    /// "ครั้งละ 1 เม็ด" (1 tablet each time)
    var amountLine: String { "ครั้งละ \(amountText) \(unit)" }

    var friendlyName: String? { DrugDictionary.friendlyName(for: name) }

    var mealEnglish: String {
        switch meal {
        case "ก่อนอาหาร": "Before meals"
        case "หลังอาหาร": "After meals"
        case "พร้อมอาหาร": "With meals"
        default: ""
        }
    }

    /// What the Thai voice says, e.g. "ยา Metformin. ยาเบาหวาน. กินครั้งละ 1 เม็ด. ตอนเช้า และตอนเย็น. หลังอาหาร"
    var spokenThai: String {
        var parts = ["ยา \(name.isEmpty ? "ไม่ทราบชื่อ" : name)"]
        if let friendlyName { parts.append(friendlyName) }
        parts.append("กินครั้งละ \(amountText) \(unit)")
        if asNeeded {
            parts.append("เมื่อมีอาการ")
        } else if !orderedSlots.isEmpty {
            parts.append(orderedSlots.map(\.spokenThai).joined(separator: " และ"))
        }
        if !meal.isEmpty { parts.append(meal) }
        parts += warnings
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

    static func < (lhs: DoseTime, rhs: DoseTime) -> Bool {
        lhs.minutesFromMidnight < rhs.minutesFromMidnight
    }

    func date(on day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    /// "8:00 AM" or "08:00", following the device's settings.
    var label: String {
        date(on: Date()).formatted(date: .omitted, time: .shortened)
    }

    var periodSymbol: String {
        switch hour {
        case ..<11: "sunrise.fill"
        case ..<15: "sun.max.fill"
        case ..<19: "sunset.fill"
        default: "moon.stars.fill"
        }
    }
}

/// Proof that a dose was taken on a given day.
nonisolated struct DoseRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var medicineID: UUID
    var time: DoseTime
    /// Start of the day the dose belongs to.
    var day: Date
    var takenAt: Date
}

nonisolated enum DoseStatus: Hashable {
    case taken(at: Date)
    case dueNow
    case missed
    case upcoming

    var isTaken: Bool {
        if case .taken = self { return true }
        return false
    }

    /// Due from 30 minutes before the time; missed once it's more than 60 minutes late.
    static func make(time: DoseTime, takenAt: Date?, day: Date, now: Date) -> DoseStatus {
        if let takenAt { return .taken(at: takenAt) }
        let minutesLate = now.timeIntervalSince(time.date(on: day)) / 60
        if minutesLate > 60 { return .missed }
        if minutesLate >= -30 { return .dueNow }
        return .upcoming
    }
}

/// One medicine at one time today.
nonisolated struct ScheduledDose: Identifiable, Hashable {
    var medicine: Medicine
    var time: DoseTime
    var status: DoseStatus

    var id: String { "\(medicine.id.uuidString)-\(time.minutesFromMidnight)" }
}
