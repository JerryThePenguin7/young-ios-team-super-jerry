import SwiftUI

/// The AI feature: paste the prescription text, Jenny turns it into medicines with times.
struct AddWithJennyView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var isReading = false
    @State private var result: ReadResult?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                    Button("Use an example", systemImage: "doc.text") {
                        text = PrescriptionReader.example
                        result = nil
                    }
                } header: {
                    Text("Prescription instructions")
                } footer: {
                    Text("One medicine per line, e.g. \"Metformin 500mg 1 tablet twice a day after meals\". Use made-up examples only.")
                }

                Section {
                    Button {
                        Task { await read() }
                    } label: {
                        HStack {
                            if isReading {
                                ProgressView()
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isReading ? "Jenny is reading…" : "Let Jenny read it")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isReading)
                } footer: {
                    Text(PrescriptionReader.isAppleIntelligenceAvailable
                         ? "Uses Apple Intelligence on this device. Nothing is sent to the internet."
                         : "Apple Intelligence isn't available here, so Jenny uses her basic offline reader.")
                }

                if let result {
                    resultSection(result)
                }
            }
            .navigationTitle("Add with Jenny")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.add(result?.medicines ?? [])
                        dismiss()
                    }
                    .disabled((result?.medicines ?? []).isEmpty)
                }
            }
        }
    }

    private func resultSection(_ result: ReadResult) -> some View {
        Section {
            if result.medicines.isEmpty {
                Text("Jenny couldn't find a medicine. Try one medicine per line, with a dose or a time.")
                    .foregroundStyle(.secondary)
            }
            ForEach(result.medicines) { medicine in
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name)
                        .font(.headline)
                    if !medicine.details.isEmpty {
                        Text(medicine.details)
                            .foregroundStyle(.secondary)
                    }
                    Label(medicine.times.map(\.label).joined(separator: ", "), systemImage: "clock")
                        .foregroundStyle(Theme.red)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                for index in offsets.sorted(by: >) {
                    self.result?.medicines.remove(at: index)
                }
            }
        } header: {
            Text("Jenny found \(result.medicines.count)")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Label(result.source.label, systemImage: result.source.symbol)
                Text("Check these before adding. Swipe left to remove one. You can edit them later. Not medical advice.")
            }
        }
    }

    private func read() async {
        isReading = true
        result = await PrescriptionReader.read(text)
        isReading = false
    }
}

#Preview {
    AddWithJennyView()
        .environment(MedicineStore(inMemory: true))
}
