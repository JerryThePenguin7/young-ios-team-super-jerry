import SwiftUI

/// Every medicine the user takes. Add with Jenny (AI), add by hand, edit, or swipe to delete.
struct MedicinesView: View {
    @Environment(MedicineStore.self) private var store
    @State private var showingScan = false
    @State private var showingAddWithJenny = false
    @State private var editingMedicine: Medicine?
    @State private var editingIsNew = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    redRow(title: "Scan an envelope",
                           subtitle: "Take a photo of a Thai medicine envelope. Jenny reads it on this device.",
                           symbol: "camera.viewfinder") {
                        showingScan = true
                    }
                    redRow(title: "Add with Jenny",
                           subtitle: "Type or paste the instructions from your prescription, and Jenny sets up the times.",
                           symbol: "sparkles") {
                        showingAddWithJenny = true
                    }
                }
                .listRowBackground(Theme.card)

                Section("Your medicines") {
                    if store.medicines.isEmpty {
                        Text("No medicines yet. Scan an envelope above.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.medicines) { medicine in
                        Button {
                            editingIsNew = false
                            editingMedicine = medicine
                        } label: {
                            row(for: medicine)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Medicines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add by hand", systemImage: "plus") {
                        editingIsNew = true
                        editingMedicine = Medicine(name: "", dose: "", note: "", times: [DoseTime(hour: 8)])
                    }
                }
            }
            .sheet(isPresented: $showingScan) {
                ScanView()
            }
            .sheet(isPresented: $showingAddWithJenny) {
                AddWithJennyView()
            }
            .sheet(item: $editingMedicine) { medicine in
                MedicineEditorView(medicine: medicine, isNew: editingIsNew)
            }
        }
    }

    private func redRow(title: String, subtitle: String, symbol: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.title)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .opacity(0.9)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func row(for medicine: Medicine) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "pills.fill")
                .font(.title2)
                .foregroundStyle(Theme.red)
                .frame(width: 44, height: 44)
                .background(Theme.red.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name)
                    .font(.headline)
                if !medicine.details.isEmpty {
                    Text(medicine.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(medicine.times.isEmpty
                     ? "When needed · เมื่อมีอาการ"
                     : medicine.times.sorted().map(\.label).joined(separator: ", "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.red)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    MedicinesView()
        .environment(MedicineStore(inMemory: true))
}
