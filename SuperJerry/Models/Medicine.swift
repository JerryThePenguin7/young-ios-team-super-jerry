import Foundation

// These value types are `nonisolated` so they can be used anywhere,
// including by Foundation Models and JSON saving (the app defaults to MainActor).

/// One medicine the user takes, and the times of day to take it.
nonisolated struct Medicine: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var dose: String
    var note: String
    var times: [DoseTime]

    /// "500 mg · 1 tablet — After meals", skipping the empty parts.
    var details: String {
        [dose, note].filter { !$0.isEmpty }.joined(separator: " — ")
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

    var periodName: String {
        switch hour {
        case ..<11: "Morning"
        case ..<15: "Afternoon"
        case ..<19: "Evening"
        default: "Night"
        }
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
    var medicineName: String
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

/// One medicine at one time on one day, shown as a card on the Today screen.
nonisolated struct ScheduledDose: Identifiable, Hashable {
    var medicine: Medicine
    var time: DoseTime
    var status: DoseStatus

    var id: String { "\(medicine.id.uuidString)-\(time.minutesFromMidnight)" }
}

/// How many doses were taken on one day, for the History screen.
nonisolated struct DaySummary: Identifiable, Hashable {
    var date: Date
    var taken: Int
    var total: Int

    var id: Date { date }

    var percent: Double {
        total == 0 ? 0 : Double(taken) / Double(total) * 100
    }
}
