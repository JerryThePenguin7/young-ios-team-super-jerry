# Project status: YaoYao (for new AI chats and teammates)

**Read this first in any new chat**, then `AGENTS.md` (rules) and `DESIGN.md` (look).
Last updated: 2026-10-18 (Day 2), after the health professional's fixes: word-for-word directions, expiry dates, and the duplicate warning. Update the "Last updated" line and the lists below whenever something big changes.

## What we're building

**YaoYao** is an iPad/iPhone app that helps older Thai adults take their medicines correctly.
You take a photo of a Thai medicine envelope (ซองยา), and YaoYao reads it on the device, shows it in big text, reads it aloud in Thai, and remembers it.
It also keeps a daily log of what was taken, like the Medications page in Apple Health.
The idea, the pitch plan and the judge Q&A are in `README.md` and `docs/pill-reader/plan.md` (that plan calls the app ยาใจ; the app is named YaoYao).

**Renamed from Jenny to YaoYao on 2026-10-19.** The app is **YaoYao** (logo: the green 药 tile with a capsule, `Assets.xcassets/AppIcon`
and `YaoYaoLogo`), and the assistant that talks to the user is **Yao** ("Yao อ่านฉลาก…", "Yao reads the label…").
Internal code names keep "Jenny" on purpose, so saved data and settings keep working: the color assets (`JennyAccent`…),
the save file `jenny-medicines.json`, the `jenny…` UserDefaults keys, and the `jenny-design-review` skill. Older docs
(`docs/`, `JERRY-NOTES.md`) still say Jenny.
The home-screen name and icon are target settings, set once with the team's OK (an exception to AGENTS.md rule 4):
`INFOPLIST_KEY_CFBundleDisplayName = YaoYao` and `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` (Debug and Release). Keep them.

## How it works (the AI choices, and why)

| Step | How | Files |
|---|---|---|
| Read the label | Apple **Vision** text recognition on the device (Thai + English), using the medicine name list as custom words | `Reading/TextReader.swift` |
| Understand it | Our **Thai label rules** ("ครั้งละ 1 เม็ด วันละ 2 ครั้ง หลังอาหาร"), then matching against `medicine-names.json` (486 medicines), even with OCR spelling mistakes | `Understanding/LabelParser.swift`, `LabelReader.swift`, `MedicineNames.swift`, `DosageForm.swift` |
| Group it | Name list first, then how it's used. For unknown medicines: **Core AI** (iOS 27, optional, behind `#if canImport`), then Apple Intelligence for English names, then "อื่น ๆ" | `Services/MedicineGrouper.swift`, `Models/MedicineGroup.swift` |
| Read it aloud | `AVSpeechSynthesizer` with the Thai or English voice, offline | `Speaking/SpeechReader.swift` |
| Remind | **Apple Reminders** (EventKit): one repeating reminder per medicine per meal, at its time around the meal. YaoYao sends no notifications itself | `Services/AppleReminders.swift` |
| Save | A JSON file and JPEG label photos, on the device only | `Models/MedicineStore.swift`, `Services/PhotoStore.swift` |

**Decisions already made. Don't redo them without asking the team:**
- **No Foundation Models for understanding labels.** We tested it: it doesn't support Thai, and it blocked medicine text as "sensitive content". See `docs/pill-reader/ai-explained.md`.
- **Everything works offline.** Health data never leaves the device (PDPA). Use only made-up envelopes in tests and screenshots (`Understanding/SampleLabels.swift`, `docs/pill-reader/plan.md` §10.1).
- **One language at a time:** all Thai or all English, picked in Settings or on the first tutorial page. Write every string as `language("ไทย", "English")`.
- **Reminders go through Apple Reminders**, not our own notifications.
- **Directions are kept word for word from the label** (advice from a health professional): shown in full on the scan result and the
  medicine's screen, and read aloud as printed. Lists (Log checklist, Your Medications) show YaoYao's summary as bullet points, which must
  never drop a detail ("พ่นจมูก 2 ข้าง ข้างละ 2 ที" must not become "พ่นจมูก 2 ครั้ง").
- **Important things show before ticking:** expired / expiring soon, running low, and label warnings, under each medicine's name.

## The app today (main)

