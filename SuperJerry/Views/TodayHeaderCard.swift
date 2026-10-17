import SwiftUI

/// The big red card at the top of Today: greeting, Jenny's message, and a progress ring.
struct TodayHeaderCard: View {
    let now: Date
    let taken: Int
    let total: Int
    let message: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 24) {
                textBlock
                Spacer(minLength: 0)
                progressRing
            }
            VStack(alignment: .leading, spacing: 20) {
                textBlock
                progressRing
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(Theme.card.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline.weight(.semibold))
                .opacity(0.85)
            Text(greeting)
                .font(.largeTitle.bold())
            Label {
                Text(message)
            } icon: {
                Image(systemName: "bell.fill")
            }
            .font(.title3.weight(.medium))
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(taken)/\(total)")
                    .font(.title2.bold())
                Text("taken")
                    .font(.caption.weight(.semibold))
            }
        }
        .frame(width: 104, height: 104)
        .animation(.snappy, value: taken)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(taken) of \(total) doses taken today")
    }

    private var progress: Double {
        total == 0 ? 0 : Double(taken) / Double(total)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: now) {
        case ..<12: "Good morning"
        case ..<17: "Good afternoon"
        default: "Good evening"
        }
    }
}

#Preview {
    TodayHeaderCard(
        now: Date(),
        taken: 2,
        total: 5,
        message: "It's time for Metformin now!"
    )
    .padding()
}
