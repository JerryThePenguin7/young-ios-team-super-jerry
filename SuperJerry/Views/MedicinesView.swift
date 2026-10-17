import SwiftUI

/// Every medicine the user takes. Add with Jenny (AI), add by hand, edit, or swipe to delete.
struct MedicinesView: View {
    @Environment(MedicineStore.self) private var store
    @State private var showingAddWithJenny = false
    @State private var editingMedicine: Medicine?
    @State private var editingIsNew = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    addWithJennyButton
                }
                .listRowBackground(Theme.card)

                Section("Your medicines") {
                    if store.medicines.isEmpty {
                        Text("No medicines yet. Tap \"Add with Jenny\" above.")
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
            .sheet(isPresented: $showingAddWithJenny) {
                AddWithJennyView()
            }
            .sheet(item: $editingMedicine) { medicine in
                MedicineEditorView(medicine: medicine, isNew: editingIsNew)
            }
        }
    }

    private var addWithJennyButton: some View {
        Button {
            showingAddWithJenny = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add with Jenny")
                        .font(.title3.bold())
                    Text("Type or paste the instructions from your prescription, and Jenny sets up the times.")
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
                Text(medicine.times.sorted().map(\.label).joined(separator: ", "))
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
