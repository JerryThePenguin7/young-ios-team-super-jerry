import Foundation

/// English for the kinds of medicine in Yao's name list, so English titles work like Thai ones:
/// "ยาฆ่าเชื้อแบคทีเรีย (Dicloxacillin)" → "Antibiotic (Dicloxacillin)".
/// Keyed by the list's short Thai description, without its brackets ("ยาฆ่าเชื้อแบคทีเรีย (ทานจนหมด)" → "ยาฆ่าเชื้อแบคทีเรีย").
/// Plain words an older reader knows, general categories only, not advice. A description that isn't here
/// falls back to the medicine's group ("Infection medicine"), so new names in the list still get a kind.
nonisolated enum MedicineKinds {
    static func english(forThai thai: String) -> String? {
        english[thai.trimmingCharacters(in: .whitespaces)]
    }

    static let english: [String: String] = [
        // Heart, blood and blood pressure
        "ยาลดความดันโลหิต": "Blood pressure medicine",
        "ยาโรคหัวใจ": "Heart medicine",
        "ยาขยายหลอดเลือดหัวใจ": "Angina medicine",
        "ยาป้องกันเลือดแข็งตัว": "Blood thinner",
        "ยาต้านเกล็ดเลือด": "Antiplatelet medicine",
        "ยาขับปัสสาวะ": "Water pill",
        "ยาลดไขมันในเลือด": "Cholesterol medicine",
        // Diabetes and hormones
        "ยาเบาหวาน": "Diabetes medicine",
        "อินซูลิน": "Insulin",
        "ยาไทรอยด์ฮอร์โมน": "Thyroid hormone",
        "ยารักษาไทรอยด์เป็นพิษ": "Overactive thyroid medicine",
        "ยาสเตียรอยด์": "Steroid",
        // Infections
        "ยาฆ่าเชื้อแบคทีเรีย": "Antibiotic",
        "ยาฆ่าเชื้อแบคทีเรีย มีทั้งชนิดเม็ดและยาหยอดตา": "Antibiotic",
        "ยาต้านไวรัส": "Antiviral",
        "ยาต้านไวรัสไข้หวัดใหญ่": "Flu antiviral",
        "ยาต้านเชื้อรา": "Antifungal",
        // Stomach and bowels
        "ยาลดกรดในกระเพาะอาหาร": "Stomach acid medicine",
        "ยาระบาย": "Laxative",
        "ยาแก้ท้องเสีย": "Diarrhea medicine",
        "ยาแก้คลื่นไส้ อาเจียน": "Nausea medicine",
        "ยาแก้เมารถ คลื่นไส้": "Motion sickness medicine",
        "ยาขับลม แก้ท้องอืด": "Gas and bloating medicine",
        "ยาแก้ปวดเกร็งท้อง": "Stomach cramp medicine",
        "เกลือแร่ทดแทนการเสียน้ำ": "Rehydration salts",
        // Pain and fever
        "ยาแก้ปวด ลดไข้": "Pain and fever medicine",
        "ยาแก้ปวด ลดอักเสบ": "Pain and swelling medicine",
        "ยาแก้ปวด": "Painkiller",
        "ยาแก้ปวดปลายประสาท": "Nerve pain medicine",
        "ยาคลายกล้ามเนื้อ": "Muscle relaxant",
        "บรรเทาอาการปวดกล้ามเนื้อ": "Muscle pain relief",
        "ยาลดกรดยูริก": "Uric acid medicine",
        "ยารักษาโรคเกาต์": "Gout medicine",
        "ยารักษากระดูกพรุน": "Bone strength medicine",
        "บำรุงข้อ": "Joint supplement",
        // Allergy, cough and breathing
        "ยาแก้แพ้ ลดน้ำมูก": "Allergy medicine",
        "ยาลดน้ำมูก คัดจมูก": "Stuffy nose medicine",
        "ยาแก้ไอ": "Cough medicine",
        "ยาแก้ไอ ขับเสมหะ": "Cough and phlegm medicine",
        "ยาแก้ไอ ชุ่มคอ": "Cough and sore throat medicine",
        "ยาละลายเสมหะ": "Phlegm medicine",
        "ยาขับเสมหะ": "Phlegm medicine",
        "ยาขยายหลอดลม": "Breathing medicine",
        "ยาพ่นขยายหลอดลม": "Breathing inhaler",
        "ยาพ่นป้องกันหอบหืด": "Asthma preventer inhaler",
        "ยาพ่นจมูก ลดจมูกอักเสบ ภูมิแพ้": "Allergy nasal spray",
        "บรรเทาอาการเจ็บคอ ไข้หวัด": "Sore throat and cold relief",
        // Brain, nerves and sleep
        "ยานอนหลับ ยาคลายกังวล": "Sleep and anxiety medicine",
        "ยาต้านซึมเศร้า": "Antidepressant",
        "ยาต้านซึมเศร้า / แก้ปวดปลายประสาท": "Antidepressant and nerve pain medicine",
        "ยากันชัก": "Seizure medicine",
        "ยารักษาอาการทางจิตเวช": "Mental health medicine",
        "ยารักษาอาการสมองเสื่อม": "Memory medicine",
        "ยารักษาโรคพาร์กินสัน": "Parkinson's medicine",
        "ยาแก้เวียนศีรษะ บ้านหมุน": "Dizziness medicine",
        "ช่วยลดความอยากบุหรี่": "Quit-smoking aid",
        // Bladder and prostate
        "ยารักษาต่อมลูกหมากโต": "Prostate medicine",
        "ยาลดปัสสาวะบ่อย กลั้นไม่อยู่": "Bladder control medicine",
        // Eyes
        "ยาหยอดตารักษาต้อหิน": "Glaucoma eye drops",
        "น้ำตาเทียม": "Artificial tears",
        "ยาหยอดตาลดการอักเสบ": "Anti-inflammatory eye drops",
        "ยาหยอดตาฆ่าเชื้อแบคทีเรีย": "Antibiotic eye drops",
        "ยาหยอดตาฆ่าเชื้อและลดการอักเสบ": "Antibiotic and anti-inflammatory eye drops",
        "ยาหยอดตาแก้แพ้ คันตา": "Allergy eye drops",
        "ยาหยอดตาขยายม่านตา": "Pupil-widening eye drops",
        // Skin and creams
        "ยาทาแก้ผื่นคัน อักเสบ": "Rash and itch cream",
        "ยาทาแก้คัน": "Anti-itch cream",
        "ยาทาฆ่าเชื้อรา": "Antifungal cream",
        "ยาทาฆ่าเชื้อแบคทีเรียที่ผิวหนัง": "Antibiotic skin cream",
        "ยาทาแก้ปวด": "Pain relief cream",
        "ยาทาบรรเทาปวดกล้ามเนื้อ": "Muscle pain cream",
        "ยาทาบรรเทาปวดเมื่อย ฟกช้ำ": "Aches and bruises cream",
        "ยาทาแก้ปวดเมื่อย แมลงกัดต่อย": "Aches and insect bites balm",
        "ยาทาแผลไฟไหม้ น้ำร้อนลวก": "Burn cream",
        "ยาทาบรรเทาผื่นคัน เริม งูสวัด": "Rash, cold sore and shingles cream",
        "สมานแผล": "Wound healing medicine",
        "บรรเทาอาการริดสีดวงทวาร": "Hemorrhoid relief",
        // Vitamins and minerals
        "แคลเซียมเสริม": "Calcium supplement",
        "วิตามินดี": "Vitamin D",
        "วิตามินบี": "Vitamin B",
        "วิตามินซี": "Vitamin C",
        "วิตามินโฟลิก": "Folic acid",
        "วิตามินรวม": "Multivitamin",
        "ธาตุเหล็ก": "Iron supplement",
        "เกลือแร่โพแทสเซียม": "Potassium supplement",
        // Thai herbal and traditional medicine
        "ยาแผนไทย": "Thai traditional medicine",
        "สมุนไพร": "Herbal medicine",
        "บรรเทาอาการท้องอืด ท้องเฟ้อ อาหารไม่ย่อย": "Indigestion relief",
        "บรรเทาอาการคลื่นไส้ ท้องอืด": "Nausea and bloating relief",
        "ยาแผนไทย แก้ลมวิงเวียน": "Thai remedy for dizziness",
        "ยาแผนไทย แก้ลมวิงเวียน ใจสั่น": "Thai remedy for dizziness and palpitations",
        "ยาแผนไทย แก้ลมวิงเวียน คลื่นไส้": "Thai remedy for dizziness and nausea",
        "ยาแผนไทย บรรเทาปวดเมื่อย": "Thai remedy for aches",
        "ยาแผนไทย บรรเทาอาการปวดประจำเดือน": "Thai remedy for period pain",
        "ยาแผนไทย บรรเทาไข้ ร้อนใน": "Thai remedy for fever and mouth sores",
        "ยาแผนไทย บรรเทาไข้ตัวร้อน": "Thai remedy for fever",
        "ยาแผนไทย บรรเทาท้องอืด ท้องเฟ้อ": "Thai remedy for bloating",
        "ยาแผนไทย บรรเทาปวดท้อง ท้องอืด": "Thai remedy for stomach ache and bloating",
        "ยาแผนไทย บรรเทาอาการท้องเสีย": "Thai remedy for diarrhea",
        "ยาแผนไทย บรรเทาริดสีดวงทวาร": "Thai remedy for hemorrhoids",
        "ยาแผนไทย บรรเทาปวดตามเส้นเอ็น": "Thai remedy for tendon pain",
        "ยาแผนไทยที่มีกัญชา": "Thai remedy with cannabis",
        "ยาที่มีกัญชา": "Medicine with cannabis",
    ]
}
