import Foundation

/// Reads a Thai medicine label with fixed rules. Offline, instant, and the same answer every time.
nonisolated enum LabelParser {

    static func parse(_ lines: [String]) -> PillInfo {
        let text = normalize(lines.joined(separator: "\n"))
        let compact = text.replacingOccurrences(of: " ", with: "")              // OCR adds random spaces in Thai
        let latin = text.lowercased().replacingOccurrences(of: ".", with: "")   // "b.i.d." → "bid"
        var info = PillInfo.empty

        // 1. Drug + strength: "Amlodipine 5 mg"
        if let m = text.firstMatch(of: #/([A-Za-z][A-Za-z\-]{3,})\s*(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml)\b/#.ignoresCase()) {
            info.drugName = String(m.1).capitalized
            info.strength = "\(m.2) \(m.3.lowercased())"
        }

        // 2. Amount each time: "ครั้งละ1เม็ด", "ครั้งละครึ่งเม็ด", "ครั้งละ½เม็ด"
        if let m = compact.firstMatch(of: #/ครั้งละ(\d+(?:\.\d+)?|ครึ่ง|½)(เม็ด|แคปซูล|ช้อนชา|ช้อนโต๊ะ|ซอง)?/#) {
            info.amountPerDose = (m.1 == "ครึ่ง" || m.1 == "½") ? 0.5 : (Double(m.1) ?? 1)
            if let unit = m.2 { info.unit = String(unit) }
        }

        // 3. Times of day
        info.morning = compact.contains("เช้า")
        info.noon = compact.contains("กลางวัน") || compact.contains("เที่ยง")
        info.evening = compact.contains("เย็น")
        info.bedtime = compact.contains("ก่อนนอน") || latin.contains(#/\bhs\b/#)

        // 4. Only when needed
        let asNeededWords = ["เมื่อมีอาการ", "เวลามีอาการ", "หากมีอาการ", "ถ้ามีอาการ", "ขณะมีอาการ", "เมื่อปวด", "เวลาปวด",
                             "เมื่อมีไข้", "เวลามีไข้", "เมื่อจำเป็น", "ทุก4-6ชั่วโมง", "ทุก4-6ชม"]
        let englishAsNeeded = ["as needed", "when needed", "if needed", "when required"]
        info.asNeeded = asNeededWords.contains { compact.contains($0) } || latin.contains(#/\bprn\b/#)
            || englishAsNeeded.contains { latin.contains($0) }

        // 5. Times per day: fill in times only if the label didn't name them
        var timesPerDay = 0
        if let m = compact.firstMatch(of: #/วันละ(\d)ครั้ง/#) { timesPerDay = Int(m.1) ?? 0 }
        if latin.contains(#/\bod\b/#) { timesPerDay = 1 }
        if latin.contains(#/\bbid\b/#) { timesPerDay = 2 }
        if latin.contains(#/\btid\b/#) { timesPerDay = 3 }
        if latin.contains(#/\bqid\b/#) { timesPerDay = 4 }
        // "ห่างกันอย่างน้อย 6 ชม." with no set times: take it when needed (paracetamol), not at fixed times.
        if !info.asNeeded && !info.hasAnyTime && timesPerDay == 0 && compact.contains("ห่างกันอย่างน้อย") {
            info.asNeeded = true
        }
        if !info.hasAnyTime && !info.asNeeded {
            // These are a GUESS. The result card must say "please check".
            switch timesPerDay {
            case 1: info.morning = true
            case 2: info.morning = true; info.evening = true
            case 3: info.morning = true; info.noon = true; info.evening = true
            case 4: info.morning = true; info.noon = true; info.evening = true; info.bedtime = true
            default: break
            }
        }

        // 6. Meals
        if compact.contains("ก่อนอาหาร") || latin.contains(#/\bac\b/#) {
            info.mealTiming = .before
        } else if compact.contains("หลังอาหาร") || latin.contains(#/\bpc\b/#) {
            info.mealTiming = .after
        } else if compact.contains("พร้อมอาหาร") {
            info.mealTiming = .with
        }

        // 7. Warnings: keep the whole line so nothing gets lost
        let warningWords = ["ง่วง", "ห้าม", "ระวัง", "ไม่ควร", "จนหมด", "ดื่มน้ำ"]
        info.warnings = lines.filter { line in warningWords.contains { line.contains($0) } || isDailyLimit(line) }
                             .map { $0.trimmingCharacters(in: .whitespaces) }
        return info
    }

    /// "ไม่เกินวันละ 8 เม็ด" on a line of its own: the most a day, which matters as much as a warning.
    static func isDailyLimit(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        return compact.contains("ไม่เกิน") && !compact.contains("ครั้งละ")
            && (compact.contains("วันละ") || compact.contains("ต่อวัน") || compact.contains("ใน1วัน") || compact.contains("ใน24ชั่วโมง"))
    }

    /// Thai digits → 0-9, and fix สระอำ that OCR splits into two characters (ํ + า).
    static func normalize(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars {
            if (0x0E50...0x0E59).contains(u.value), let digit = Unicode.Scalar(u.value - 0x0E50 + 0x30) {
                out.append(digit)
            } else {
                out.append(u)
            }
        }
        return String(out).replacingOccurrences(of: "\u{0E4D}\u{0E32}", with: "\u{0E33}")
    }
}
