import Foundation

/// One fake (synthetic) envelope label and the answer we expect from it. No real patient data (PDPA).
nonisolated struct SampleLabel: Identifiable {
    let id: Int
    let text: String
    let expected: PillInfo

    var lines: [String] { text.components(separatedBy: "\n") }
}

/// The 5 fake envelopes from the plan (section 10.1). Print these for the demo, and reuse them in Previews.
nonisolated enum SampleLabels {
    static let all: [SampleLabel] = [
        SampleLabel(
            id: 1,
            text: "Amlodipine 5 mg\nรับประทานครั้งละ 1 เม็ด วันละ 1 ครั้ง\nหลังอาหารเช้า",
            expected: PillInfo(drugName: "Amlodipine", strength: "5 mg", amountPerDose: 1, unit: "เม็ด",
                               morning: true, noon: false, evening: false, bedtime: false,
                               mealTiming: .after, asNeeded: false, warnings: [])),
        SampleLabel(
            id: 2,
            text: "Metformin 500 mg\nรับประทานครั้งละ 1 เม็ด วันละ 2 ครั้ง\nหลังอาหารทันที เช้า-เย็น",
            expected: PillInfo(drugName: "Metformin", strength: "500 mg", amountPerDose: 1, unit: "เม็ด",
                               morning: true, noon: false, evening: true, bedtime: false,
                               mealTiming: .after, asNeeded: false, warnings: [])),
        SampleLabel(
            id: 3,
            text: "Simvastatin 20 mg\nรับประทานครั้งละ 1 เม็ด\nก่อนนอน",
            expected: PillInfo(drugName: "Simvastatin", strength: "20 mg", amountPerDose: 1, unit: "เม็ด",
                               morning: false, noon: false, evening: false, bedtime: true,
                               mealTiming: .anytime, asNeeded: false, warnings: [])),
        SampleLabel(
            id: 4,
            text: "Omeprazole 20 mg\nรับประทานครั้งละ 1 แคปซูล วันละ 1 ครั้ง\nก่อนอาหารเช้า 30 นาที",
            expected: PillInfo(drugName: "Omeprazole", strength: "20 mg", amountPerDose: 1, unit: "แคปซูล",
                               morning: true, noon: false, evening: false, bedtime: false,
                               mealTiming: .before, asNeeded: false, warnings: [])),
        SampleLabel(
            id: 5,
            text: "Paracetamol 500 mg\nรับประทานครั้งละ 1-2 เม็ด ทุก 4-6 ชั่วโมง\nเวลามีอาการปวดหรือมีไข้\nไม่ควรเกิน 8 เม็ดต่อวัน",
            expected: PillInfo(drugName: "Paracetamol", strength: "500 mg", amountPerDose: 1, unit: "เม็ด",
                               morning: false, noon: false, evening: false, bedtime: false,
                               mealTiming: .anytime, asNeeded: true, warnings: ["ไม่ควรเกิน 8 เม็ดต่อวัน"])),
    ]
}
