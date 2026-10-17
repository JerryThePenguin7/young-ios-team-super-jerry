import SwiftUI

/// The app's tabs. On iPhone they sit at the bottom; on iPad they can turn into a sidebar.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "pills.fill") {
                TodayView()
            }
            Tab("Medicines", systemImage: "cross.case.fill") {
                MedicinesView()
            }
            Tab("History", systemImage: "chart.bar.fill") {
                HistoryView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(Theme.red)
    }
}

#Preview {
    ContentView()
        .environment(MedicineStore(inMemory: true))
}
