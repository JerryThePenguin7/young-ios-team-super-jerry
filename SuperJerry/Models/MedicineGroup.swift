import Foundation

/// What a medicine is for, so the home screen can show medicines in groups an older person understands.
nonisolated enum MedicineGroup: String, Codable, CaseIterable, Hashable {
    case heart, diabetes, cholesterol, stomach, pain, infection, breathing, brain
    case eyesEars, skin, vitamins, hormones, bonesJoints, urinary, herbal, other

    /// A short Thai name for this kind of medicine, put in front of a foreign name: "ยาฆ่าเชื้อ (Xyz)". nil for "Other".
    var kindName: String? {
        switch self {
        case .heart: "ยาหัวใจและความดัน"
        case .diabetes: "ยาเบาหวาน"
        case .cholesterol: "ยาลดไขมัน"
        case .stomach: "ยากระเพาะและลำไส้"
        case .pain: "ยาแก้ปวด ลดไข้"
        case .infection: "ยาฆ่าเชื้อ"
        case .breathing: "ยาแก้แพ้ แก้ไอ"
        case .brain: "ยาระบบประสาท"
        case .eyesEars: "ยาตาและหู"
        case .skin: "ยาผิวหนัง"
        case .vitamins: "วิตามิน"
        case .hormones: "ยาฮอร์โมน"
        case .bonesJoints: "ยากระดูกและข้อ"
        case .urinary: "ยาทางเดินปัสสาวะ"
        case .herbal: "ยาสมุนไพร"
        case .other: nil
        }
    }

    var thai: String {
        switch self {
        case .heart: "หัวใจ หลอดเลือด และความดัน"
        case .diabetes: "เบาหวาน"
        case .cholesterol: "ไขมันในเลือด"
        case .stomach: "กระเพาะและลำไส้"
        case .pain: "แก้ปวด ลดไข้"
        case .infection: "ฆ่าเชื้อ"
        case .breathing: "ภูมิแพ้ ไอ หอบหืด"
        case .brain: "สมอง ประสาท และการนอน"
        case .eyesEars: "ตาและหู"
        case .skin: "ผิวหนัง ยาทา"
        case .vitamins: "วิตามินและแร่ธาตุ"
        case .hormones: "ไทรอยด์และฮอร์โมน"
        case .bonesJoints: "กระดูก ข้อ และกล้ามเนื้อ"
        case .urinary: "ต่อมลูกหมากและปัสสาวะ"
        case .herbal: "ยาสมุนไพร ยาแผนไทย"
        case .other: "อื่น ๆ"
        }
    }

    var english: String {
        switch self {
        case .heart: "Heart & blood pressure"
        case .diabetes: "Diabetes"
        case .cholesterol: "Cholesterol"
        case .stomach: "Stomach & digestion"
        case .pain: "Pain & fever"
        case .infection: "Infections"
        case .breathing: "Allergy, cough & breathing"
        case .brain: "Brain, nerves & sleep"
        case .eyesEars: "Eyes & ears"
        case .skin: "Skin & creams"
        case .vitamins: "Vitamins & minerals"
        case .hormones: "Thyroid & hormones"
        case .bonesJoints: "Bones, joints & muscles"
        case .urinary: "Bladder & prostate"
        case .herbal: "Thai herbal medicine"
        case .other: "Other"
        }
    }

    func name(_ language: AppLanguage) -> String {
        language(thai, english)
    }

    var symbol: String {
        switch self {
        case .heart: "heart.fill"
        case .diabetes: "drop.fill"
        case .cholesterol: "chart.line.downtrend.xyaxis"
        case .stomach: "fork.knife"
        case .pain: "bandage.fill"
        case .infection: "cross.case.fill"
        case .breathing: "lungs.fill"
        case .brain: "brain.head.profile.fill"
        case .eyesEars: "eye.fill"
        case .skin: "hand.raised.fill"
        case .vitamins: "pills.circle.fill"
        case .hormones: "staroflife.fill"
        case .bonesJoints: "figure.walk"
        case .urinary: "toilet.fill"
        case .herbal: "leaf.fill"
        case .other: "pills.fill"
        }
    }
}

/// Who put a medicine into its group. Shown on the result screen.
nonisolated enum GroupSource {
    case nameList, rules, coreAI, appleIntelligence

    func label(_ language: AppLanguage) -> String {
        switch self {
        case .nameList: language("จากรายชื่อยา", "From the medicine list")
        case .rules: language("จากวิธีใช้ยา", "From how it's used")
        case .coreAI: language("จัดกลุ่มโดย Core AI ในเครื่อง", "Grouped by Core AI on this device")
        case .appleIntelligence: language("จัดกลุ่มโดย Apple Intelligence ในเครื่อง", "Grouped by Apple Intelligence on this device")
        }
    }
}
