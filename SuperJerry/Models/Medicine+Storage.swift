import Foundation

/// Medicine Storage: how many are left. Jenny takes one dose off each time the user logs Taken,
/// and puts it back if they change their mind.
nonisolated extension Medicine {
    /// Creams and other medicines with no count can't be counted.
    var canCountStock: Bool { !unit.isEmpty }

    /// How much is used each day, or nil for "when needed" medicines.
    var usePerDay: Double? {
        guard !asNeeded, !times.isEmpty else { return nil }
        return amount * Double(times.count)
    }

    /// Whole days left at the usual dose.
    var daysLeft: Int? {
        guard let stock, let usePerDay, usePerDay > 0 else { return nil }
        return Int(max(stock, 0) / usePerDay)
    }

    /// A week or less left (or 3 doses or fewer for "when needed" medicines).
    var isLowStock: Bool {
        guard let stock else { return false }
        if let daysLeft { return daysLeft <= 7 }
        return stock <= amount * 3
    }

    /// From 0 (empty) to 1 (just refilled), for the bar.
    var stockFraction: Double {
        guard let stock, let stockFull, stockFull > 0 else { return 0 }
        return min(max(stock / stockFull, 0), 1)
    }

    /// "เหลือ 24 เม็ด" or "24 tablets left"
    func stockText(_ language: AppLanguage) -> String {
        guard let stock else { return language("ยังไม่ได้นับ", "Not counted") }
        let left = max(stock, 0)
        if left == 0 { return language("หมดแล้ว", "None left") }
        let number = String(format: "%g", left)
        return language("เหลือ \(number) \(unit)",
                        "\(number) \(Self.unitName(unit, .english, plural: left != 1)) left")
    }

    /// "พอใช้อีกประมาณ 12 วัน" or "About 12 days left"
    func daysLeftText(_ language: AppLanguage) -> String? {
        guard let daysLeft else { return nil }
        if daysLeft == 0 { return language("ไม่พอสำหรับวันนี้", "Not enough for today") }
        return language("พอใช้อีกประมาณ \(daysLeft) วัน", daysLeft == 1 ? "About 1 day left" : "About \(daysLeft) days left")
    }
}
