// Makes fake Thai medicine envelope labels (ซองยา) for testing Jenny's reader, plus the right answer for each.
// Everything is made up: fake hospital, fake patient, fake HN. No real health data (PDPA).
//
// Usage: make-envelopes <out-folder> [count] [seed]
// The same seed always makes the same envelopes, so test results can be compared.

import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: Random numbers you can repeat

struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("usage: make-envelopes <out-folder> [count] [seed]")
    exit(1)
}
let outFolder = URL(fileURLWithPath: arguments[1])
let envelopeCount = arguments.count > 2 ? Int(arguments[2]) ?? 300 : 300
var rng = SeededRandom(state: arguments.count > 3 ? UInt64(arguments[3]) ?? 1 : 1)

func pick<T>(_ items: [T]) -> T { items.randomElement(using: &rng)! }
func chance(_ probability: Double) -> Bool { Double.random(in: 0..<1, using: &rng) < probability }
func between(_ low: Double, _ high: Double) -> Double { Double.random(in: low...high, using: &rng) }

// MARK: The right answer (what Jenny should read)

struct Answer: Codable {
    var name: String          // as in Jenny's name list, e.g. "Amlodipine"
    var strength: String      // "5 mg", "0.1%", or "" when none is printed
    var amount: Double
    var amountMax: Double?    // "ครั้งละ 1-2 เม็ด" → 1 and 2
    var unit: String          // "เม็ด", "แคปซูล", "ช้อนชา", "ml", "หยด", "พัฟ", "ซอง", or "" for creams
    var slots: [String]       // "morning", "noon", "evening", "bedtime"
    var meal: String          // "ก่อนอาหาร", "หลังอาหาร", "พร้อมอาหาร", or ""
    var asNeeded: Bool
    var warnings: [String]
    var route: String?        // "หยอดตาขวา", "ทาบาง ๆ", "สูด"… nil = by mouth
    /// false when the label only says "วันละ 2 ครั้ง". Jenny then guesses the times, and so does this answer.
    var timesPrinted: Bool
}

struct Envelope: Codable {
    var id: String
    var image: String
    var difficulty: String
    var font: String
    /// Every printed line, top to bottom: what a perfect OCR would return.
    var lines: [String]
    var answer: Answer
}

// MARK: Medicines

enum Form { case tablet, capsule, syrup, eyeDrops, cream, inhaler, sachet }

enum Meal: String {
    case before = "ก่อนอาหาร", after = "หลังอาหาร", with = "พร้อมอาหาร", none = ""
}

enum Slot: String {
    case morning, noon, evening, bedtime
    var thai: String {
        switch self {
        case .morning: "เช้า"
        case .noon: "กลางวัน"
        case .evening: "เย็น"
        case .bedtime: "ก่อนนอน"
        }
    }
}

enum Plan {
    case times([Slot], Meal)            // the label names the times: "หลังอาหาร เช้า-เย็น"
    case perDay(Int, Meal)              // only "วันละ 2 ครั้ง หลังอาหาร"
    case whenNeeded(String, Meal)       // "เมื่อมีอาการปวด"
}

struct Drug {
    var name: String            // as in medicine-names.json
    var line: String            // the printed drug line: {N} = name, {S} = strength
    var strengths: [String]
    var form: Form
    var purpose: String
    var plans: [Plan]
    var amounts: [String] = ["1"]   // "1", "2", "½", "1-2"
    var warnings: [String] = []
}

let m: [Slot] = [.morning], me: [Slot] = [.morning, .evening], mne: [Slot] = [.morning, .noon, .evening]
let bed: [Slot] = [.bedtime], all4: [Slot] = [.morning, .noon, .evening, .bedtime]
let sleepy = "ยานี้อาจทำให้ง่วงซึม ควรหลีกเลี่ยงการขับขี่ยานพาหนะ"
let finishAll = "รับประทานยานี้ติดต่อกันจนหมด"
let noAlcohol = "ห้ามดื่มสุราหรือเครื่องดื่มที่มีแอลกอฮอล์"
let drinkWater = "ดื่มน้ำตามมาก ๆ"

