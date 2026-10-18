import SwiftUI

/// Jenny's colors. Each has a light and a dark version in Assets.xcassets, so the app still looks right in dark mode.
/// Neutral grays and white carry the layout; red is only the accent (see DESIGN.md).
enum Theme {
    /// Buttons, icons, and red text.
    static let red = Color("JennyRed")
    /// Big red cards and filled buttons with white text on top (darker in dark mode, so white stays readable).
    static let card = Color("JennyCard")
    /// Page background: light gray (light) or black (dark), like the Health app.
    static let background = Color("JennyBackground")
    /// Cards and list rows: white (light) or dark gray (dark).
    static let surface = Color("JennySurface")
    /// Soft gray fill for secondary buttons and icon circles on a card. Red text on it still passes contrast.
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
