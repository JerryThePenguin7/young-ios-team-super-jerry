import SwiftUI

/// A ring that fills up as today's doses are taken, like the Activity rings in Health.
struct TodayProgressRing: View {
    let taken: Int
    let total: Int

    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 92
    @ScaledMetric(relativeTo: .title) private var lineWidth: CGFloat = 12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double {
        total == 0 ? 0 : Double(taken) / Double(total)
    }

    private var isComplete: Bool { total > 0 && taken >= total }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.red.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(isComplete ? Theme.taken : Theme.red,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.title.bold())
                    .foregroundStyle(Theme.taken)
            } else {
                Text("\(taken)/\(total)")
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .padding(lineWidth)
            }
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? nil : .smooth, value: fraction)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ทานแล้ว \(taken) จาก \(total) · \(taken) of \(total) doses taken")
    }
}

#Preview {
    HStack(spacing: 24) {
        TodayProgressRing(taken: 0, total: 4)
        TodayProgressRing(taken: 2, total: 5)
        TodayProgressRing(taken: 3, total: 3)
    }
    .padding()
}
