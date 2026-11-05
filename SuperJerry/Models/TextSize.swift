import SwiftUI

/// How big Yao's text is, for older eyes. Picked in Settings. "ตามเครื่อง" follows the iPad's own
/// text size (Settings ▸ Display & Brightness ▸ Text Size); the others set it for Yao only.
/// The biggest sizes are capped where Yao's screens still fit (wrapping, never cut off).
nonisolated enum TextSize: String, CaseIterable, Identifiable {
    case system, normal, large, larger, extraLarge, largest

    var id: String { rawValue }

    static let storageKey = "textSize"

    /// The sizes the app may use. One size sets it; `system` follows the device, up to the biggest Yao supports.
    var range: ClosedRange<DynamicTypeSize> {
        switch self {
        case .system: .xSmall ... .accessibility3
        case .normal: .large ... .large
        case .large: .xLarge ... .xLarge
        case .larger: .xxxLarge ... .xxxLarge
        case .extraLarge: .accessibility1 ... .accessibility1
        case .largest: .accessibility2 ... .accessibility2
        }
    }

    func name(_ language: AppLanguage) -> String {
        switch self {
        case .system: language("ตามเครื่อง", "Same as iPad")
        case .normal: language("ปกติ", "Normal")
        case .large: language("ใหญ่", "Large")
        case .larger: language("ใหญ่มาก", "Larger")
        case .extraLarge: language("ใหญ่พิเศษ", "Extra large")
        case .largest: language("ใหญ่ที่สุด", "Largest")
        }
    }
}
