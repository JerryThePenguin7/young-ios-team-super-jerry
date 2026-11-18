// Scores Jenny's label reader on the fake envelopes from make-envelopes.
// It is compiled together with the app's own reader files (see run.sh), so it tests the real code:
// the same Vision settings as Reading/TextReader.swift, then LabelReader.read(...).
//
// Each envelope is read twice:
//   - "Perfect text": the printed lines exactly. Wrong here = the reader's rules need fixing.
//   - "Photo": Vision OCR on the damaged photo. Wrong here only = the OCR misread the photo.
//
// Usage: score-envelopes <envelope-folder> [report.md]

import Foundation
import ImageIO
import Vision

// MARK: Envelope files (same shape as MakeEnvelopes)

struct Answer: Codable, Sendable {
    var name: String
    var strength: String
    var amount: Double
    var amountMax: Double?
    var unit: String
    var slots: [String]
    var meal: String
    var asNeeded: Bool
    var warnings: [String]
    var route: String?
    var timesPrinted: Bool
}

struct Envelope: Codable, Sendable {
    var id: String
    var image: String
    var difficulty: String
    var font: String
    var lines: [String]
    var answer: Answer
}

// MARK: Reading a photo, like the app does

func readText(at url: URL) async throws -> [String] {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return [] }
    var request = RecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["th", "en"].compactMap { code in
        request.supportedRecognitionLanguages.first { $0.languageCode?.identifier == code }
    }
    request.customWords = MedicineNames.ocrWords
    return try await request.perform(on: image).map(\.transcript)
}

// MARK: Checking one reading against the answer

let fields = ["Name", "Strength", "Amount", "Unit", "Times", "Meal", "As needed", "Use (route)", "Warnings"]

/// One result per field: true = right, false = wrong, nil = doesn't apply to this envelope.
func check(_ reading: LabelReading?, against answer: Answer) -> [Bool?] {
    guard let medicine = reading?.medicine else {
        // Jenny said "this isn't a medicine label".
        return [false, false, answer.unit.isEmpty ? nil : false, false, false, false, false, false,
                answer.warnings.isEmpty ? nil : false]
    }
    return [
        MedicineNames.matchKey(medicine.name) == MedicineNames.matchKey(answer.name),
        squash(medicine.strength) == squash(answer.strength),
        answer.unit.isEmpty ? nil : (medicine.amount == answer.amount && medicine.amountMax == answer.amountMax),
        medicine.unit == answer.unit,
        Set(medicine.slots.map(\.rawValue)) == Set(answer.slots),
        medicine.meal == answer.meal,
        medicine.asNeeded == answer.asNeeded,
        medicine.route == answer.route,
        answer.warnings.isEmpty ? nil : answer.warnings.allSatisfy { warning in
            // Found = one of Jenny's warning lines matches it, with at most 15% of the letters wrong.
            // "คำเตือน:" in front is fine: some labels print it.
            medicine.warnings.contains { line in
                let text = line.replacingOccurrences(of: "คำเตือน:", with: "")
                return characterErrorRate(truth: [warning], read: [text]) <= 0.15
            }
        },
    ]
}

/// "500 MG" and "500mg" count as the same.
func squash(_ text: String) -> String {
    text.lowercased().filter { !$0.isWhitespace }
}

/// What Jenny read for one field, for the report.
func shown(_ field: String, _ reading: LabelReading?) -> String {
    guard let medicine = reading?.medicine else { return "(not a label)" }
    switch field {
    case "Name": return medicine.name
    case "Strength": return medicine.strength
    case "Amount": return medicine.amountText
    case "Unit": return medicine.unit
    case "Times": return medicine.orderedSlots.map(\.rawValue).joined(separator: "+")
    case "Meal": return medicine.meal
    case "As needed": return String(medicine.asNeeded)
    case "Use (route)": return medicine.route ?? "by mouth"
    default: return medicine.warnings.joined(separator: " / ")
    }
}

