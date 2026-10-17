import SwiftUI

@main struct MyApp: App {
    @State private var store = MedicineStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