let drugs: [Drug] = [
    Drug(name: "Amlodipine", line: "{N} {S}", strengths: ["5 mg", "10 mg"], form: .tablet, purpose: "ยาลดความดันโลหิต",
         plans: [.times(m, .after), .times(m, .none), .perDay(1, .after)], amounts: ["1", "½"]),
    Drug(name: "Metformin", line: "{N} {S}", strengths: ["500 mg", "850 mg"], form: .tablet, purpose: "ยาลดน้ำตาลในเลือด",
         plans: [.times(me, .after), .times(mne, .after), .perDay(2, .after)], amounts: ["1", "2"]),
    Drug(name: "Simvastatin", line: "{N} {S}", strengths: ["10 mg", "20 mg", "40 mg"], form: .tablet, purpose: "ยาลดไขมันในเลือด",
         plans: [.times(bed, .none)], amounts: ["1", "½"]),
    Drug(name: "Atorvastatin", line: "{N} {S}", strengths: ["10 mg", "20 mg", "40 mg"], form: .tablet, purpose: "ยาลดไขมันในเลือด",
         plans: [.times(bed, .none), .times([.evening], .after)]),
    Drug(name: "Omeprazole", line: "{N} {S}", strengths: ["20 mg"], form: .capsule, purpose: "ยาลดกรดในกระเพาะอาหาร",
         plans: [.times(m, .before), .times(me, .before)]),
    Drug(name: "Losartan", line: "{N} {S}", strengths: ["50 mg", "100 mg"], form: .tablet, purpose: "ยาลดความดันโลหิต",
         plans: [.times(m, .after), .perDay(1, .after)]),
    Drug(name: "Enalapril", line: "{N} {S}", strengths: ["5 mg", "20 mg"], form: .tablet, purpose: "ยาลดความดันโลหิต",
         plans: [.times(me, .after), .times(m, .after)]),
    Drug(name: "Paracetamol", line: "{N} {S}", strengths: ["500 mg"], form: .tablet, purpose: "ยาแก้ปวด ลดไข้",
         plans: [.whenNeeded("เมื่อมีอาการปวดหรือมีไข้", .none), .whenNeeded("เวลามีอาการปวด", .none)],
         amounts: ["1", "1-2"], warnings: ["ห้ามรับประทานเกินวันละ 8 เม็ด"]),
    Drug(name: "Amoxicillin", line: "{N} {S}", strengths: ["250 mg", "500 mg"], form: .capsule, purpose: "ยาฆ่าเชื้อแบคทีเรีย",
         plans: [.times(mne, .after), .perDay(3, .after)], amounts: ["1", "2"], warnings: [finishAll]),
    Drug(name: "Chlorpheniramine", line: "{N} {S}", strengths: ["4 mg"], form: .tablet, purpose: "ยาแก้แพ้ ลดน้ำมูก",
         plans: [.times(mne, .after), .whenNeeded("เมื่อมีอาการแพ้ คัน มีน้ำมูก", .none), .times(bed, .none)],
         warnings: [sleepy]),
    Drug(name: "Ibuprofen", line: "{N} {S}", strengths: ["200 mg", "400 mg"], form: .tablet, purpose: "ยาแก้ปวด ลดการอักเสบ",
         plans: [.times(mne, .after), .whenNeeded("เมื่อมีอาการปวด", .after)], warnings: ["ห้ามรับประทานขณะท้องว่าง"]),
    Drug(name: "Glipizide", line: "{N} {S}", strengths: ["5 mg"], form: .tablet, purpose: "ยาลดน้ำตาลในเลือด",
         plans: [.times(m, .before), .times(me, .before)], amounts: ["1", "½"]),
    Drug(name: "Furosemide", line: "{N} {S}", strengths: ["40 mg"], form: .tablet, purpose: "ยาขับปัสสาวะ",
         plans: [.times(m, .after)], amounts: ["1", "½"]),
    Drug(name: "Hydrochlorothiazide", line: "{N} {S}", strengths: ["25 mg"], form: .tablet, purpose: "ยาขับปัสสาวะ ลดความดัน",
         plans: [.times(m, .after)]),
    Drug(name: "Atenolol", line: "{N} {S}", strengths: ["25 mg", "50 mg"], form: .tablet, purpose: "ยาลดความดันโลหิต",
         plans: [.times(m, .after), .perDay(1, .after)], warnings: ["ห้ามหยุดยาเอง"]),
    Drug(name: "Propranolol", line: "{N} {S}", strengths: ["10 mg", "40 mg"], form: .tablet, purpose: "ยาลดอาการใจสั่น",
         plans: [.times(me, .after), .perDay(2, .after)]),
    Drug(name: "Domperidone", line: "{N} {S}", strengths: ["10 mg"], form: .tablet, purpose: "ยาแก้คลื่นไส้ อาเจียน",
         plans: [.times(mne, .before)]),
    Drug(name: "Simethicone", line: "{N} {S}", strengths: ["80 mg"], form: .tablet, purpose: "ยาขับลม",
         plans: [.times(mne, .after)], warnings: []),
    Drug(name: "Cetirizine", line: "{N} {S}", strengths: ["10 mg"], form: .tablet, purpose: "ยาแก้แพ้",
         plans: [.times(bed, .none), .whenNeeded("เมื่อมีอาการแพ้", .none)], warnings: [sleepy]),
    Drug(name: "Loratadine", line: "{N} {S}", strengths: ["10 mg"], form: .tablet, purpose: "ยาแก้แพ้",
         plans: [.times(m, .after), .perDay(1, .none)]),
    Drug(name: "Metronidazole", line: "{N} {S}", strengths: ["200 mg", "400 mg"], form: .tablet, purpose: "ยาฆ่าเชื้อ",
         plans: [.times(mne, .after)], warnings: [noAlcohol, finishAll]),
    Drug(name: "Prednisolone", line: "{N} {S}", strengths: ["5 mg"], form: .tablet, purpose: "ยาลดการอักเสบ",
         plans: [.times(m, .after), .times(mne, .after)], amounts: ["1", "2"], warnings: ["ห้ามหยุดยาเอง"]),
    Drug(name: "Allopurinol", line: "{N} {S}", strengths: ["100 mg", "300 mg"], form: .tablet, purpose: "ยาลดกรดยูริก",
         plans: [.times(m, .after)], warnings: [drinkWater]),
    Drug(name: "Colchicine", line: "{N} {S}", strengths: ["0.6 mg"], form: .tablet, purpose: "ยารักษาโรคเกาต์",
         plans: [.times(me, .after), .perDay(2, .after)]),
    Drug(name: "Warfarin", line: "{N} {S}", strengths: ["3 mg", "5 mg"], form: .tablet, purpose: "ยาต้านการแข็งตัวของเลือด",
         plans: [.times(bed, .none), .times([.evening], .after)], amounts: ["1", "½"],
         warnings: ["ห้ามรับประทานยาอื่นร่วมโดยไม่ปรึกษาแพทย์"]),
    Drug(name: "Clopidogrel", line: "{N} {S}", strengths: ["75 mg"], form: .tablet, purpose: "ยาต้านเกล็ดเลือด",
         plans: [.times(m, .after)]),
    Drug(name: "Glibenclamide", line: "{N} {S}", strengths: ["5 mg"], form: .tablet, purpose: "ยาลดน้ำตาลในเลือด",
         plans: [.times(m, .before), .times(me, .before)], amounts: ["1", "½"]),
    Drug(name: "Levothyroxine", line: "{N} {S}", strengths: ["50 mcg", "100 mcg"], form: .tablet, purpose: "ยาไทรอยด์",
         plans: [.times(m, .before)]),
    Drug(name: "Montelukast", line: "{N} {S}", strengths: ["10 mg"], form: .tablet, purpose: "ยาป้องกันหอบหืด",
         plans: [.times(bed, .none)]),
    Drug(name: "Gabapentin", line: "{N} {S}", strengths: ["300 mg"], form: .capsule, purpose: "ยาลดอาการปวดปลายประสาท",
         plans: [.times(bed, .none), .times(me, .after)], warnings: [sleepy]),
    Drug(name: "Tramadol", line: "{N} {S}", strengths: ["50 mg"], form: .capsule, purpose: "ยาแก้ปวด",
         plans: [.whenNeeded("เมื่อมีอาการปวด", .after)], warnings: [sleepy]),
    Drug(name: "Diazepam", line: "{N} {S}", strengths: ["2 mg", "5 mg"], form: .tablet, purpose: "ยาคลายกังวล",
         plans: [.times(bed, .none)], warnings: [sleepy, noAlcohol]),
    Drug(name: "Lorazepam", line: "{N} {S}", strengths: ["0.5 mg", "1 mg"], form: .tablet, purpose: "ยาช่วยให้นอนหลับ",
         plans: [.times(bed, .none), .whenNeeded("เมื่อนอนไม่หลับ", .none)], warnings: [sleepy]),
    Drug(name: "Betahistine", line: "{N} {S}", strengths: ["6 mg", "12 mg"], form: .tablet, purpose: "ยาแก้เวียนศีรษะ",
         plans: [.times(mne, .after)]),
    Drug(name: "Dimenhydrinate", line: "{N} {S}", strengths: ["50 mg"], form: .tablet, purpose: "ยาแก้เมารถ เมาเรือ",
         plans: [.whenNeeded("เมื่อมีอาการคลื่นไส้ อาเจียน", .none)], warnings: [sleepy]),
    Drug(name: "Bisacodyl", line: "{N} {S}", strengths: ["5 mg"], form: .tablet, purpose: "ยาระบาย",
         plans: [.times(bed, .none)], amounts: ["1", "2"]),
    Drug(name: "Aspirin", line: "{N} {S}", strengths: ["81 mg"], form: .tablet, purpose: "ยาต้านเกล็ดเลือด",
         plans: [.times(m, .after)], warnings: ["ห้ามรับประทานขณะท้องว่าง"]),
    Drug(name: "Hyoscine", line: "{N} {S}", strengths: ["10 mg"], form: .tablet, purpose: "ยาแก้ปวดท้อง",
         plans: [.whenNeeded("เมื่อปวดท้อง", .none)]),
    Drug(name: "Norfloxacin", line: "{N} {S}", strengths: ["400 mg"], form: .tablet, purpose: "ยาฆ่าเชื้อทางเดินปัสสาวะ",
         plans: [.times(me, .before)], warnings: [finishAll, drinkWater]),
    Drug(name: "Dicloxacillin", line: "{N} {S}", strengths: ["250 mg", "500 mg"], form: .capsule, purpose: "ยาฆ่าเชื้อ",
         plans: [.times(all4, .before), .perDay(4, .before)], warnings: [finishAll]),
    Drug(name: "Cephalexin", line: "{N} {S}", strengths: ["500 mg"], form: .capsule, purpose: "ยาฆ่าเชื้อ",
         plans: [.times(all4, .after), .times(mne, .after)], warnings: [finishAll]),
    Drug(name: "ฟ้าทะลายโจร", line: "ยาแคปซูลฟ้าทะลายโจร", strengths: [""], form: .capsule, purpose: "บรรเทาอาการเจ็บคอ ไข้หวัด",
         plans: [.times(all4, .before), .perDay(4, .before)], amounts: ["2", "3"]),
    // Syrups: the name line has "Syrup" and "/5 ml" in it, like real bottles.
    Drug(name: "Paracetamol", line: "{N} Syrup {S}/5 ml", strengths: ["120 mg", "250 mg"], form: .syrup, purpose: "ยาลดไข้ แก้ปวด",
         plans: [.whenNeeded("เมื่อมีไข้", .none)], amounts: ["1", "2"]),
    Drug(name: "Bromhexine", line: "{N} {S}/5 ml syrup", strengths: ["4 mg"], form: .syrup, purpose: "ยาละลายเสมหะ",
         plans: [.times(mne, .after), .perDay(3, .after)], amounts: ["1", "2"]),
    Drug(name: "Dextromethorphan", line: "{N} {S}/5 ml", strengths: ["15 mg"], form: .syrup, purpose: "ยาแก้ไอ",
         plans: [.times(mne, .after)], warnings: [sleepy]),
    Drug(name: "Amoxicillin", line: "{N} Suspension {S}/5 ml", strengths: ["125 mg", "250 mg"], form: .syrup,
         purpose: "ยาฆ่าเชื้อแบคทีเรีย", plans: [.times(mne, .after)], warnings: [finishAll, "เขย่าขวดก่อนใช้"]),
    // Eye drops, creams, inhalers, sachets.
    Drug(name: "Chloramphenicol", line: "{N} eye drops {S}", strengths: ["0.5%"], form: .eyeDrops, purpose: "ยาหยอดตาฆ่าเชื้อ",
         plans: [.perDay(4, .none), .times(all4, .none)], amounts: ["1", "2"]),
    Drug(name: "TEARS NATURALE", line: "TEARS NATURALE II", strengths: [""], form: .eyeDrops, purpose: "น้ำตาเทียม",
         plans: [.perDay(4, .none), .whenNeeded("เมื่อมีอาการตาแห้ง", .none)]),
    Drug(name: "Timolol", line: "{N} eye drops {S}", strengths: ["0.5%"], form: .eyeDrops, purpose: "ยารักษาต้อหิน",
         plans: [.times(me, .none)]),
    Drug(name: "Triamcinolone", line: "{N} cream {S}", strengths: ["0.1%", "0.02%"], form: .cream, purpose: "ยาทาแก้ผื่นคัน",
         plans: [.times(me, .none), .perDay(2, .none)]),
    Drug(name: "Clotrimazole", line: "{N} cream {S}", strengths: ["1%"], form: .cream, purpose: "ยาทาฆ่าเชื้อรา",
         plans: [.times(me, .none)], warnings: ["ใช้ภายนอก ห้ามรับประทาน"]),
    Drug(name: "VENTOLIN", line: "VENTOLIN EVOHALER {S}", strengths: ["100 mcg"], form: .inhaler, purpose: "ยาขยายหลอดลม",
         plans: [.whenNeeded("เมื่อมีอาการหอบเหนื่อย", .none)], amounts: ["1", "2"]),
    Drug(name: "ORS", line: "ORS (ผงเกลือแร่)", strengths: [""], form: .sachet, purpose: "ยาแก้ท้องเสีย ป้องกันการขาดน้ำ",
         plans: [.whenNeeded("เมื่อถ่ายเหลว", .none)]),
]