func expected(_ field: String, _ answer: Answer) -> String {
    switch field {
    case "Name": return answer.name
    case "Strength": return answer.strength
    case "Amount": return answer.amountMax.map { "\(fmt(answer.amount))-\(fmt($0))" } ?? fmt(answer.amount)
    case "Unit": return answer.unit
    case "Times": return answer.slots.joined(separator: "+")
    case "Meal": return answer.meal
    case "As needed": return String(answer.asNeeded)
    case "Use (route)": return answer.route ?? "by mouth"
    default: return answer.warnings.joined(separator: " / ")
    }
}

func fmt(_ value: Double) -> String { String(format: "%g", value) }

// MARK: OCR character error rate

/// Characters the OCR got wrong, out of all printed characters (spaces ignored, Thai digits = 0-9).
func characterErrorRate(truth: [String], read: [String]) -> Double {
    func clean(_ lines: [String]) -> [Unicode.Scalar] {
        Array(MedicineNames.thaiKey(lines.joined()).precomposedStringWithCanonicalMapping.unicodeScalars)
    }
    let a = clean(truth), b = clean(read)
    guard !a.isEmpty else { return 0 }
    var previous = Array(0...b.count)
    for i in 1...a.count {
        var current = [i] + Array(repeating: 0, count: b.count)
        for j in stride(from: 1, through: b.count, by: 1) {
            current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
        }
        previous = current
    }
    return Double(previous[b.count]) / Double(a.count)
}

// MARK: Scoring everything

struct Result: Sendable {
    var envelope: Envelope
    var ocrLines: [String]
    var perfect: [Bool?]
    var photo: [Bool?]
    var perfectShown: [String]
    var photoShown: [String]
    var cer: Double
}

func score(_ envelope: Envelope, folder: URL) async -> Result {
    let ocrLines = (try? await readText(at: folder.appendingPathComponent(envelope.image))) ?? []
    let perfectReading = LabelReader.read(envelope.lines)
    let photoReading = LabelReader.read(ocrLines)
    return Result(envelope: envelope, ocrLines: ocrLines,
                  perfect: check(perfectReading, against: envelope.answer),
                  photo: check(photoReading, against: envelope.answer),
                  perfectShown: fields.map { shown($0, perfectReading) },
                  photoShown: fields.map { shown($0, photoReading) },
                  cer: characterErrorRate(truth: envelope.lines, read: ocrLines))
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("usage: score-envelopes <envelope-folder> [report.md]")
    exit(1)
}
let folder = URL(fileURLWithPath: arguments[1])
let reportURL = URL(fileURLWithPath: arguments.count > 2 ? arguments[2] : folder.appendingPathComponent("report.md").path)

guard !MedicineNames.all.isEmpty else {
    print("Jenny's medicine name list didn't load. Set JENNY_MEDICINE_NAMES to SuperJerry/Understanding/medicine-names.json")
    exit(1)
}
let thaiCheck = RecognizeTextRequest()
guard thaiCheck.supportedRecognitionLanguages.contains(where: { $0.languageCode?.identifier == "th" }) else {
    print("This Mac's Vision can't read Thai, so the photo test can't run here. Try the M-chip Mac.")
    exit(1)
}

let decoder = JSONDecoder()
let envelopes = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "json" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
    .compactMap { try? decoder.decode(Envelope.self, from: Data(contentsOf: $0)) }
guard !envelopes.isEmpty else {
    print("No envelopes in \(folder.path). Run make-envelopes first.")
    exit(1)
}

print("Reading \(envelopes.count) fake envelopes with Vision…")
var results: [Result] = []
let batchSize = 6
for start in stride(from: 0, to: envelopes.count, by: batchSize) {
    let batch = Array(envelopes[start..<min(start + batchSize, envelopes.count)])
    let done = await withTaskGroup(of: Result.self) { group in
        for envelope in batch { group.addTask { await score(envelope, folder: folder) } }
        var out: [Result] = []
        for await result in group { out.append(result) }
        return out
    }
    results += done
    print("  \(results.count)/\(envelopes.count)", terminator: "\r")
    fflush(stdout)
}
results.sort { $0.envelope.id < $1.envelope.id }
print("")

