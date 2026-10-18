import SwiftUI

/// How to use a medicine, shown big. The label's own words come first, word for word, because a summary
/// can drop something important ("พ่นจมูก 2 ข้าง ข้างละ 2 ที" must not become "พ่นจมูก 2 ครั้ง").
/// In English, Jenny's translated summary is shown under the label's words, marked as a summary to check.
struct DirectionsView: View {
    @Environment(\.language) private var language
    let medicine: Medicine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let directions = medicine.directions {
                Label(language("วิธีใช้ตามฉลาก (ทุกคำ)", "Directions, word for word from the label"),
                      systemImage: "doc.text.fill")
                    .font(.callout.bold())
                    .foregroundStyle(.secondary)
                Text(directions)
                    .font(.title.bold())
                    .foregroundStyle(Theme.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                if language == .english {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Jenny's summary in English (check it against the label):")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text(medicine.amountLine(.english))
                            .font(.title3.bold())
                    }
                }
            } else {
                Text(medicine.amountLine(language))
                    .font(.title.bold())
                    .foregroundStyle(Theme.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    var spray = Medicine.blank
    spray.name = "Otrivin"
    spray.unit = "ที"
    spray.amount = 2
    spray.route = "พ่นจมูกทั้ง 2 ข้าง"
    spray.perSide = true
    spray.labelDirections = "พ่นจมูก 2 ข้าง ข้างละ 2 ที\nวันละ 2 ครั้ง เช้า เย็น"
    return VStack(spacing: 30) {
        DirectionsView(medicine: spray)
        DirectionsView(medicine: spray)
            .environment(\.language, .english)
    }
    .padding()
}