// MARK: Writing the label text

let thaiDigits = Array("๐๑๒๓๔๕๖๗๘๙")

func toThaiDigits(_ text: String) -> String {
    String(text.map { $0.isASCII && $0.isNumber ? thaiDigits[Int(String($0))!] : $0 })
}

func amountValue(_ text: String) -> (Double, Double?) {
    if text == "½" { return (0.5, nil) }
    let parts = text.split(separator: "-").compactMap { Double($0) }
    return (parts.first ?? 1, parts.count > 1 ? parts[1] : nil)
}

func amountWord(_ text: String) -> String {
    text == "½" ? pick(["ครึ่ง", "½", "1/2"]) : text
}

func mealWord(_ meal: Meal) -> String {
    switch meal {
    case .before: pick(["ก่อนอาหาร", "ก่อนอาหาร 30 นาที", "ก่อนอาหารครึ่งชั่วโมง"])
    case .after: pick(["หลังอาหาร", "หลังอาหาร", "หลังอาหารทันที"])
    case .with: "พร้อมอาหาร"
    case .none: ""
    }
}

/// "เช้า-เย็น", "เช้า กลางวัน เย็น", "เช้า-เย็น และก่อนนอน"
func timesWord(_ slots: [Slot]) -> String {
    let day = slots.filter { $0 != .bedtime }.map(\.thai)
    var text = day.joined(separator: pick(["-", " ", " - ", ", "]))
    if slots.contains(.bedtime) {
        text += day.isEmpty ? "ก่อนนอน" : pick([" และก่อนนอน", " และ ก่อนนอน", " ก่อนนอน"])
    }
    return text
}

