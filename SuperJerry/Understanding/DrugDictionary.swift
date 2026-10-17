import Foundation

/// Friendly Thai names for common medicines, so older users know what each one is for.
/// General category names only, not advice.
nonisolated enum DrugDictionary {
    static let names: [String: String] = [
        "amlodipine": "ยาลดความดันโลหิต",
        "losartan": "ยาลดความดันโลหิต",
        "enalapril": "ยาลดความดันโลหิต",
        "hydrochlorothiazide": "ยาขับปัสสาวะ / ลดความดัน",
        "metformin": "ยาเบาหวาน",
        "glipizide": "ยาเบาหวาน",
        "simvastatin": "ยาลดไขมันในเลือด",
        "atorvastatin": "ยาลดไขมันในเลือด",
        "aspirin": "ยาต้านเกล็ดเลือด",
        "omeprazole": "ยาลดกรดในกระเพาะ",
        "paracetamol": "ยาแก้ปวด ลดไข้",
        "calcium carbonate": "แคลเซียมเสริม",
        "folic acid": "วิตามินโฟลิก",
    ]

    static func friendlyName(for drug: String) -> String? {
        names[drug.lowercased()]
    }
}