// MARK: Report

func percent(_ checks: [Bool?]) -> String {
    let applicable = checks.compactMap { $0 }
    guard !applicable.isEmpty else { return "  -  " }
    let value = Double(applicable.filter { $0 }.count) / Double(applicable.count) * 100
    return String(format: "%5.1f%%", value)
}

func allRight(_ checks: [Bool?]) -> Bool { checks.allSatisfy { $0 != false } }

func pad(_ text: String, _ width: Int) -> String {
    text.count >= width ? text : text + String(repeating: " ", count: width - text.count)
}

var summary: [String] = []
summary.append("Jenny envelope test: \(results.count) fake envelopes")
summary.append("")
summary.append("\(pad("Field", 22)) \(pad("Perfect text", 14)) Photo (OCR)")
for (index, field) in fields.enumerated() {
    summary.append("\(pad(field, 22)) \(pad(percent(results.map { $0.perfect[index] }), 14)) \(percent(results.map { $0.photo[index] }))")
}
summary.append("\(pad("WHOLE ENVELOPE RIGHT", 22)) \(pad(percent(results.map { allRight($0.perfect) }), 14)) \(percent(results.map { allRight($0.photo) }))")
summary.append("")
summary.append("By difficulty (whole envelope right on the photo, and OCR character error rate):")
for level in ["easy", "medium", "hard"] {
    let group = results.filter { $0.envelope.difficulty == level }
    guard !group.isEmpty else { continue }
    let cer = group.map(\.cer).reduce(0, +) / Double(group.count) * 100
    summary.append("  \(pad(level, 7)) \(String(format: "%3d", group.count)) envelopes   right \(percent(group.map { allRight($0.photo) }))   OCR errors \(String(format: "%4.1f%%", cer))")
}
summary.append("")
summary.append("By font (whole envelope right on the photo):")
for font in Set(results.map(\.envelope.font)).sorted() {
    let group = results.filter { $0.envelope.font == font }
    summary.append("  \(pad(font, 14)) \(String(format: "%3d", group.count)) envelopes   right \(percent(group.map { allRight($0.photo) }))")
}
print(summary.joined(separator: "\n"))

// The full report: the reader's rule problems first (they're the easiest to fix), then OCR problems.
var report = ["# Jenny envelope test", "", "```", summary.joined(separator: "\n"), "```", ""]

let ruleProblems = results.filter { !allRight($0.perfect) }
report.append("## Rule problems: wrong even with perfect text (\(ruleProblems.count))")
report.append("")
report.append("Fix these in `LabelReader` / `LabelParser`. The OCR isn't to blame here.")
report.append("")
for result in ruleProblems {
    report.append("### \(result.envelope.id) (\(result.envelope.difficulty))")
    for (index, ok) in result.perfect.enumerated() where ok == false {
        report.append("- **\(fields[index])**: expected `\(expected(fields[index], result.envelope.answer))`, got `\(result.perfectShown[index])`")
    }
    report.append("")
    report.append("```")
    report += result.envelope.lines
    report.append("```")
    report.append("")
}

let ocrProblems = results.filter { allRight($0.perfect) && !allRight($0.photo) }
report.append("## OCR problems: right with perfect text, wrong from the photo (\(ocrProblems.count))")
report.append("")
for result in ocrProblems {
    report.append("### \(result.envelope.id) (\(result.envelope.difficulty), \(result.envelope.font), OCR errors \(String(format: "%.1f%%", result.cer * 100)))")
    for (index, ok) in result.photo.enumerated() where ok == false {
        report.append("- **\(fields[index])**: expected `\(expected(fields[index], result.envelope.answer))`, got `\(result.photoShown[index])`")
    }
    report.append("")
    report.append("What Vision read:")
    report.append("```")
    report += result.ocrLines
    report.append("```")
    report.append("")
}

try report.joined(separator: "\n").write(to: reportURL, atomically: true, encoding: .utf8)
print("\nFull list of mistakes: \(reportURL.path)")