/// What LabelReader guesses when the label only says "วันละ N ครั้ง".
func guessedSlots(_ perDay: Int) -> [Slot] {
    switch perDay {
    case ...1: m
    case 2: me
    case 3: mne
    default: all4
    }
}

func spaced(_ parts: [String]) -> String {
    parts.filter { !$0.isEmpty }.joined(separator: " ")
}

/// The instruction lines and the matching answer fields.
func instructions(for drug: Drug, plan: Plan, amount: String) -> (lines: [String], answer: Answer) {
    var (value, maxValue) = amountValue(amount)
    var unit: String
    var route: String?
    var doseLine: String

    switch drug.form {
    case .tablet, .capsule, .sachet:
        unit = drug.form == .tablet ? "เม็ด" : (drug.form == .capsule ? "แคปซูล" : "ซอง")
        doseLine = "\(pick(["รับประทาน", "รับประทาน", "รับประทานยา", "รับประทาน "]))ครั้งละ \(amountWord(amount)) \(unit)"
        if drug.form == .sachet { doseLine += " ละลายน้ำ 1 แก้ว" }
    case .syrup:
        if chance(0.25) {
            unit = "ml"
            (value, maxValue) = (value * 5, nil)   // 1 ช้อนชา = 5 ml
            doseLine = "รับประทานครั้งละ \(Int(value)) \(pick(["มล.", "ml", "ซีซี"]))"
        } else {
            unit = "ช้อนชา"
            doseLine = "รับประทานครั้งละ \(amountWord(amount)) ช้อนชา"
        }
    case .eyeDrops:
        unit = "หยด"
        route = pick(["หยอดตาทั้ง 2 ข้าง", "หยอดตาขวา", "หยอดตาซ้าย"])
        doseLine = "\(route!) ครั้งละ \(amountWord(amount)) หยด"
    case .cream:
        unit = ""
        route = "ทาบาง ๆ"
        doseLine = pick(["ทาบาง ๆ บริเวณที่เป็น", "ทาบางๆ บริเวณที่มีอาการ"])
    case .inhaler:
        unit = "พัฟ"
        route = "สูด"
        doseLine = "สูดครั้งละ \(amountWord(amount)) พัฟ"
    }

    var slots: [Slot] = []
    var meal = Meal.none
    var asNeeded = false
    var timesPrinted = true
    var timeLine: String

    switch plan {
    case .times(let planSlots, let planMeal):
        slots = planSlots
        meal = planMeal
        let daySlots = planSlots.filter { $0 != .bedtime }
        if planSlots == bed {
            timeLine = pick(["ก่อนนอน", "ก่อนนอน", "ก่อนเข้านอน"])
        } else if daySlots.count == 1 && planSlots.count == 1 && planMeal != .none && chance(0.6) {
            // "หลังอาหารเช้า", "ก่อนอาหารเช้า 30 นาที"
            timeLine = planMeal.rawValue + daySlots[0].thai + (planMeal == .before && chance(0.5) ? " 30 นาที" : "")
        } else {
            let perDay = chance(0.7) ? "วันละ \(planSlots.count) ครั้ง" : ""
            timeLine = spaced([perDay, mealWord(planMeal), timesWord(planSlots)])
        }
    case .perDay(let count, let planMeal):
        slots = guessedSlots(count)
        meal = planMeal
        timesPrinted = false
        timeLine = spaced(["วันละ \(count) ครั้ง", mealWord(planMeal)])
    case .whenNeeded(let phrase, let planMeal):
        asNeeded = true
        meal = planMeal
        let every = drug.form == .cream || drug.form == .eyeDrops ? "" : pick(["ทุก 4-6 ชั่วโมง", "ห่างกันอย่างน้อย 4 ชั่วโมง", ""])
        timeLine = spaced([every, phrase, mealWord(planMeal)])
    }

    var lines = chance(0.4) ? [spaced([doseLine, timeLine])] : [doseLine, timeLine]
    if chance(0.15) { lines = lines.map(toThaiDigits) }

    // The strength and warnings are filled in by makeEnvelope().
    let answer = Answer(name: drug.name, strength: "", amount: unit.isEmpty ? 1 : value,
                        amountMax: unit.isEmpty ? nil : maxValue, unit: unit, slots: slots.map(\.rawValue),
                        meal: meal.rawValue, asNeeded: asNeeded, warnings: [], route: route, timesPrinted: timesPrinted)
    return (lines, answer)
}

