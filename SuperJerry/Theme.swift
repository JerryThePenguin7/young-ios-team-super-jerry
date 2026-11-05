import SwiftUI

/// Yao's colors. Each has a light and a dark version in Assets.xcassets, so the app still looks right in dark mode.
/// Green first, with red and yellow as small accents (the team's reference: a Thai public-health app's green, red and yellow).
/// Neutral gray-blue and white carry the layout (see DESIGN.md). Every text color passes WCAG AA (4.5:1) on its background.
enum Theme {
    /// The main color: buttons, icons, links, and green text. A deep green, readable on white and on `fill`.
    static let accent = Color("JennyAccent")
    /// Filled buttons and big colored areas with white text on top (the chosen tab, the scan button, pill icons).
    static let accentFill = Color("JennyAccentFill")
    /// Red, only for things that need care: Skipped, expired, delete.
    static let red = Color("JennyRed")
    /// The filled "Skipped" button, with white text on top.
    static let redFill = Color("JennyRedFill")
    /// Yellow, only behind text ("Time to take"): dark text in light mode, white in dark mode. Never yellow text.
    static let yellow = Color("JennyYellow")
    /// Page background: light gray-blue (light) or black (dark), like the Health app.
    static let background = Color("JennyBackground")
    /// Cards and list rows: white (light) or dark gray (dark).
    static let surface = Color("JennySurface")
    /// Soft gray-blue fill for secondary buttons and icon circles on a card. Green or red text on it still passes contrast.
    static let fill = Color("JennyFill")
    /// "Taken": the ✓ marks, green text, and the week circles (brighter in dark mode, so it stays readable).
    static let green = Color("JennyGreen")
    /// The filled "Taken" button, with white text on top.
    static let greenFill = Color("JennyGreenFill")

    static let cornerRadius: CGFloat = 20

    /// Corner radii, so every card and button matches. Always use `style: .continuous`.
    enum Radius {
        /// Buttons, chips and small boxes.
        static let button: CGFloat = 16
        /// Cards: Log, Logged, medicines, storage, sheets' rows.
        static let card: CGFloat = 24
        /// The big red box and the scan result.
        static let hero: CGFloat = 28
    }

    /// Round icon buttons (+, pencil, speaker): one size everywhere, bigger than Apple's 44 pt minimum for older hands.
    static let iconButton: CGFloat = 48
    /// Space inside cards.
    static let cardPadding: CGFloat = 20
}
