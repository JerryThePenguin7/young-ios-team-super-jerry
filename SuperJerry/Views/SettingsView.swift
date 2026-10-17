import SwiftUI

/// Reminders, a test notification for the demo, sample data, and the disclaimer.
struct SettingsView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingNotificationsOffAlert = false
    @State private var showingEraseConfirmation = false
    @State private var showingSpikeTest = false
    @State private var testMessage: String?

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Toggle("Remind me at pill times", isOn: $store.remindersEnabled)
                    Button("Send a test reminder in 5 seconds", systemImage: "bell.badge") {
                        Task { await sendTest() }
                    }
                } header: {
                    Text("Jenny's reminders")
                } footer: {
                    Text(testMessage ?? "Jenny sends a notification at every pill time, every day.")
                }

                Section("Apple Intelligence") {
                    LabeledContent("On this device",
                                   value: PrescriptionReader.isAppleIntelligenceAvailable ? "Available" : "Not available")
                }

                Section {
                    Button("Load sample medicines", systemImage: "tray.and.arrow.down") {
                        store.loadSampleData()
                    }
                    Button("Erase all data", systemImage: "trash", role: .destructive) {
                        showingEraseConfirmation = true
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Sample medicines and history are made up. Don't enter real patient data.")
                }

                Section {
                    Button("Run the spike test", systemImage: "testtube.2") {
                        showingSpikeTest = true
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Temporary test from feature/pill-reader: what works on this device? Delete SuperJerry/Debug before submitting.")
                }

                Section("About") {
                    Text("Jenny is a prototype by Team Super Jerry for YIDH26. Jenny is a reminder helper, not medical advice. Always follow your doctor or pharmacist.")
                        .font(.callout)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: store.remindersEnabled) {
                Task { await applyReminders() }
            }
            .sheet(isPresented: $showingSpikeTest) {
                SpikeTestView()
            }
            .alert("Notifications are off", isPresented: $showingNotificationsOffAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Turn on notifications for this app in the Settings app so Jenny can remind you.")
            }
            .confirmationDialog("Erase all medicines and history?", isPresented: $showingEraseConfirmation,
                                titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) {
                    store.eraseAll()
                }
            }
        }
    }

    private func applyReminders() async {
        let allowed = await store.applyReminderSetting()
        if !allowed {
            showingNotificationsOffAlert = true
        }
    }

    private func sendTest() async {
        if await ReminderScheduler.sendTest(for: store.medicines.first) {
            testMessage = "Sent! Go to the Home Screen or lock the screen to see it."
        } else {
            showingNotificationsOffAlert = true
        }
    }
}

#Preview {
    SettingsView()
        .environment(MedicineStore(inMemory: true))
}
