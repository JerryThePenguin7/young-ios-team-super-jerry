import SwiftUI

/// Short lines as bullet points: "• ครั้งละ 1 เม็ด", "• หลังอาหาร". Each line wraps, never cut off.
/// In the main text color (black, or white in dark mode), so older eyes can read it easily.
struct BulletList: View {
    let items: [String]
    var font: Font = .callout

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                        .bold()
                        .accessibilityHidden(true)
                    Text(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .font(font)
        .foregroundStyle(.primary)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    BulletList(items: ["พ่นจมูกทั้ง 2 ข้าง ข้างละ 2 ที", "วันละ 2 ครั้ง: เช้า เย็น", "หลังอาหาร"])
        .padding()
}
