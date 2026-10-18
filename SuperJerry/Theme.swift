import SwiftUI

/// Jenny's design tokens. See DESIGN.md for when to use each one.
/// Colors have a light and a dark version in Assets.xcassets, so the app looks right in dark mode.
enum Theme {
    /// Brand red: the main action, card headers, icons, and the dose amount.
    static let red = Color("JennyRed")
    /// Filled red buttons and the camera card, with white text on top (darker in dark mode, so white stays readable).
    static let card = Color("JennyCard")
    /// Page background: Health-style light gray, or black in dark mode.
    static let background = Color("JennyBackground")
    /// Cards and rows: white, or dark gray in dark mode.
    static let surface = Color("JennySurface")

    /// A dose that was taken. Always shown with a checkmark, never color alone.
    static let taken = Color.green
    /// A late dose, or something to double-check.
    static let late = Color.orange

    /// Cards.
    static let cornerRadius: CGFloat = 20
    /// The camera card and big result cards.
    static let heroCornerRadius: CGFloat = 28
    /// Buttons and label photos.
    static let buttonCornerRadius: CGFloat = 16

    /// Space between cards on a page.
    static let sectionSpacing: CGFloat = 24
}
