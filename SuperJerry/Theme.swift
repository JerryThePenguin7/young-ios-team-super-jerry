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

    static let cornerRadius: CGFloat = 20
}
