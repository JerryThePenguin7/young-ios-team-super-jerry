import SwiftUI

@main struct MyApp: App {
    @State private var store = MedicineStore()
    /// Thai or English for the whole app. Changed in Settings or on the first tutorial page.
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.deviceDefault
    /// Light (white) or dark (black), or follow the device. Changed with the button at the top left.
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.automatic
    /// Text size for older eyes, or follow the device. Changed in Settings.
    @AppStorage(TextSize.storageKey) private var textSize = TextSize.system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(\.language, language)
                .environment(\.locale, language.locale)
                .preferredColorScheme(appearance.colorScheme)
                .dynamicTypeSize(textSize.range)
                .onChange(of: language) {
                    // Rewrite the reminders in the new language.
                    store.refreshReminders()
                }
        }
    }
}
