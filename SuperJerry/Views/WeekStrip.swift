import SwiftUI

/// "Today, October 18" and a strip of days (like the Health app). Each day's circle fills up
/// with the doses taken that day. Tap a day to see its log. Swipe for earlier weeks.
struct WeekStrip: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Binding var selectedDay: Date
    let now: Date

    var body: some View {
        VStack(spacing: 12) {
            Text(language.dayTitle(selectedDay, today: now))
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
            Divider()
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
        }
    }

    /// 4 weeks: this week and the 3 before it, starting on the device's first day of the week.
    private var days: [Date] {
        let calendar = Calendar.current
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        guard let first = calendar.date(byAdding: .day, value: -21, to: thisWeek) else { return [] }
        return (0..<28).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
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
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption2)
                    .opacity(isSelected ? 1 : 0)
                Text(language.weekdayLetter(day))
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Theme.red : Color.secondary))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Theme.card : Color.clear, in: Circle())
                ProgressCircle(progress: progress ?? 0)
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            // The letters live in fixed 32 pt circles: cap their size so they aren't cut off,
            // and let people with very big text press and hold to see the day enlarged.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .buttonStyle(.plain)
        .accessibilityShowsLargeContentViewer {
            Label(language.longDay(day), systemImage: "calendar")
        }
        .accessibilityLabel(language.longDay(day))
        .accessibilityValue(progress.map { language("ทานแล้ว \(Int($0 * 100))%", "\(Int($0 * 100))% taken") } ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A circle that fills with green from the bottom: empty = nothing taken, full = everything taken.
private struct ProgressCircle: View {
    let progress: Double

    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.18))
            .overlay {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(Theme.green)
                        .frame(height: proxy.size.height * min(max(progress, 0), 1))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .clipShape(Circle())
    }
}

#Preview {
    @Previewable @State var day = Date()
    WeekStrip(selectedDay: $day, now: Date())
        .padding()
        .environment(MedicineStore.preview())
}
