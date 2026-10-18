# Project status: Jenny (for new AI chats and teammates)

**Read this first in any new chat**, then `AGENTS.md` (rules) and `DESIGN.md` (look).
Last updated: 2026-10-18 (Day 2), after PR #3. Update the "Last updated" line and the lists below whenever something big changes.

## What we're building

**Jenny** is an iPad/iPhone app that helps older Thai adults take their medicines correctly.
You take a photo of a Thai medicine envelope (ซองยา), and Jenny reads it on the device, shows it in big text, reads it aloud in Thai, and remembers it.
It also keeps a daily log of what was taken, like the Medications page in Apple Health.
The idea, the pitch plan and the judge Q&A are in `README.md` and `docs/pill-reader/plan.md` (that plan calls the app ยาใจ; the app is named Jenny).

## How it works (the AI choices, and why)

| Step | How | Files |
|---|---|---|
| Read the label | Apple **Vision** text recognition on the device (Thai + English), using the medicine name list as custom words | `Reading/TextReader.swift` |
| Understand it | Our **Thai label rules** ("ครั้งละ 1 เม็ด วันละ 2 ครั้ง หลังอาหาร"), then matching against `medicine-names.json` (486 medicines), even with OCR spelling mistakes | `Understanding/LabelParser.swift`, `LabelReader.swift`, `MedicineNames.swift`, `DosageForm.swift` |
| Group it | Name list first, then how it's used. For unknown medicines: **Core AI** (iOS 27, optional, behind `#if canImport`), then Apple Intelligence for English names, then "อื่น ๆ" | `Services/MedicineGrouper.swift`, `Models/MedicineGroup.swift` |
| Read it aloud | `AVSpeechSynthesizer` with the Thai or English voice, offline | `Speaking/SpeechReader.swift` |
| Remind | **Apple Reminders** (EventKit): one repeating reminder per medicine per pill time. Jenny sends no notifications itself | `Services/AppleReminders.swift` |
| Save | A JSON file and JPEG label photos, on the device only | `Models/MedicineStore.swift`, `Services/PhotoStore.swift` |

**Decisions already made. Don't redo them without asking the team:**
- **No Foundation Models for understanding labels.** We tested it: it doesn't support Thai, and it blocked medicine text as "sensitive content". See `docs/pill-reader/ai-explained.md`.
- **Everything works offline.** Health data never leaves the device (PDPA). Use only made-up envelopes in tests and screenshots (`Understanding/SampleLabels.swift`, `docs/pill-reader/plan.md` §10.1).
- **One language at a time:** all Thai or all English, picked with the globe menu. Write every string as `language("ไทย", "English")`.
- **Reminders go through Apple Reminders**, not our own notifications.

## The app today (main)

- **Home** (`ContentView.swift`), Health-style:
  - The day and a week strip (`WeekStrip`).
  - **Log** cards per pill time, each with a round **+** (`LogTimeCard`). Tapping one opens the log sheet with Taken / Skipped (`DoseLogSheet`).
  - **Logged** (`LoggedCard`).
  - **Your Medications** in groups you can fold (tap a header).
  - A disclaimer at the bottom.
- **Camera:**
  - When there are no medicines yet, the big red box (`CameraCard`) is at the top.
  - After that, a floating Liquid Glass **scan bar** sits at the bottom (`ScanBar`).
- **Scan result** (`ScanResultView`): what Jenny read, read aloud, Edit / Retake / Save.
- **Medicine detail, editor, settings:** `MedicineDetailView`, `MedicineEditorView`, `SettingsView`.
- **Look:**
  - Light-gray page, white cards, a soft gray fill, and red as the accent only (`Theme.swift`, `DESIGN.md`).
  - Works in dark mode, at the biggest text sizes, and on iPad (two columns).

## Tools for AI agents in this repo

- `DESIGN.md`: the design system. **Read before any UI work.**
- `docs/design/research.md`: research on older users and medication apps, with sources and a ranked list of ideas.
- `.claude/skills/`:
  - `jenny-design-review` (ours): screenshots, scores, personas, an anti-AI-slop check.
  - `swiftui-pro`, `ios-design-guidelines`, `ipados-design-guidelines`: third-party, MIT.
- `ai/prompts/01–11`: copy-paste prompts for other tools (feature, bug, design review, accessibility, user test…).

## How to build and check

```bash
xcodebuild -project SuperJerry.xcodeproj -scheme SuperJerry -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

- **Gotcha:** building with Xcode 27 can rewrite `SuperJerry.xcodeproj/project.pbxproj` and add entries to `SuperJerry/InfoPlist.xcstrings`.
  Don't commit those automatic edits: run `git checkout -- SuperJerry.xcodeproj/project.pbxproj SuperJerry/InfoPlist.xcstrings` (AGENTS.md rules 3–4).
- **Bundle ID** (for `xcrun simctl`): read it from the built app's `Info.plist` (`CFBundleIdentifier`). Don't guess it. It is currently `Jenny.JennyNagig6767`.
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
