import SwiftUI

/// The button at the top left: switch Yao between a light (white) and a dark (black) look,
/// or follow the iPad's own setting.
struct AppearanceMenu: View {
    @Environment(\.language) private var language
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.automatic

    var body: some View {
        Menu {
            Picker(language("ธีม", "Theme"), selection: $appearance) {
                ForEach(AppAppearance.allCases) { option in
                    Label(option.name(language), systemImage: option.symbol).tag(option)
                }
            }
        } label: {
            Label(language("ธีมสว่างหรือมืด", "Light or dark theme"), systemImage: appearance.symbol)
        }
    }
}

#Preview {
    NavigationStack {
        Text("YaoYao")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { AppearanceMenu() }
            }
    }
}
