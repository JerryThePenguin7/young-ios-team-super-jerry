import SwiftUI

/// "When do you eat?": one time picker per meal and for bedtime. Yao's pill times follow these:
/// ก่อนอาหาร 30 minutes before (Settings can change it), หลังอาหาร 15 minutes after. Used in the tutorial and in Settings.
/// Rows only, so it fits in a Settings `Section` or in a card.
struct MealTimesEditor: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.language) private var language

    var body: some View {
        ForEach(TimeSlot.allCases, id: \.self) { slot in
            DatePicker(selection: binding(for: slot), displayedComponents: .hourAndMinute) {
                Label {
                    Text(slot.mealName(language))
                } icon: {
                    Image(systemName: slot.symbol)
                        .foregroundStyle(Theme.accent)
                }
                .font(.title3)
            }
            .frame(minHeight: 44)
            // 24-hour times in Thai, AM/PM in English, whatever the iPad is set to.
            .environment(\.locale, language.locale)
        }
    }

    /// The meal's time as a Date for the picker; picking a time saves it right away.
    private func binding(for slot: TimeSlot) -> Binding<Date> {
        Binding(
            get: { store.mealTimes.time(of: slot).date(on: Date()) },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                var meals = store.mealTimes
                meals.set(DoseTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0), for: slot)
                store.setMealTimes(meals)
            }
        )
    }
}

#Preview {
    Form {
        Section("เวลาอาหาร") {
            MealTimesEditor()
        }
    }
    .environment(MedicineStore.preview())
    .environment(\.language, .thai)
}
