import SwiftUI

/// A white, rounded card like the ones in Apple's Health app:
/// a colored header (icon + title, with an optional detail on the right), then the content.
struct SummaryCard<Content: View>: View {
    let title: String
    let symbol: String
    var tint: Color = Theme.red
    /// Small gray text on the right of the header, like a time or a count.
    var detail: String?
    /// Draws a border in the tint color, for things that need attention now.
    var highlighted = false
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cornerRadius)

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundStyle(tint)
                Spacer(minLength: 8)
                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: shape)
        .overlay {
            if highlighted {
                shape.strokeBorder(tint, lineWidth: 2)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SummaryCard(title: "ยาของฉัน · My medicines", symbol: "pills.fill", detail: "3") {
            Text("ครั้งละ 1 เม็ด")
                .font(.title.bold())
                .fontDesign(.rounded)
        }
        SummaryCard(title: "ถึงเวลาทานยา · Time to take", symbol: "bell.fill", detail: "8:00 AM", highlighted: true) {
            Text("Metformin")
                .font(.title3.bold())
        }
    }
    .padding()
    .background(Theme.background)
}
