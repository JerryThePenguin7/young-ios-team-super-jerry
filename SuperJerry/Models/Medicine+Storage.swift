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

    /// "Running low" at this many left: the user's own number, or else about a week's worth
    /// (3 doses for "when needed" medicines).
    var lowStockLevel: Double {
        if let lowAt { return lowAt }
        if let usePerDay { return usePerDay * 7 }
        return amount * 3
    }

    var isLowStock: Bool {
        guard let stock else { return false }
        return stock <= lowStockLevel
    }

    /// "เตือนเมื่อเหลือ 10 เม็ด" or "Warns at 10 tablets left"
    func lowLevelText(_ language: AppLanguage) -> String {
        let level = lowStockLevel.rounded(.up)
        let number = String(format: "%g", level)
        return language("เตือนเมื่อเหลือ \(number) \(unit)",
                        "Warns at \(number) \(Self.unitName(unit, .english, plural: level != 1)) left")
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
