import Foundation
import FoundationModels
#if compiler(>=6.4) && canImport(CoreAILanguageModels)
import CoreAILanguageModels
#endif

/// Groups medicines Jenny doesn't know (not in the name list, no clue from how they're used).
/// 1. Core AI (iOS 27): Qwen3 0.6B running on the iPad, once the team adds it (see README).
/// 2. Apple Intelligence (Foundation Models) for English names; it can't read Thai.
/// 3. Otherwise nil, and the medicine shows under "อื่น ๆ · Other" (the user can change it).
/// Called once per new medicine, never in a loop.
enum MedicineGrouper {
    static func group(for medicine: Medicine) async -> (group: MedicineGroup, source: GroupSource)? {
        #if compiler(>=6.4) && canImport(CoreAILanguageModels)
        if #available(iOS 27, *), let group = await CoreAIGrouper.shared.group(for: medicine) {
            return (group, .coreAI)
        }
        #endif
        if let group = await askAppleIntelligence(medicine) {
            return (group, .appleIntelligence)
        }
        return nil
    }

    static let instructions = """
        You sort medicines into groups so an older person can find them in a list. \
        Pick the single best group for the medicine. If you don't know the medicine, pick other. \
        Only sort it. Do not give medical advice.
        """

    static func prompt(for medicine: Medicine) -> String {
        var text = "Medicine name: \(medicine.name)"
        if !medicine.strength.isEmpty { text += " \(medicine.strength)" }
        if let friendly = medicine.friendlyName { text += "\nKnown use (Thai): \(friendly)" }
        return text
    }

    private static func askAppleIntelligence(_ medicine: Medicine) async -> MedicineGroup? {
        guard case .available = SystemLanguageModel.default.availability,
              !medicine.name.isEmpty, !MedicineNames.containsThai(medicine.name) else { return nil }
        let session = LanguageModelSession(instructions: instructions)
        do {
            return try await session.respond(to: prompt(for: medicine), generating: GroupAnswer.self).content.group.medicineGroup
        } catch {
            return nil   // e.g. the safety filter refused, or the model is busy
        }
    }
}

// MARK: The shape the AI fills in (@Generable = structured output)

@Generable
nonisolated enum GroupChoice {
    case heart, diabetes, cholesterol, stomach, pain, infection, breathing, brain
    case eyesEars, skin, vitamins, hormones, bonesJoints, urinary, herbal, other
}

@Generable
nonisolated struct GroupAnswer {
    @Guide(description: "heart = heart, blood pressure, blood thinners; brain = sleep, mood, nerves, dizziness; eyesEars = eye or ear drops; herbal = Thai traditional or herbal medicine")
    var group: GroupChoice
}

nonisolated extension GroupChoice {
    var medicineGroup: MedicineGroup {
        switch self {
        case .heart: .heart
        case .diabetes: .diabetes
        case .cholesterol: .cholesterol
        case .stomach: .stomach
        case .pain: .pain
        case .infection: .infection
        case .breathing: .breathing
        case .brain: .brain
        case .eyesEars: .eyesEars
        case .skin: .skin
        case .vitamins: .vitamins
        case .hormones: .hormones
        case .bonesJoints: .bonesJoints
        case .urinary: .urinary
        case .herbal: .herbal
        case .other: .other
        }
    }
}

// MARK: Core AI (iOS 27 only)

#if compiler(>=6.4) && canImport(CoreAILanguageModels)
/// Core AI: Qwen3 0.6B on the device (YIDH26 handbook, workshop 3). Needs Xcode 27, iOS 27, the
/// apple/coreai-models package (CoreAILM), the model folder from a TA in the app, and Increased Memory Limit.
/// If the model folder isn't in the app, this quietly returns nil.
@available(iOS 27, *)
final class CoreAIGrouper {
    static let shared = CoreAIGrouper()
    static let modelFolderName = "qwen3_0_6b_mixed_4bit_8bit_static"

    private var model: CoreAILanguageModel?
    private var couldNotLoad = false

    func group(for medicine: Medicine) async -> MedicineGroup? {
        guard let model = await loadModel() else { return nil }
        let session = LanguageModelSession(model: model, instructions: MedicineGrouper.instructions)
        do {
            return try await session.respond(to: MedicineGrouper.prompt(for: medicine), generating: GroupAnswer.self)
                .content.group.medicineGroup
        } catch {
            return nil
        }
    }

    /// Loads the model once and reuses it. The first load is slow while Core AI prepares it.
    private func loadModel() async -> CoreAILanguageModel? {
        if let model { return model }
        guard !couldNotLoad,
              let folder = Bundle.main.url(forResource: Self.modelFolderName, withExtension: nil) else {
            couldNotLoad = true
            return nil
        }
        do {
            let loaded = try await CoreAILanguageModel(resourcesAt: folder)
            model = loaded
            return loaded
        } catch {
            couldNotLoad = true
            return nil
        }
    }
}
#endif
