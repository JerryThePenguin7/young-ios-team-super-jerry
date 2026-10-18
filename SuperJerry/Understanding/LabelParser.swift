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
        info.bedtime = compact.contains("ก่อนนอน") || compact.contains("ก่อนเข้านอน") || latin.contains(#/\bhs\b/#)

        // 4. Only when needed
        let asNeededWords = ["เมื่อมีอาการ", "เวลามีอาการ", "เมื่อปวด", "เวลาปวด", "เมื่อมีไข้", "ทุก4-6ชั่วโมง",
                             "เมื่อนอนไม่หลับ", "เมื่อถ่ายเหลว", "เมื่อท้องเสีย", "เมื่อคลื่นไส้", "เมื่อไอ",
                             "เมื่อจำเป็น", "ตามอาการ"]
        info.asNeeded = asNeededWords.contains { compact.contains($0) } || latin.contains(#/\bprn\b/#)

        // 5. Times per day: fill in times only if the label didn't name them
        var timesPerDay = 0
        if let m = compact.firstMatch(of: #/วันละ(\d)ครั้ง/#) { timesPerDay = Int(m.1) ?? 0 }
        if latin.contains(#/\bod\b/#) { timesPerDay = 1 }
        if latin.contains(#/\bbid\b/#) { timesPerDay = 2 }
        if latin.contains(#/\btid\b/#) { timesPerDay = 3 }
        if latin.contains(#/\bqid\b/#) { timesPerDay = 4 }
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
        let warningWords = ["ง่วง", "ห้าม", "ระวัง", "ไม่ควร", "จนหมด", "ดื่มน้ำ", "เขย่า"]
        info.warnings = lines.filter { line in warningWords.contains { line.contains($0) } }
                             .map { $0.trimmingCharacters(in: .whitespaces) }
        return info
    }

    /// Thai digits → 0-9, fix สระอำ that OCR splits into two characters (ํ + า), and fix OCR look-alikes.
    static func normalize(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars {
            if (0x0E50...0x0E59).contains(u.value), let digit = Unicode.Scalar(u.value - 0x0E50 + 0x30) {
                out.append(digit)
            } else {
                out.append(u)
            }
        }
        return fixMisreads(String(out).replacingOccurrences(of: "\u{0E4D}\u{0E32}", with: "\u{0E33}"))
    }

    /// Letters Vision often reads wrong on envelopes (found with tools/envelope-test).
    /// Each fix only applies where the real word belongs, so it can't change other words.
    private static func fixMisreads(_ s: String) -> String {
        // เย็น read as เข็น or เซ็น, and ช้อนชา as ซ้อนชา
        var text = s.replacingOccurrences(of: "เข็น", with: "เย็น")
            .replacingOccurrences(of: "เซ็น", with: "เย็น")
            .replacingOccurrences(of: "ซ้อน", with: "ช้อน")

        // เช้า read as เข้า. But เข้า is a real word on labels ("ก่อนเข้านอน", "พ่นเข้าปาก"),
        // so only fix it after อาหาร or before another time: "หลังอาหารเข้า", "เข้า-เย็น", "เข้า กลางวัน".
        if text.contains("เข้า") {
            text = text.replacing(#/(อาหาร\s*)เข้า/#) { "\($0.1)เช้า" }
            text = text.replacing(#/เข้า(?=[ \t]*(?:[-,\n]|กลางวัน|เย็น|และ|$))/#) { _ in "เช้า" }
        }

        // Thai digits read as look-alikes: ๑ → "9" or "น", ๓ → "ต", ๔ → "«".
        // Only between ครั้งละ and a unit, or วันละ and ครั้ง. No label says "9 tablets" or "9 times a day".
        func digit(_ misread: Substring) -> String {
            switch misread {
            case "9", "น": "1"
            case "ต": "3"
            default: "4"
            }
        }
        if text.contains("ครั้งละ") {
            text = text.replacing(#/(ครั้งละ\s*)(9|น|ต|«)(\s*(?:เม็ด|แคปซูล|ช้อน|ซอง|หยด|พัฟ))/#) {
                "\($0.1)\(digit($0.2))\($0.3)"
            }
        }
        if text.contains("วันละ") {
            text = text.replacing(#/(วันละ\s*)(9|น|ต|«)(\s*ครั้ง)/#) { "\($0.1)\(digit($0.2))\($0.3)" }
        }

        // "5mg" read as "Smg"
        if text.contains("mg") || text.contains("MG") {
            text = text.replacing(#/\b[Ss](\s?)(mg|MG)\b/#) { "5\($0.1)\($0.2)" }
        }
        return text
    }
}
