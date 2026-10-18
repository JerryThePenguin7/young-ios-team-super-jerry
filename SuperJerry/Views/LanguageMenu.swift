import SwiftUI

/// The globe button: switch the whole app between ภาษาไทย and English.
struct LanguageMenu: View {
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.deviceDefault

    var body: some View {
        Menu {
            Picker(language("ภาษา", "Language"), selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.name).tag(option)
                }
            }
        } label: {
            Label(language("ภาษา", "Language"), systemImage: "globe")
        }
    }
}

#Preview {
    NavigationStack {
        Text("Jenny")
            .toolbar { LanguageMenu() }
    }
}
