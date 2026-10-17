import Foundation
import FoundationModels

/// Who read the prescription. The UI shows this so users (and judges) know who answered.
nonisolated enum ReaderSource {
    case appleIntelligence
    case basicReader

    var label: String {
        switch self {
        case .appleIntelligence: "Read by Apple Intelligence, on this device"
        case .basicReader: "Read by Jenny's basic reader (offline rules)"
        }
    }

    var symbol: String {
        switch self {
        case .appleIntelligence: "sparkles"
        case .basicReader: "text.magnifyingglass"
        }
    }
}

struct ReadResult {
    var medicines: [Medicine]
    var source: ReaderSource
}

/// Turns typed or pasted medicine instructions into medicines with times.
/// Uses Foundation Models when Apple Intelligence is on; otherwise the basic reader.
enum PrescriptionReader {
    static let example = """
        Metformin 500mg 1 tablet twice a day after meals
        Amlodipine 5mg once a day in the morning
        Simvastatin 20mg at bedtime
        """

    static var isAppleIntelligenceAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static func read(_ text: String) async -> ReadResult {
        if isAppleIntelligenceAvailable {
            do {
                let medicines = try await readWithAppleIntelligence(text)
                if !medicines.isEmpty {
                    return ReadResult(medicines: medicines, source: .appleIntelligence)
                }
            } catch {
                // Guardrails, unsupported language (e.g. Thai), or the model is busy:
                // fall back to the basic reader below.
                print("Apple Intelligence couldn't read it: \(error)")
            }
        }
        return ReadResult(medicines: BasicPrescriptionParser.parse(text), source: .basicReader)
    }

    private static func readWithAppleIntelligence(_ text: String) async throws -> [Medicine] {
        let session = LanguageModelSession(instructions: """
            You turn medicine instructions into a simple schedule. For each medicine in the text, \
            give its name, the amount per dose, a short note, and the hours of the day to take it. \
            Only use what the text says. Do not add advice.
            """)
        let response = try await session.respond(to: text, generating: PrescriptionDraft.self)
        return response.content.medicines.compactMap { $0.medicine }
    }
}

// MARK: Shapes the on-device model fills in (@Generable = structured output)

@Generable
nonisolated struct PrescriptionDraft {
    @Guide(description: "Every medicine mentioned in the text, in order")
    var medicines: [MedicineDraft]
}

@Generable
nonisolated struct MedicineDraft {
    @Guide(description: "Medicine name only, for example Paracetamol")
    var name: String

    @Guide(description: "Amount per dose, for example '500 mg · 1 tablet'. Empty if not given")
    var dose: String

    @Guide(description: "Short instruction, for example 'After meals'. Empty if not given")
    var note: String

    @Guide(description: "Hours of the day to take it, 24-hour clock from 0 to 23. Morning is 8, noon is 12, evening is 18, bedtime is 21. Twice a day is 8 and 20")
    var hours: [Int]
}

extension MedicineDraft {
    /// Cleans up what the model wrote and turns it into a Medicine.
    var medicine: Medicine? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return nil }
        let times = Set(hours.map { DoseTime(hour: $0) }).sorted()
        return Medicine(
            name: cleanName,
            dose: dose.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            times: times.isEmpty ? [DoseTime(hour: 8)] : times
        )
    }
}
