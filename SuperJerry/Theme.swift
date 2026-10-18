import SwiftUI

/// Jenny's red-and-white colors. Each has a light and a dark version in Assets.xcassets,
/// so the app still looks right in dark mode.
enum Theme {
    /// Buttons, icons, and red text.
    static let red = Color("JennyRed")
    /// Big red cards and filled buttons with white text on top (darker in dark mode, so white stays readable).
    static let card = Color("JennyCard")
    /// Page background: warm white (light) or near-black (dark).
    static let background = Color("JennyBackground")
    /// Cards and list rows: white (light) or dark red-gray (dark).
    static let surface = Color("JennySurface")

    static let cornerRadius: CGFloat = 20
}