- **Home** (`ContentView.swift`), Health-style:
  - The day and a week strip (`WeekStrip`). Tap the date for a calendar by month (`MonthCalendarSheet`).
  - Two big buttons at the top switch between **Log** and **Your Medications** (`ContentView.tabButtons`).
  - **Log**: a **checklist per meal** (`MealCard`): ก่อนอาหาร, a meal block, then หลังอาหาร, at the user's meal times (`MealTimes`:
    before = 30 min before by default, 10–60 in Settings (`MealTimes.minutesBefore`); after = 15 min after; bedtime never says "หลังอาหาร"). Tap a tick box to mark it taken (press and hold to skip;
    **…** opens `DoseLogSheet`, where a medicine's name opens it in Your Medications). Ticks remember their meal (`DoseRecord.slot`),
    so changing a meal time moves them along; old 8/12/18/21 ticks are upgraded on load.
  - Ticking a dose more than 30 minutes before its time asks first (`MedicineStore.isTooEarly`, `Medicine.earlyTickMessage`).
  - **When needed** (`AsNeededCard`, `DoseTimeline`): at the top, or below the meals via its **…** menu (`@AppStorage("asNeededAtBottom")`). Medicines with no set time (paracetamol).
    A tick box like the meals' (ticked = taken today; tapping it again asks: another one now, or undo the last one, `MedicineStore.undoLastDose`)
    and a timeline of the last 24 hours (doses → now → next allowed, from the label's gap `hoursApart`, "ห่างกันอย่างน้อย 6 ชม."). Logging too soon asks first.
  - **Taken** (`LoggedCard`): ticked medicines, tap to undo.
  - **Your Medications**: a plain list of medicine cards in groups you can fold (the swipe stack was removed on request).
  - **How many are left** (merged into Your Medications): on each card, and a card on the medicine's screen (`StockCard`, `StockEditorSheet`).
    Counted down by itself when a dose is logged Taken, with a "Running low" level set per medicine.
  - Top left: the light or dark theme button (`AppearanceMenu`). **Taken** is green everywhere.
- **Colors** follow the team's reference image: deep green accent, red only for Skipped/expired/delete, yellow behind "Time to take",
  gray-blue background (`Theme.accent`, `accentFill`, `red`, `redFill`, `yellow`; see DESIGN.md). Only the colors, never another app's logo or name.
- **First launch:** a 5-page tutorial with Skip (`TutorialView`), including **your meal times** (`MealTimesEditor`, also in Settings). Settings can show it again.
- **Label reading also keeps:** the directions word for word (`labelDirections`), "ข้างละ" doses per side (`perSide`, counted ×2 in storage),
  the gap between "when needed" doses (`hoursApart`: "ห่างกันอย่างน้อย 6 ชม.", "ทุก 4-6 ชั่วโมง", "every 6 hours"),
  the most a day as a warning ("ไม่เกินวันละ 8 เม็ด"),
  and the expiry date (`expiresOn`; "EXP 12/2027", "หมดอายุ 31/12/2569", "หมดอายุ 5 มี.ค. 70"…; Buddhist years converted).
- **Same medicine twice:** saving a medicine that's already saved asks first (Add anyway / Cancel), on the scan result and when typing one in.
  - A disclaimer at the bottom.
- **Camera:**
  - One floating Liquid Glass **scan button** at the bottom from the first launch (`ScanBar`): tap it, then Take photo or Choose from Photos.
- **Scan result** (`ScanResultView`): what YaoYao read, read aloud, Edit / Retake / Save.
- **Medicine detail, editor, settings:** `MedicineDetailView`, `MedicineEditorView`, `SettingsView` (including **text size**, `TextSize`,
  applied at the root with `.dynamicTypeSize`; pinned bars stop growing at AX1/AX2 so screens don't break).
- **Look:**
  - Light-gray page, white cards, a soft gray fill, and red as the accent only (`Theme.swift`, `DESIGN.md`).
  - Works in dark mode, at the biggest text sizes, and on iPad (two columns).

## Tools for AI agents in this repo

- `DESIGN.md`: the design system. **Read before any UI work.**
- `docs/design/research.md`: research on older users and medication apps, with sources and a ranked list of ideas.
- `.claude/skills/`:
  - `jenny-design-review` (ours): screenshots, scores, personas, an anti-AI-slop check.
  - `swiftui-pro`, `ios-design-guidelines`, `ipados-design-guidelines`: third-party, MIT.
  - `ui-ux-pro-max`: third-party, MIT. A searchable database of 119 UX guidelines plus SwiftUI tips
    (`python3 .claude/skills/ui-ux-pro-max/scripts/search.py "touch target" --domain ux`). Lookups only; DESIGN.md wins.
- `ai/prompts/01–11`: copy-paste prompts for other tools (feature, bug, design review, accessibility, user test…).

## How to build and check

```bash
xcodebuild -project SuperJerry.xcodeproj -scheme SuperJerry -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

- **Gotcha:** building with Xcode 27 can rewrite `SuperJerry.xcodeproj/project.pbxproj` and add entries to `SuperJerry/InfoPlist.xcstrings`.
  Don't commit those automatic edits: run `git checkout -- SuperJerry.xcodeproj/project.pbxproj SuperJerry/InfoPlist.xcstrings` (AGENTS.md rules 3–4).
- **Bundle ID** (for `xcrun simctl`): read it from the built app's `Info.plist` (`CFBundleIdentifier`). Don't guess it. It is currently `YaoYao.JennyNagig6767`.
- **Sample data** in a simulator: `python3 .claude/skills/jenny-design-review/seed_sample_medicines.py <UDID> <bundle id>`. It adds 3 made-up medicines.
- **Language** in a simulator: `xcrun simctl spawn <UDID> defaults write <bundle id> appLanguage th` (or `en`).
- The camera, VoiceOver feel, Apple Reminders alerts and Core AI need the **real iPad**.

## Workflow the team uses

- Branch from `main` (`feature/…`, `design/…`, `docs/…`), commit, push, open a PR into `main`.
  Before merging, check that `main` hasn't moved, review the diff, scan for secrets, and do a fresh build. Never commit straight to `main`.
- The user is a high-school student: explain simply, and reply in their language.

## Still to do

- [ ] **Build on an Intel Mac with Xcode 26.** Only Xcode 27 has been tested so far.
- [ ] Test on the iPad: camera scanning of the 5 fake envelopes, a VoiceOver walk-through, Apple Reminders alerts.
- [ ] **Impact numbers** for the pitch: run the user test in `ai/prompts/10-user-test.md` with a real older person, then fill in the README "Impact" line.
- [ ] Ideas, ranked, in `docs/design/research.md` §6: ticking a reminder logs the dose, a follow-up reminder, meal pictograms, labeled toolbar buttons, a family summary.
- [ ] Design review leftovers (`docs/design/review-2026-10-18.md`): the week strip's future days look like missed days, and the toolbar buttons are icon-only.
- [ ] Remember folded medicine groups after the app restarts (they reset today).
- [ ] Pitch deck (PDF), demo recording, zip the project for staff (`ai/prompts/06-pre-demo-check.md`, `07-pitch-prep.md`).
