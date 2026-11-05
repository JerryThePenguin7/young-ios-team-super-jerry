import SwiftUI

/// Tap the date above the week: a calendar by month. Scroll up for earlier months (it opens on this one).
/// Each day has its ring, like the week strip: how much of that day's medicine was taken.
/// Tap a day to see its log. Days still to come can't be picked.
struct MonthCalendarSheet: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDay: Date
    let now: Date

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(months, id: \.self) { month in
                        monthCard(month)
                    }
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            // Opens on this month, at the bottom.
            .defaultScrollAnchor(.bottom)
            .background(Theme.background)
            .navigationTitle(language("ปฏิทิน", "Calendar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language("เสร็จ", "Done")) { dismiss() }
                }
            }
        }
    }

    /// From the month of the first medicine (at most a year back) to this month, oldest first.
    private var months: [Date] {
        let calendar = Calendar.current
        let thisMonth = startOfMonth(now)
        let yearAgo = calendar.date(byAdding: .month, value: -11, to: thisMonth) ?? thisMonth
        let first = max(startOfMonth(store.medicines.map(\.addedAt).min() ?? now), yearAgo)
        var months: [Date] = []
        var month = first
        while month <= thisMonth {
            months.append(month)
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = next
        }
        return months
    }

    private func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    // MARK: One month

    private func monthCard(_ month: Date) -> some View {
        let days = days(in: month)
        return VStack(alignment: .leading, spacing: 12) {
            Text(language.month(month))
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 10) {
                ForEach(weekdayHeader(for: month), id: \.self) { day in
                    Text(language.weekdayShort(day))
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityHidden(true)
                }
                ForEach(days.indices, id: \.self) { index in
                    if let day = days[index] {
                        dayButton(day)
                    } else {
                        Color.clear
                            .frame(height: 1)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    /// Blank cells until the month's first weekday, then every day of the month.
    private func days(in month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let count = calendar.range(of: .day, in: .month, for: month)?.count else { return [] }
        let blanks = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
        let dates: [Date?] = (0..<count).map { calendar.date(byAdding: .day, value: $0, to: month) }
        return Array(repeating: nil, count: blanks) + dates
    }

    /// One week's days, starting on the calendar's first weekday, for the "อา. จ. อ. …" header.
    private func weekdayHeader(for month: Date) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: month)?.start ?? month
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func dayButton(_ day: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let isFuture = !isToday && day > now
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let progress = isFuture ? nil : store.progress(on: day)

        return Button {
            selectedDay = calendar.startOfDay(for: day)
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Text(day.formatted(.dateTime.day()))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Theme.accent : (isFuture ? Color.secondary : Color.primary)))
                    .frame(width: 34, height: 34)
                    .background(isSelected ? Theme.accentFill : Color.clear, in: Circle())
                DayRing(progress: progress, isFuture: isFuture)
                    .frame(width: 28, height: 28)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        // The days sit in fixed circles: stop them growing past what fits 7 across.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel(isToday ? language("วันนี้ \(language.longDay(day))", "Today, \(language.longDay(day))")
                                    : language.longDay(day))
        .accessibilityValue(progress.map { language("ใช้ยาแล้ว \(Int($0 * 100))%", "\(Int($0 * 100))% done") } ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var day = Date()
    MonthCalendarSheet(selectedDay: $day, now: Date())
        .environment(MedicineStore.preview())
        .environment(\.language, .thai)
}
