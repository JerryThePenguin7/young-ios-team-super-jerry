# 11 — Design or redesign a screen

Use this when you add a new screen or change how one looks. It keeps every screen in the same Apple Health style.

```text
GOAL:        [e.g. "Add 'ข้าม · Skip' next to 'ทานแล้ว' so a skipped dose isn't shown as late."]
CONTEXT:     Read DESIGN.md first and follow it exactly. Files: [e.g. Views/TodayScheduleCard.swift, Models/Medicine.swift].
             Users are Thai adults 60+ (weak eyes, shaky hands, Thai first) and their family.
DESIGN:      - Reuse what exists: SummaryCard, .buttonStyle(.big / .bigProminent / .pressable),
               TintedIconLabelStyle, Theme colors, DoseChips. Don't invent new colors, fonts, or shadows.
             - At most one filled red button per screen. Tap targets 60 pt (main) and never under 52 pt.
             - Thai first, then English, joined by " · ". Every state has an SF Symbol AND a word.
             - Text styles only (no fixed sizes). Stack rows when dynamicTypeSize.isAccessibilitySize.
             - Every icon-only control gets an accessibilityLabel.
CONSTRAINTS: SwiftUI only, iOS 26 target, no iOS 27-only APIs, no new packages, don't touch project settings.
             Synthetic data only in Previews (MedicineStore.preview()).
DONE WHEN:   It builds with xcodebuild, has a #Preview, and looks right in light mode, dark mode,
             and the largest text size.
PROCESS:     Show me a plan and a quick sketch of the layout (a text wireframe is fine) first.
             Wait for my approval before editing.
```

After building it, run [08-design-review.md](08-design-review.md) on the new screen.
