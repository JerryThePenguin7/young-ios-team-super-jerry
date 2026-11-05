import Foundation

/// One medicine in Yao's name list (medicine-names.json).
nonisolated struct MedicineNameEntry: Codable, Hashable {
    /// Shown in the app, e.g. "MAWANG" or "Amlodipine".
    var name: String
    /// Other spellings and Thai names found on labels, e.g. "มะแว้ง", "ยาแก้ไอมะแว้ง".
    var aliases: [String]?
    /// A short, friendly Thai description, e.g. "ยาแก้ไอ ขับเสมหะ (สมุนไพร)". General categories only, not advice.
    var thai: String?
    /// How it's used, when every product with this name is the same (e.g. eye drops).
    var form: DosageForm?
    /// What it's for, so the home screen can group it.
    var group: MedicineGroup?

    var allNames: [String] { [name] + (aliases ?? []) }
}

/// A name found on the label, and how sure we are.
nonisolated struct NameMatch {
    var entry: MedicineNameEntry
    /// 0 = exactly as in the list; 1-2 = a letter or two different (OCR mistakes).
    var distance: Int
}

/// Yao's medicine name list: common medicines in Thai hospitals, Thai herbal medicines from the national list,
/// and eye drops, creams and inhalers. Matching it against the label finds names the rules can't
/// (e.g. "MAWANG", no "mg" printed) and fixes OCR spelling mistakes. Grow it with tools/tmt_to_medicine_names.py.
nonisolated enum MedicineNames {
    static let all: [MedicineNameEntry] = loadBundled()

    /// Latin names given to Vision as custom words, so it reads drug names more accurately.
    static let ocrWords: [String] = {
        var seen = Set<String>()
        var words: [String] = []
        for entry in all {
            for name in entry.allNames where !containsThai(name) && name.count >= 4 {
                if seen.insert(name.uppercased()).inserted { words.append(name) }
            }
        }
        return Array(words.prefix(3000))
    }()

    static func friendlyName(for name: String, in entries: [MedicineNameEntry] = all) -> String? {
        entry(named: name, in: entries)?.thai
    }

    /// The list entry with exactly this name or spelling.
    static func entry(named name: String, in entries: [MedicineNameEntry] = all) -> MedicineNameEntry? {
        let key = matchKey(name)
        guard !key.isEmpty else { return nil }
        return entries.first { entry in entry.allNames.contains { matchKey($0) == key } }
    }

    // MARK: Finding a name on the label

    /// The best name in `entries` that appears in the label text, allowing small OCR mistakes in Latin words.
    static func bestMatch(in lines: [String], entries: [MedicineNameEntry] = all) -> NameMatch? {
        let text = lines.joined(separator: "\n")
        let compactThai = thaiKey(text)
        let words = latinWords(text)
        let wordSet = Set(words)
        let joinedWords = " " + words.joined(separator: " ") + " "

        var best: (match: NameMatch, score: Int)?
        func consider(_ entry: MedicineNameEntry, distance: Int, length: Int) {
            // Exact beats fuzzy; longer names beat shorter ones ("ยาแก้ไอมะแว้ง" over "มะแว้ง").
            let score = (distance == 0 ? 10_000 : 5_000 - distance * 1_000) + length
            if score > (best?.score ?? Int.min) { best = (NameMatch(entry: entry, distance: distance), score) }
        }

        for entry in entries {
            for alias in entry.allNames {
                if containsThai(alias) {
                    let key = thaiKey(alias)
                    if key.count >= 4 && compactThai.contains(key) { consider(entry, distance: 0, length: key.count) }
                    continue
                }
                let aliasWords = latinWords(alias)
                guard let first = aliasWords.first else { continue }
                if aliasWords.count > 1 {
                    if joinedWords.contains(" \(aliasWords.joined(separator: " ")) ") {
                        consider(entry, distance: 0, length: alias.count)
                    }
                } else if first.count >= 3 {
                    // 3-letter names (FML, CPM, ORS) must match exactly; spelling tolerance needs 5+ letters.
                    if wordSet.contains(first) {
                        consider(entry, distance: 0, length: first.count)
                    } else if let distance = closestDistance(to: first, in: words) {
                        consider(entry, distance: distance, length: first.count)
                    }
                }
            }
        }
        return best?.match
    }

    /// Fixes the spelling of one name (e.g. "Amlodipme" → "Amlodipine"), or nil if it's not in the list.
    static func correct(_ name: String, entries: [MedicineNameEntry] = all) -> NameMatch? {
        bestMatch(in: [name], entries: entries)
    }

    /// Allows 1 wrong letter in 5-8 letter names, 2 in longer ones. Short names must match exactly.
    private static func closestDistance(to target: String, in words: [String]) -> Int? {
        let allowed = target.count >= 9 ? 2 : (target.count >= 5 ? 1 : 0)
        guard allowed > 0 else { return nil }
        var best: Int?
        for word in words where abs(word.count - target.count) <= allowed {
            let distance = levenshtein(word, target, limit: allowed)
            if distance <= allowed && distance < (best ?? Int.max) { best = distance }
        }
        return best
    }

    // MARK: Text helpers

    static func containsThai(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x0E00...0x0E7F).contains($0.value) }
    }

    /// Thai text with Thai digits fixed and all spaces removed (OCR adds random spaces in Thai).
    static func thaiKey(_ text: String) -> String {
        LabelParser.normalize(text).filter { !$0.isWhitespace }
    }

    /// Uppercase Latin words of 2+ letters, e.g. "Tears Naturale 15ml" → ["TEARS", "NATURALE", "ML"]
    static func latinWords(_ text: String) -> [String] {
        text.uppercased()
            .split { !($0.isASCII && $0.isLetter) }
            .map(String.init)
            .filter { $0.count >= 2 }
    }

    /// One key per name for exact lookups: Thai without spaces, or Latin words joined.
    static func matchKey(_ name: String) -> String {
        containsThai(name) ? thaiKey(name) : latinWords(name).joined(separator: " ")
    }

    /// Edit distance between two words, stopping early once it's over `limit`.
    static func levenshtein(_ a: String, _ b: String, limit: Int) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            var rowMin = current[0]
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                rowMin = min(rowMin, current[j])
            }
            if rowMin > limit { return limit + 1 }
            previous = current
        }
        return previous[b.count]
    }

    // MARK: Loading

    /// Reads medicine-names.json from the app. JENNY_MEDICINE_NAMES can point to the file when testing on a computer.
    private static func loadBundled() -> [MedicineNameEntry] {
        let url = Bundle.main.url(forResource: "medicine-names", withExtension: "json")
            ?? ProcessInfo.processInfo.environment["JENNY_MEDICINE_NAMES"].map { URL(fileURLWithPath: $0) }
        guard let url, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([MedicineNameEntry].self, from: data)) ?? []
    }
}
