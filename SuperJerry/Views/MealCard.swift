import SwiftUI

/// One meal in "Log" as a checklist: "มื้อเช้า", then the medicines still to take around it, in order:
///
///     ก่อนอาหาร · 06:30 น.        ○ Metformin
///     ┌ 🍴 ทานอาหารเช้า · 07:00 น. ┐   ← the meal itself, in the middle
///     หลังอาหาร · 07:15 น.        ○ Amlodipine
///
/// Bedtime ("ก่อนนอน") has no meal block. Tap a tick box when you've taken it: it moves to "Taken"
/// (like ticking off an item in the Reminders app). Press and hold a medicine to mark it skipped; "…" opens the full sheet.
struct MealCard: View {
    @Environment(\.language) private var language
    /// Only the medicines still to take.
    let meal: MealSchedule
    /// Today only: .dueNow shows "Time to take", .missed shows "Late".
    var status: DoseStatus = .upcoming
    /// false for days that haven't come yet.
    var canLog = true
    let tick: (Medicine) -> Void
    let skip: (Medicine) -> Void
    let more: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // One row when it fits; with very big text the badge goes on its own line.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    title
                    badge
                    Spacer(minLength: 8)
                    moreButton
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        title
                        Spacer(minLength: 8)
                        moreButton
                    }
                    badge
                }
            }
            ForEach(meal.parts) { part in
                if part.id == partAfterMeal?.id { mealBlock }
                partSection(part)
            }
            // Only "before eating" medicines: the meal comes after them.
            if hasMealBlock && partAfterMeal == nil { mealBlock }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.accent, lineWidth: status == .dueNow ? 2 : 0)
        }
    }

    // MARK: The meal and its parts

    private var hasMealBlock: Bool { meal.slot != .bedtime }

    /// The first part that comes at or after the meal: the meal block goes right above it.
    private var partAfterMeal: MealPartSchedule? {
        guard hasMealBlock else { return nil }
        return meal.parts.first { $0.part != .before }
    }

    /// "ทานอาหารเช้า · 07:00 น." in a soft block, so the medicines before and after it are easy to place.
    private var mealBlock: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(language("ทาน\(meal.slot.foodName(.thai)) · \(meal.mealTime.label(.thai))",
                          "Eat \(meal.slot.foodName(.english)) · \(meal.mealTime.label(.english))"))
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// "ก่อนอาหาร · 06:30 น.", then its medicines.
    private func partSection(_ part: MealPartSchedule) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(partTitle(part), systemImage: "clock")
                .font(.headline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            ForEach(part.medicines) { medicine in
                row(medicine)
            }
        }
    }

    /// "ก่อนอาหาร · 06:30 น.", "หลังอาหาร · 07:15 น.", or "เวลา 21:00 น." at bedtime and for medicines the label
    /// doesn't say before or after eating.
    private func partTitle(_ part: MealPartSchedule) -> String {
        let time = part.time.label(language)
        guard let name = part.part.name(language) else { return language("เวลา \(time)", "At \(time)") }
        return "\(name) · \(time)"
    }

    /// One checklist row: an empty tick box, the name, how much in short bullets, and anything important.
    private func row(_ medicine: Medicine) -> some View {
        Button {
            tick(medicine)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "circle")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(canLog ? Theme.green : Color.secondary)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.title(language))
                        .font(.title3)
                        .fixedSize(horizontal: false, vertical: true)
                    // How much (the part's title already says when, and before or after eating).
                    // The label's exact words are on the medicine's own screen.
                    BulletList(items: medicine.summaryBullets(language, includeTimes: false, includeMeal: false))
                    // Expired, running low, or a warning from the label: seen before ticking.
                    // The envelope's "หมายเหตุ" notes are left out here; they're on the medicine's own screen.
                    MedicineAlerts(medicine: medicine, showsNotes: false)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canLog)
        .contextMenu {
            if canLog {
                Button(language("ทานแล้ว", "Taken"), systemImage: "checkmark.circle") { tick(medicine) }
                Button(language("ข้าม", "Skipped"), systemImage: "xmark.circle") { skip(medicine) }
            }
        }
        .accessibilityLabel(medicine.title(language))
        .accessibilityValue(language("ยังไม่ได้ทาน", "Not taken yet"))
        .accessibilityHint(language("แตะสองครั้งเมื่อทานแล้ว", "Double-tap when you've taken it"))
        .accessibilityAction(named: language("ข้าม", "Skipped")) { skip(medicine) }
    }

    // MARK: The header

    /// "🌅 มื้อเช้า" / "Breakfast"
    private var title: some View {
        Label {
            Text(meal.slot.mealName(language))
        } icon: {
            Image(systemName: meal.slot.symbol)
                .foregroundStyle(Theme.accent)
        }
        .font(.title3.bold())
        .accessibilityAddTraits(.isHeader)
    }

    /// "…": the full log sheet (Taken or Skipped for each, Log All as Taken, read aloud, open the medicine).
    @ViewBuilder
    private var moreButton: some View {
        if canLog {
            Button(action: more) {
                Image(systemName: "ellipsis")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.fill, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(language("ตัวเลือกเพิ่มเติม เช่น ข้าม หรือทานครบทุกตัว", "More: skip, or log all as taken"))
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch status {
        case .dueNow:
            // Yellow behind the words, a green bell.
            badgeLabel(language("ถึงเวลาแล้ว", "Time to take"), symbol: "bell.fill", color: Theme.accent, background: Theme.yellow)
        case .missed:
            badgeLabel(language("เลยเวลาแล้ว", "Late"), symbol: "exclamationmark.circle.fill", color: .orange)
        default:
            EmptyView()
        }
    }

    /// Dark text on a light tint, with a colored icon: white on orange is too hard to read.
    /// `background` replaces the light tint of `color` (yellow for "Time to take").
    private func badgeLabel(_ title: String, symbol: String, color: Color, background: Color? = nil) -> some View {
        Label {
            Text(title)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background ?? color.opacity(0.18), in: Capsule())
    }
}

#Preview {
    let store = MedicineStore.preview()
    ScrollView {
        VStack {
            ForEach(store.meals(on: Date())) { meal in
                MealCard(meal: meal, status: meal.slot == .morning ? .dueNow : .upcoming,
                         tick: { _ in }, skip: { _ in }, more: {})
            }
        }
        .padding()
    }
    .background(Theme.background)
    .environment(\.language, .thai)
}
