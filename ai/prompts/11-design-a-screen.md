# 11 — Design or redesign a screen

Use this when you add a new screen or change how one looks. It keeps every screen in the same Apple Health style.

```text
GOAL:        [e.g. "Add 'Taken' and 'Remind me in 10 min' buttons to the pill-time reminder notification."]
CONTEXT:     Read DESIGN.md first and follow it exactly. Files: [e.g. Services/AppleReminders.swift, Views/DoseLogSheet.swift].
             Users are Thai adults 60+ (weak eyes, shaky hands, unsure with tech) and their family.
DESIGN:      - Reuse what exists: the red box (CameraCard), LogTimeCard, BigButtonLabel, PillIcon, Theme colors.
               Don't invent new colors, fonts, corner radii, or shadows.
             - One big red call to action per screen. Tap targets 60 pt (main) and never under 44 pt.
             - Every string is language("ไทย", "English"). Every state has an SF Symbol or a word.
             - No AI slop: no hero/welcome sections, emoji icons, left-stripe cards, cards in cards, or bare "+" labels.
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
