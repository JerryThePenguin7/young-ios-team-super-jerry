import SwiftUI

/// A new medicine that looks like one already saved.
struct DuplicateCheck {
    let saved: Medicine
    let new: Medicine
}

/// "You already have this medicine": shown before saving the same medicine twice,
/// so nobody takes a double dose by mistake. Add anyway, or Cancel.
struct DuplicateMedicineAlert: ViewModifier {
    @Environment(\.language) private var language
    @Binding var check: DuplicateCheck?
    let addAnyway: (Medicine) -> Void

    func body(content: Content) -> some View {
        content.alert(language("มียานี้อยู่แล้ว", "You already have this medicine"), isPresented: isPresented,
                      presenting: check) { check in
            Button(language("เพิ่มอยู่ดี", "Add anyway")) { addAnyway(check.new) }
            Button(language("ยกเลิก", "Cancel"), role: .cancel) {}
        } message: { check in
            Text(message(check))
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { check != nil }, set: { if !$0 { check = nil } })
    }

    private func message(_ check: DuplicateCheck) -> String {
        let saved = check.saved
        let added = language.date(saved.addedAt)
        var text = language(
            "\(saved.displayName(.thai)) \(saved.strength) บันทึกไว้แล้วเมื่อ \(added) ถ้าเพิ่มซ้ำ อาจทำให้ทานยาซ้ำซ้อน",
            "\(saved.displayName(.english)) \(saved.strength) was already saved on \(added). Adding it again could lead to taking a double dose.")
        let strengths = [saved.strength, check.new.strength].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        if !strengths[0].isEmpty && !strengths[1].isEmpty && strengths[0] != strengths[1] {
            text += language(
                " ขนาดยาไม่เหมือนกัน (\(saved.strength) กับ \(check.new.strength)) โปรดถามเภสัชกรว่าต้องทานตัวไหน",
                " The strengths are different (\(saved.strength) and \(check.new.strength)). Ask your pharmacist which one to take.")
        }
        return text
    }
}

extension View {
    func duplicateMedicineAlert(check: Binding<DuplicateCheck?>, addAnyway: @escaping (Medicine) -> Void) -> some View {
        modifier(DuplicateMedicineAlert(check: check, addAnyway: addAnyway))
    }
}