// MARK: The rest of the envelope (all fake)

let hospitals = ["โรงพยาบาลสมมติ", "โรงพยาบาลทดสอบวิทยา", "โรงพยาบาลตัวอย่างนคร", "คลินิกเวชกรรมใจดี (ตัวอย่าง)",
                 "ร้านยาตัวอย่างเภสัช", "โรงพยาบาลส่งเสริมสุขภาพตำบลสมมติ"]
let patients = ["นายทดสอบ ใจดี", "นางสาวสมมติ สุขใจ", "นางตัวอย่าง มีสุข", "นายสมมุติ รักษ์ยา", "นางทดลอง ชื่อปลอม",
                "Mr. Test Sample", "นายตัวอย่าง ทดสอบระบบ"]
let footers = ["เก็บยาให้พ้นมือเด็ก", "เก็บยาให้พ้นแสงแดด", "ยานี้สำหรับผู้ป่วยรายนี้เท่านั้น"]

func number(_ digits: Int) -> String {
    (0..<digits).map { _ in String(Int.random(in: 0...9, using: &rng)) }.joined()
}

func casedName(_ name: String) -> String {
    pick([name, name.uppercased(), name])
}

func casedStrength(_ strength: String) -> String {
    guard !strength.isEmpty else { return "" }
    return pick([strength, strength.uppercased(), strength.replacingOccurrences(of: " ", with: "")])
}

