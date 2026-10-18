import SwiftUI

/// Light (white) or dark (black) look, or follow the iPad's own setting.
/// Picked with the button at the top left of the home screen, or in Settings.
nonisolated enum AppAppearance: String, CaseIterable, Identifiable {
    case automatic, light, dark

    var id: String { rawValue }

    static let storageKey = "appAppearance"

    /// nil follows the device.
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func name(_ language: AppLanguage) -> String {
        switch self {
        case .automatic: language("อัตโนมัติ", "Automatic")
        case .light: language("สว่าง (พื้นขาว)", "Light (white)")
        case .dark: language("มืด (พื้นดำ)", "Dark (black)")
        }
    }

    var symbol: String {
        switch self {
        case .automatic: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
}
