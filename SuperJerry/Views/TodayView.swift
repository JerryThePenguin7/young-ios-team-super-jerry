import SwiftUI

/// The first screen: today's doses, so the value shows up as soon as the app opens.
struct TodayView: View {
    @Environment(MedicineStore.self) private var store
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            // Redraws every minute so "Later" turns into "Time now" and then "Missed".
            TimelineView(.everyMinute) { context in
                content(now: context.date)
            }
            .background(Theme.background)
            .navigationTitle("Jenny")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Settings", systemImage: "gearshape") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private func content(now: Date) -> some View {
        let doses = store.doses(on: now, now: now)
        let takenCount = doses.filter { $0.status.isTaken }.count

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TodayHeaderCard(now: now, taken: takenCount, total: doses.count, message: jennySays(doses))

                if !store.remindersEnabled && !doses.isEmpty {
                    remindersButton
                }

                if doses.isEmpty {
                    ContentUnavailableView(
                        "No medicines yet",
                        systemImage: "pills",
                        description: Text("Open the Medicines tab and let Jenny read your prescription.")
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                        ForEach(doses) { dose in
                            DoseCard(dose: dose) {
                                withAnimation(.snappy) {
                                    store.toggleTaken(dose, on: now)
                                }
                            }
                        }
                    }
                }

                Label("Jenny is a reminder helper, not medical advice. Always follow your doctor or pharmacist.",
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .sensoryFeedback(.success, trigger: takenCount)
    }

    private var remindersButton: some View {
        Button {
            store.remindersEnabled = true
            Task { _ = await store.applyReminderSetting() }
        } label: {
            Label("Let Jenny remind me at pill times", systemImage: "bell.badge.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Theme.red)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.red, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }

    /// Jenny's nag, based on what's missed, due, or next.
    private func jennySays(_ doses: [ScheduledDose]) -> String {
        if doses.isEmpty {
            return "Add your medicines and I'll remind you when it's time."
        }
        let missed = doses.filter { $0.status == .missed }
        if let first = missed.first {
            if missed.count == 1 {
                return "You haven't taken \(first.medicine.name) from \(first.time.label) yet!"
            }
            return "You've missed \(missed.count) doses today, starting with \(first.medicine.name) at \(first.time.label)."
        }
        if let due = doses.first(where: { $0.status == .dueNow }) {
            return "It's time for \(due.medicine.name) now!"
        }
        if let next = doses.first(where: { $0.status == .upcoming }) {
            return "All caught up. Next: \(next.medicine.name) at \(next.time.label)."
        }
        return "All done for today. Great job!"
    }
}

#Preview("With medicines") {
    TodayView()
        .environment(MedicineStore(inMemory: true))
}

#Preview("Empty") {
    let store = MedicineStore(inMemory: true)
    store.eraseAll()
    return TodayView()
        .environment(store)
}