func quantityLine(_ form: Form) -> String {
    switch form {
    case .tablet: "จำนวน \(pick([10, 14, 20, 30, 60, 90])) เม็ด"
    case .capsule: "จำนวน \(pick([10, 20, 30])) แคปซูล"
    case .syrup, .eyeDrops: "จำนวน 1 ขวด"
    case .cream: "จำนวน 1 หลอด"
    case .inhaler: "จำนวน 1 กระบอก"
    case .sachet: "จำนวน \(pick([5, 10])) ซอง"
    }
}

enum Role { case header, small, drug, normal, warning }

func makeEnvelope() -> (lines: [(String, Role)], answer: Answer) {
    let drug = pick(drugs)
    let strength = pick(drug.strengths)
    var (instructionLines, answer) = instructions(for: drug, plan: pick(drug.plans), amount: pick(drug.amounts))
    answer.strength = strength

    let drugLine = drug.line
        .replacingOccurrences(of: "{N}", with: casedName(drug.name))
        .replacingOccurrences(of: "{S}", with: casedStrength(strength))

    var lines: [(String, Role)] = [(pick(hospitals), .header)]
    if chance(0.6) { lines.append(("โทร. 0-2000-\(number(4))", .small)) }
    let patient = pick(patients)
    if chance(0.5) {
        lines.append(("ชื่อ \(patient)  HN \(number(2))-\(number(5))", .normal))
    } else {
        lines.append(("\(patient)", .normal))
        lines.append(("HN \(number(7))  วันที่ \(Int.random(in: 1...28, using: &rng))/\(Int.random(in: 1...12, using: &rng))/2569", .small))
    }
    lines.append((drugLine, .drug))
    if chance(0.7) { lines.append((chance(0.5) ? drug.purpose : "ข้อบ่งใช้: \(drug.purpose)", .small)) }
    let quantityFirst = chance(0.3)
    if quantityFirst { lines.append((quantityLine(drug.form), .small)) }
    lines += instructionLines.map { ($0, .normal) }

    answer.warnings = drug.warnings.filter { _ in chance(0.85) }
    for warning in answer.warnings {
        lines.append((chance(0.3) ? "คำเตือน: \(warning)" : warning, .warning))
    }
    if !quantityFirst { lines.append((quantityLine(drug.form), .small)) }
    if chance(0.5) { lines.append((pick(footers), .small)) }
    return (lines, answer)
}

// MARK: Drawing

let fontFamilies = ["Thonburi", "Sukhumvit Set", "Tahoma", "Ayuthaya", "Sathu", "Silom"]

struct Style {
    var family: String
    var size: CGFloat
    var paper: NSColor
    var ink: NSColor
    var accent: NSColor
    var warningInk: NSColor
    var centeredHeader: Bool
    var border: Bool
}

