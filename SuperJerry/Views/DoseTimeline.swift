import SwiftUI

/// A "when needed" medicine as a timeline, top to bottom, so it's easy to see when it can be taken again:
///
///     ✓  10:15 น. ทานแล้ว            3 ชม. ที่แล้ว
///     │
///     🕒 ตอนนี้ 13:15 น.              รออีก 3 ชม.
///     │
///     ⏳ 16:15 น. ทานได้อีกครั้ง      ห่างกันอย่างน้อย 6 ชั่วโมง
///
/// Doses from the last 24 hours (so last night's dose still counts), then now, then the next allowed dose.
/// The line is green between doses and orange while waiting.
struct DoseTimeline: View {
    @Environment(\.language) private var language
    let medicine: Medicine
    /// When it was taken in the last 24 hours, oldest first.
    let taken: [Date]
    let now: Date

    private enum Kind { case taken, now, next, ready }

    private struct Step {
        let kind: Kind
        let title: String
        let detail: String?
        /// The line down to the next step.
        let line: Color
    }

    var body: some View {
        let steps = self.steps
        VStack(alignment: .leading, spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                row(steps[index], isLast: index == steps.count - 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: The steps

    private var steps: [Step] {
        let verb = medicine.thaiVerb   // ทาน, or ใช้ for drops and sprays
        let next = taken.last.flatMap(medicine.nextDose(after:))
        let waiting = next.map { $0 > now } ?? false
        var steps: [Step] = []
        for (index, date) in taken.enumerated() {
            let isLastDose = index == taken.count - 1
            steps.append(Step(kind: .taken,
                              title: language("\(when(date)) \(verb)แล้ว", "\(when(date)) Taken"),
                              detail: language.timeAgo(date, now: now),
                              line: isLastDose && waiting ? .orange : Theme.green))
        }
        if let next, waiting {
            steps.append(Step(kind: .now,
                              title: language("ตอนนี้ \(language.time(now))", "Now, \(language.time(now))"),
                              detail: language("รออีก \(timeLeft(until: next))", "\(timeLeft(until: next)) to go"),
                              line: .orange))
            steps.append(Step(kind: .next,
                              title: language("\(when(next)) \(verb)ได้อีกครั้ง", "\(when(next)) Next dose allowed"),
                              detail: medicine.apartText(language),
                              line: .clear))
        } else {
            steps.append(Step(kind: .ready,
                              title: taken.isEmpty ? language("ยังไม่ได้\(verb)วันนี้", "Not taken today")
                                                   : language("ตอนนี้\(verb)ได้", "You can take it now"),
                              detail: language("\(verb)เฉพาะเมื่อมีอาการ", "Only if you need it"),
                              line: .clear))
        }
        return steps
    }

    /// "10:15 น.", or "เมื่อวาน 22:00 น." / "พรุ่งนี้ 04:00 น." when it isn't today.
    private func when(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = language.time(date)
        if calendar.isDate(date, inSameDayAs: now) { return time }
        if date < now { return language("เมื่อวาน \(time)", "Yesterday \(time)") }
        return language("พรุ่งนี้ \(time)", "Tomorrow \(time)")
    }

    /// "3 ชม. 15 นาที" or "3 hr 15 min"
    private func timeLeft(until date: Date) -> String {
        let minutes = max(1, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
        let hours = minutes / 60, rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return language("\(rest) นาที", "\(rest) min")
        case (_, 0): return language("\(hours) ชม.", "\(hours) hr")
        default: return language("\(hours) ชม. \(rest) นาที", "\(hours) hr \(rest) min")
        }
    }

    // MARK: One step

    private func row(_ step: Step, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // The rail: an icon, and a line down to the next step.
            VStack(spacing: 2) {
                icon(step.kind)
                    .font(.title2)
                    .frame(width: 32, height: 32)
                if !isLast {
                    Capsule()
                        .fill(step.line)
                        .frame(width: 3)
                        .frame(minHeight: 14, maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(step.kind == .now ? Color.secondary : Color.primary)
                if let detail = step.detail {
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, isLast ? 0 : 12)
            Spacer(minLength: 0)
        }
        // The rail's line stretches to the height of the words next to it.
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func icon(_ kind: Kind) -> some View {
        switch kind {
        case .taken:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.green)
        case .now:
            Image(systemName: "clock.fill")
                .foregroundStyle(.orange)
        case .next:
            Image(systemName: "hourglass.circle.fill")
                .foregroundStyle(.orange)
        case .ready:
            Image(systemName: "circle")
                .foregroundStyle(Theme.accent)
        }
    }
}

#Preview {
    var paracetamol = Medicine.blank
    paracetamol.name = "Paracetamol"
    paracetamol.asNeeded = true
    paracetamol.slots = []
    paracetamol.hoursApart = 6
    let now = Date()
    return VStack(alignment: .leading, spacing: 30) {
        DoseTimeline(medicine: paracetamol, taken: [now.addingTimeInterval(-8 * 3600), now.addingTimeInterval(-2 * 3600)], now: now)
        DoseTimeline(medicine: paracetamol, taken: [], now: now)
    }
    .padding()
    .environment(\.language, .thai)
}
