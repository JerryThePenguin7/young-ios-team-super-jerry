import SwiftUI

/// "Today, October 18", a week of days, and how the picked day went (like the Health and Fitness apps).
/// Each day shows its short name ("Mon" / "จ."), its date, and a ring that fills up green as that day's
/// doses are taken. Tap a day to see its summary and its log. Swipe right for earlier weeks.
struct WeekStrip: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Binding var selectedDay: Date
    let now: Date

    var body: some View {
        VStack(spacing: 14) {
            Text(language.dayTitle(selectedDay, today: now))
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        dayButton(day)
                            .containerRelativeFrame(.horizontal, count: 7, spacing: 0)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.trailing)
            DaySummary(day: selectedDay, now: now)
        }
    }

    /// The last 4 weeks, ending today: today is always on the right of the first page, with the 6 days
    /// before it to its left, so the days you can look back on are the ones you see. Swipe for earlier weeks.
    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<28).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    private func dayButton(_ day: Date) -> some View {
        let calendar = Calendar.current
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let isFuture = !isToday && day > now
        let progress = isFuture ? nil : store.progress(on: day)

        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 6) {
                Text(language.weekdayShort(day))
                    .font(.subheadline.bold())
                    .foregroundStyle(isToday ? Theme.accent : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                // The date: filled for the picked day (the focus), red text for today.
                Text(day.formatted(.dateTime.day()))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Theme.accent : Color.primary))
                    .frame(width: 36, height: 36)
                    .background(isSelected ? Theme.accentFill : Color.clear, in: Circle())
                DayRing(progress: progress, isFuture: isFuture)
                    .frame(width: 36, height: 36)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                // Today's whole column gets a soft outline, so "which day is it?" is answered at a glance.
                if isToday {
                    RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1.5)
                        .padding(.horizontal, 2)
                }
            }
            .contentShape(Rectangle())
            // The days live in fixed circles: cap their size so they aren't cut off,
            // and let people with very big text press and hold to see the day enlarged.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .buttonStyle(.pressable)
        .accessibilityShowsLargeContentViewer {
            Label(language.longDay(day), systemImage: "calendar")
        }
        .accessibilityLabel(isToday ? language("วันนี้ \(language.longDay(day))", "Today, \(language.longDay(day))")
                                    : language.longDay(day))
        .accessibilityValue(progress.map { language("ใช้ยาแล้ว \(Int($0 * 100))%", "\(Int($0 * 100))% done") } ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One day's ring, like the Fitness app's: a gray track that fills green as doses are taken,
/// a solid green circle with ✓ when everything was taken, and a faint dashed ring for days still to come.
private struct DayRing: View {
    /// 0...1, or nil when nothing was due that day (or it hasn't come yet).
    let progress: Double?
    let isFuture: Bool

    private let lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            if isFuture {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            } else if let progress, progress >= 1 {
                Circle()
                    .fill(Theme.green)
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
                    .padding(lineWidth / 2)
                Circle()
                    .trim(from: 0, to: max(progress ?? 0, 0))
                    .stroke(Theme.green, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(lineWidth / 2)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Under the week: how the picked day went, in words and a bar. "ใช้ยาแล้ว 3 จาก 4 ครั้ง · ข้าม 1".
/// "ใช้ยา" (use), not "ทาน" (eat): eye drops, sprays and creams aren't eaten.
private struct DaySummary: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    let day: Date
    let now: Date

    var body: some View {
        let counts = self.counts

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(headline(counts), systemImage: symbol(counts))
                    .font(.headline)
                    .foregroundStyle(counts.total > 0 && counts.taken == counts.total ? Theme.green : Color.primary)
                Spacer(minLength: 8)
                if counts.total > 0 && !isFuture {
                    Text("\(counts.taken)/\(counts.total)")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            if counts.total > 0 && !isFuture {
                ProgressView(value: Double(counts.taken), total: Double(counts.total))
                    .tint(Theme.green)
                    .accessibilityHidden(true)
                if counts.skipped > 0 {
                    Text(language("ข้าม \(counts.skipped) ครั้ง", "\(counts.skipped) skipped"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var isFuture: Bool {
        !Calendar.current.isDate(day, inSameDayAs: now) && day > now
    }

    /// Doses due that day, taken, and skipped.
    private var counts: (total: Int, taken: Int, skipped: Int) {
        let slots = store.schedule(on: day)
        var taken = 0, skipped = 0, total = 0
        for slot in slots {
            for medicine in slot.medicines {
                total += 1
                if let record = store.record(for: medicine.id, at: slot.time, on: day) {
                    if record.isSkipped { skipped += 1 } else { taken += 1 }
                }
            }
        }
        return (total, taken, skipped)
    }

    private func headline(_ counts: (total: Int, taken: Int, skipped: Int)) -> String {
        if isFuture { return language("ยังไม่ถึงวันนี้", "This day hasn't come yet") }
        if counts.total == 0 { return language("ไม่มียาที่ต้องใช้วันนี้", "No medicines due this day") }
        if counts.taken == counts.total { return language("ใช้ยาครบทุกตัวแล้ว", "All doses done") }
        return language("ใช้ยาแล้ว \(counts.taken) จาก \(counts.total) ครั้ง", "\(counts.taken) of \(counts.total) doses done")
    }

    private func symbol(_ counts: (total: Int, taken: Int, skipped: Int)) -> String {
        if isFuture { return "calendar" }
        if counts.total > 0 && counts.taken == counts.total { return "checkmark.circle.fill" }
        return "checklist"
    }
}

#Preview {
    @Previewable @State var day = Date()
    WeekStrip(selectedDay: $day, now: Date())
        .padding()
        .background(Theme.background)
        .environment(MedicineStore.preview())
        .environment(\.language, .thai)
}