func randomStyle() -> Style {
    let faded = chance(0.2)   // thermal printers fade to grey
    let ink = faded ? NSColor(white: between(0.3, 0.45), alpha: 1) : NSColor(white: between(0, 0.12), alpha: 1)
    return Style(
        family: pick(fontFamilies),
        size: between(48, 64),   // big enough to look like a real phone photo of a label
        paper: pick([NSColor.white, NSColor(red: 1, green: 0.98, blue: 0.92, alpha: 1),
                     NSColor(red: 0.93, green: 0.96, blue: 1, alpha: 1), NSColor(red: 0.95, green: 1, blue: 0.95, alpha: 1)]),
        ink: ink,
        accent: pick([ink, NSColor(red: 0.05, green: 0.2, blue: 0.55, alpha: 1), NSColor(red: 0, green: 0.4, blue: 0.25, alpha: 1)]),
        warningInk: chance(0.5) ? NSColor(red: 0.75, green: 0.05, blue: 0.05, alpha: 1) : ink,
        centeredHeader: chance(0.5),
        border: chance(0.5))
}

func font(_ style: Style, size: CGFloat, bold: Bool) -> NSFont {
    NSFontManager.shared.font(withFamily: style.family, traits: bold ? .boldFontMask : [], weight: 5, size: size)
        ?? NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
}

func attributed(_ text: String, role: Role, style: Style) -> NSAttributedString {
    let (size, bold, color): (CGFloat, Bool, NSColor) = switch role {
    case .header: (style.size * 1.1, true, style.accent)
    case .small: (style.size * 0.8, false, style.ink)
    case .drug: (style.size * 1.2, true, style.ink)
    case .normal: (style.size, false, style.ink)
    case .warning: (style.size * 0.9, true, style.warningInk)
    }
    return NSAttributedString(string: text, attributes: [.font: font(style, size: size, bold: bold), .foregroundColor: color])
}

