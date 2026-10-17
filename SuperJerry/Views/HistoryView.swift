import SwiftUI
import Charts

/// The last 7 days: how many doses were taken. These numbers are useful for the pitch.
struct HistoryView: View {
    @Environment(MedicineStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weekCard
                    chartCard
                    dayList
                }
                .padding()
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("History")
        }
    }

    private var days: [DaySummary] {
        store.summaries(lastDays: 7, endingOn: Date())
    }

    private var weekCard: some View {
        let taken = days.reduce(0) { $0 + $1.taken }
        let total = days.reduce(0) { $0 + $1.total }
        let percent = total == 0 ? 0 : Int((Double(taken) / Double(total) * 100).rounded())

        return VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days")
                .font(.subheadline.weight(.semibold))
                .opacity(0.85)
            Text("\(percent)% of doses taken")
                .font(.largeTitle.bold())
            Text("\(taken) of \(total) doses · \(total - taken) not taken")
                .font(.title3.weight(.medium))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(Theme.card.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Doses taken each day")
                .font(.headline)
            Chart(days) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Taken (%)", day.percent)
                )
                .foregroundStyle(Theme.red.gradient)
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                }
            }
            .frame(height: 220)
            .accessibilityLabel("Bar chart of the percent of doses taken each day")
        }
        .padding(20)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private var dayList: some View {
        VStack(spacing: 0) {
            ForEach(days.reversed()) { day in
                HStack {
                    Text(day.date.formatted(.dateTime.weekday(.wide).day().month()))
                        .font(.body.weight(.medium))
                    Spacer()
                    Text("\(day.taken) of \(day.total)")
                        .foregroundStyle(.secondary)
                    Image(systemName: symbol(for: day))
                        .foregroundStyle(Theme.red)
                        .frame(width: 28)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                if day.id != days.first?.id {
                    Divider().padding(.leading, 20)
                }
            }
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private func symbol(for day: DaySummary) -> String {
        if day.total == 0 { return "minus.circle" }
        if day.taken >= day.total { return "checkmark.circle.fill" }
        return "exclamationmark.circle"
    }
}

#Preview {
    HistoryView()
        .environment(MedicineStore(inMemory: true))
}
