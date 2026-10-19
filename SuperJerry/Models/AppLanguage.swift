import SwiftUI

/// The app's language. Yao shows one language at a time: all Thai or all English, never both mixed.
/// Pick it in the globe menu on the home screen or in Settings.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case thai = "th"
    case english = "en"

    var id: String { rawValue }

    /// Picks the text for this language: `language("ถ่ายรูป", "Take photo")`.
    func callAsFunction(_ thai: String, _ english: String) -> String {
        self == .thai ? thai : english
    }

    /// The language's own name, for the language menu.
    var name: String {
        switch self {
        case .thai: "ภาษาไทย"
        case .english: "English"
        }
    }

    /// For dates and times: "18 ตุลาคม" or "October 18".
    var locale: Locale {
        switch self {
        case .thai: Locale(identifier: "th_TH")
        case .english: Locale(identifier: "en_US")
        }
    }

    /// The read-aloud voice.
    var voice: String {
        switch self {
        case .thai: "th-TH"
        case .english: "en-US"
        }
    }

    // MARK: Dates and times

    /// "3:16 PM" or "15:16 น."
    func time(_ date: Date) -> String {
        let text = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale))
        return self == .thai ? "\(text) น." : text
    }

    /// "Today, October 18" or "วันนี้ 18 ตุลาคม"; other days: "Friday, October 16" or "วันศุกร์ที่ 16 ตุลาคม".
    func dayTitle(_ day: Date, today: Date) -> String {
        let calendar = Calendar.current
        let date = day.formatted(.dateTime.month(.wide).day().locale(locale))
        let weekday = day.formatted(.dateTime.weekday(.wide).locale(locale))
        let offset = calendar.dateComponents([.day], from: calendar.startOfDay(for: today),
                                             to: calendar.startOfDay(for: day)).day ?? 0
        switch (self, offset) {
        case (.thai, 0): return "วันนี้ \(date)"
        case (.thai, -1): return "เมื่อวาน \(date)"
        case (.thai, 1): return "พรุ่งนี้ \(date)"
        case (.thai, _): return "\(weekday)ที่ \(date)"
        case (.english, 0): return "Today, \(date)"
        case (.english, -1): return "Yesterday, \(date)"
        case (.english, 1): return "Tomorrow, \(date)"
        case (.english, _): return "\(weekday), \(date)"
        }
    }

    /// "31 Dec 2027" or "31 ธ.ค. 2570" (Thai uses the Buddhist year, like Thai medicine labels).
    func date(_ date: Date) -> String {
        let calendar = Calendar(identifier: self == .thai ? .buddhist : .gregorian)
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale, calendar: calendar))
    }

    /// "October 2026" or "ตุลาคม 2569" (Buddhist year in Thai), for the month calendar.
    func month(_ date: Date) -> String {
        let calendar = Calendar(identifier: self == .thai ? .buddhist : .gregorian)
        let style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar)
        return date.formatted(style.month(.wide).year())
    }

    /// "Friday, September 23" or "วันศุกร์ที่ 23 กันยายน"
    func longDay(_ day: Date) -> String {
        let date = day.formatted(.dateTime.month(.wide).day().locale(locale))
        let weekday = day.formatted(.dateTime.weekday(.wide).locale(locale))
        return self == .thai ? "\(weekday)ที่ \(date)" : "\(weekday), \(date)"
    }

    /// "F" or "ศ", for the week strip.
    func weekdayLetter(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.narrow).locale(locale))
    }

    /// "Fri" or "ศ.", so each day in the week strip is easy to recognise.
    /// Thai uses the usual calendar abbreviations: the system's "short" Thai names are full words ("พฤหัส").
    func weekdayShort(_ day: Date) -> String {
        guard self == .thai else { return day.formatted(.dateTime.weekday(.abbreviated).locale(locale)) }
        let thai = ["อา.", "จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส."]
        return thai[Calendar.current.component(.weekday, from: day) - 1]
    }

    /// "1 hr. ago" or "1 ชม. ที่แล้ว"
    func timeAgo(_ date: Date, now: Date) -> String {
        if now.timeIntervalSince(date) < 60 { return self("เมื่อสักครู่", "Just now") }
        return date.formatted(Date.RelativeFormatStyle(presentation: .named, unitsStyle: .abbreviated, locale: locale))
    }

    static let storageKey = "appLanguage"

    /// Thai if the device is set to Thai, otherwise English. Used until the user picks one.
    static var deviceDefault: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("th") == true ? .thai : .english
    }

    /// The language the user picked. For code outside views, like Apple Reminders.
    static var current: AppLanguage {
        UserDefaults.standard.string(forKey: storageKey).flatMap(AppLanguage.init) ?? deviceDefault
    }
}

private nonisolated struct LanguageKey: EnvironmentKey {
    static let defaultValue = AppLanguage.thai
}

nonisolated extension EnvironmentValues {
    /// Every view reads the language from here: `@Environment(\.language) private var language`.
    var language: AppLanguage {
        get { self[LanguageKey.self] }
        set { self[LanguageKey.self] = newValue }
    }
}