func draw(_ lines: [(String, Role)], style: Style) -> CGImage {
    let texts = lines.map { attributed($0.0, role: $0.1, style: style) }
    let padding: CGFloat = 64
    let gap = style.size * 0.35
    let width = ceil(max(1300, (texts.map { $0.size().width }.max() ?? 0) + padding * 2))
    let height = ceil(texts.reduce(padding * 2) { $0 + $1.size().height + gap })

    let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(style.paper.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    // Flip so y goes down, like a page.
    context.translateBy(x: 0, y: height)
    context.scaleBy(x: 1, y: -1)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    var y = padding
    for (index, text) in texts.enumerated() {
        let size = text.size()
        let x = index == 0 && style.centeredHeader ? (width - size.width) / 2 : padding
        text.draw(at: NSPoint(x: x, y: y))
        y += size.height + gap
        if index == 0 {
            context.setStrokeColor(style.accent.cgColor)
            context.setLineWidth(3)
            context.move(to: CGPoint(x: padding, y: y - gap / 2))
            context.addLine(to: CGPoint(x: width - padding, y: y - gap / 2))
            context.strokePath()
        }
    }
    if style.border {
        context.setStrokeColor(style.accent.cgColor)
        context.setLineWidth(5)
        context.stroke(CGRect(x: 18, y: 18, width: width - 36, height: height - 36))
    }
    NSGraphicsContext.restoreGraphicsState()
    return context.makeImage()!
}

// MARK: Making it look like a phone photo

struct Damage {
    var angle: Double          // degrees, either way
    var blur: ClosedRange<Double>
    var noise: ClosedRange<Double>
    var shadow: ClosedRange<Double>
    var perspective: ClosedRange<Double>
    var contrast: ClosedRange<Double>
    var scale: ClosedRange<Double>
    var jpegQuality: Double
}

let damageLevels: [(name: String, share: Double, damage: Damage)] = [
    ("easy", 0.4, Damage(angle: 2, blur: 0...0.8, noise: 0...0.03, shadow: 0...0.1, perspective: 0...0,
                         contrast: 0.95...1, scale: 0.9...1, jpegQuality: 0.9)),
    ("medium", 0.35, Damage(angle: 6, blur: 1.2...2.4, noise: 0.04...0.09, shadow: 0.1...0.3, perspective: 0...0.04,
                            contrast: 0.75...0.95, scale: 0.6...0.8, jpegQuality: 0.7)),
    ("hard", 0.25, Damage(angle: 12, blur: 2.4...4.0, noise: 0.08...0.15, shadow: 0.25...0.5, perspective: 0.03...0.07,
                          contrast: 0.55...0.75, scale: 0.4...0.55, jpegQuality: 0.5)),
]

let ciContext = CIContext()

func range(_ r: ClosedRange<Double>) -> Double { between(r.lowerBound, r.upperBound) }

func damage(_ cgImage: CGImage, with d: Damage) -> CGImage {
    var image = CIImage(cgImage: cgImage)
    let size = image.extent.size

    // Phone held at an angle.
    let tilt = range(d.perspective)
    if tilt > 0 {
        func jitter() -> CGFloat { CGFloat(between(-tilt, tilt)) * min(size.width, size.height) }
        let filter = CIFilter.perspectiveTransform()
        filter.inputImage = image
        filter.topLeft = CGPoint(x: jitter(), y: size.height + jitter())
        filter.topRight = CGPoint(x: size.width + jitter(), y: size.height + jitter())
        filter.bottomLeft = CGPoint(x: jitter(), y: jitter())
        filter.bottomRight = CGPoint(x: size.width + jitter(), y: jitter())
        image = filter.outputImage ?? image
    }
    image = image.transformed(by: CGAffineTransform(rotationAngle: between(-d.angle, d.angle) * .pi / 180))

    // On a table.
    let frame = image.extent.insetBy(dx: -size.width * 0.06, dy: -size.height * 0.06).integral
    let table = CIColor(red: between(0.35, 0.8), green: between(0.3, 0.7), blue: between(0.25, 0.6))
    image = image.composited(over: CIImage(color: table).cropped(to: frame))

    // A shadow from a hand or the phone.
    let shadow = range(d.shadow)
    if shadow > 0.01 {
        let gradient = CIFilter.linearGradient()
        gradient.point0 = CGPoint(x: frame.minX + frame.width * between(0, 1), y: frame.minY)
        gradient.point1 = CGPoint(x: frame.minX + frame.width * between(0, 1), y: frame.maxY)
        let dark = 1 - shadow
        gradient.color0 = CIColor(red: dark, green: dark, blue: dark)
        gradient.color1 = CIColor(red: 1, green: 1, blue: 1)
        let multiply = CIFilter.multiplyCompositing()
        multiply.inputImage = gradient.outputImage?.cropped(to: frame)
        multiply.backgroundImage = image
        image = multiply.outputImage ?? image
    }

    // Faded print and camera exposure.
    let colors = CIFilter.colorControls()
    colors.inputImage = image
    colors.contrast = Float(range(d.contrast))
    colors.brightness = Float(between(-0.04, 0.06))
    colors.saturation = Float(between(0.7, 1))
    image = colors.outputImage ?? image

    // Out of focus.
    let blur = range(d.blur)
    if blur > 0.05 {
        image = image.clampedToExtent().applyingGaussianBlur(sigma: blur).cropped(to: frame)
    }

    // Camera grain: each pixel a little lighter or darker (-grain…+grain).
    let grain = range(d.noise)
    if grain > 0.005, let random = CIFilter.randomGenerator().outputImage {
        let gray = CIFilter.colorMatrix()
        gray.inputImage = random.transformed(by: CGAffineTransform(translationX: between(0, 500), y: between(0, 500)))
        let spread = CGFloat(grain * 2)
        gray.rVector = CIVector(x: spread, y: 0, z: 0, w: 0)
        gray.gVector = CIVector(x: spread, y: 0, z: 0, w: 0)
        gray.bVector = CIVector(x: spread, y: 0, z: 0, w: 0)
        gray.aVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        gray.biasVector = CIVector(x: -CGFloat(grain), y: -CGFloat(grain), z: -CGFloat(grain), w: 0)
        let add = CIFilter.additionCompositing()
        add.inputImage = gray.outputImage?.cropped(to: frame)
        add.backgroundImage = image
        image = add.outputImage ?? image
    }

    // Smaller photo (held far away).
    let scale = range(d.scale)
    image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    return ciContext.createCGImage(image, from: image.extent.integral)!
}

func writeJPEG(_ image: CGImage, to url: URL, quality: Double) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    CGImageDestinationFinalize(destination)
}

// MARK: Make them all

try FileManager.default.createDirectory(at: outFolder, withIntermediateDirectories: true)
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

for index in 1...envelopeCount {
    let id = String(format: "%04d", index)
    let (lines, answer) = makeEnvelope()
    let style = randomStyle()
    let roll = between(0, 1)
    let level = roll < damageLevels[0].share ? damageLevels[0]
        : (roll < damageLevels[0].share + damageLevels[1].share ? damageLevels[1] : damageLevels[2])

    let photo = damage(draw(lines, style: style), with: level.damage)
    writeJPEG(photo, to: outFolder.appendingPathComponent("\(id).jpg"), quality: level.damage.jpegQuality)

    let envelope = Envelope(id: id, image: "\(id).jpg", difficulty: level.name, font: style.family,
                            lines: lines.map(\.0), answer: answer)
    try encoder.encode(envelope).write(to: outFolder.appendingPathComponent("\(id).json"))
}
print("Made \(envelopeCount) fake envelopes in \(outFolder.path)")
