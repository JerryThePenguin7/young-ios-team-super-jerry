import SwiftUI

@main struct MyApp: App {
    @State private var store = MedicineStore()
    /// Thai or English for the whole app. Changed in the globe menu or in Settings.
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.deviceDefault

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(\.language, language)
                .environment(\.locale, language.locale)
                .onChange(of: language) {
                    // Rewrite the reminders in the new language.
                    store.refreshReminders()
                }
        }
    }
}
