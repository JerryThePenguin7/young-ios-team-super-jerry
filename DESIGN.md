---
version: alpha
name: YaoYao
description: >-
  YaoYao's look, modeled on the Medications page of the Apple Health app. A calm light gray-blue canvas with
  white cards, a deep green accent (with red and yellow as small accents) and green for "Taken", Health-style Log cards for each meal (before eating, the meal, after eating), white medicine
  cards in groups you can fold, pill counts that go down by themselves, and a floating Liquid Glass scan button at the bottom. Built for older Thai adults who take several
  medicines a day, and for the family members who help them, without looking like a "special" app.

colors:
  # The palette follows the team's reference image (a Thai public-health app's green, red and yellow).
  # Only the colors are borrowed: never its logo or name. Every text color passes WCAG AA (4.5:1).
  # Main green (asset "JennyAccent"): buttons, icons, links, green text. 5.37:1 on white, 4.59:1 on fill. Dark mode: #3DD598.
  primary: "#007A53"
  primary-dark-mode: "#3DD598"
  # Filled green with white text: the chosen tab, the scan button, pill icons, Done (asset "JennyAccentFill").
  # The reference's own green. White on it is 4.66:1 (light) and 6.13:1 (dark, #00704D).
  primary-fill: "#00855C"
  primary-fill-dark-mode: "#00704D"
  on-primary: "#FFFFFF"
  # Red, only for things that need care: Skipped, expired, delete (asset "JennyRed"). 5.36:1 on white. Dark mode: #FF6B6B.
  danger: "#D11C2F"
  danger-dark-mode: "#FF6B6B"
  # The filled Skipped button with white text (asset "JennyRedFill"). Dark mode: #B3261E.
  danger-fill: "#D11C2F"
  danger-fill-dark-mode: "#B3261E"
  # Yellow, only BEHIND text: the "ถึงเวลาแล้ว · Time to take" badge and chip (asset "JennyYellow").
  # Black on it is 16:1. Dark mode: dark mustard #5E5300 with white text (7.7:1). Never yellow text (1.3:1 on white).
  highlight: "#F3E441"
  highlight-dark-mode: "#5E5300"
  # Page background (asset "JennyBackground"): light gray-blue. Dark mode: black.
  background: "#EEF3F6"
  background-dark-mode: "#000000"
  # Every card: Log, Logged, medicines, reminders, sheets (asset "JennySurface"). Dark mode: #1C1C1E.
  surface: "#FFFFFF"
  surface-dark-mode: "#1C1C1E"
  # Soft gray-blue for secondary buttons and icon circles on a card (asset "JennyFill"). Dark mode: #2C2C2E.
  # Green text on it is 4.59:1, red 4.58:1 (light); 7.41:1 and 5.02:1 (dark).
  fill: "#E8EEF2"
  fill-dark-mode: "#2C2C2E"
  on-surface: "#000000"
  # "Late" and "Running low" states. Always with a word, never color alone.
  late: "#FF9500"
  # "Taken" (asset "JennyGreen"): ✓ marks, green words, week-strip circles. Same green as primary. Dark mode: #3DD598.
  taken: "#007A53"
  taken-dark-mode: "#3DD598"
  # The filled Taken button with white text (asset "JennyGreenFill"). Dark mode: #00704D.
  taken-fill: "#00855C"

typography:
  # Sizes are the iOS defaults at the standard text size. In SwiftUI always use the text style
  # (e.g. .title3) so text grows with the user's Dynamic Type setting.
  section-title:
    fontFamily: "SF Pro, system-ui"
    fontSize: 28px
    fontWeight: 700
  day-title:
    fontFamily: "SF Pro, system-ui"
    fontSize: 22px
    fontWeight: 700
  row:
    fontFamily: "SF Pro, system-ui"
    fontSize: 20px
    fontWeight: 400
  card-title:
    fontFamily: "SF Pro, system-ui"
    fontSize: 17px
    fontWeight: 600
  footnote:
    fontFamily: "SF Pro, system-ui"
    fontSize: 13px
    fontWeight: 400

rounded:
  button: 16px
  box-button: 18px
  card: 24px
  red-box: 28px
  full: 9999px

spacing:
  sm: 8px
  md: 12px
  lg: 16px
  card-padding: 20px
  section: 28px

components:
  red-box:
    backgroundColor: "{colors.primary-fill}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.red-box}"
    padding: "{spacing.card-padding}"
  red-box-main-button:
    backgroundColor: "#FFFFFF"
    textColor: "{colors.primary-fill}"
    rounded: "{rounded.box-button}"
    height: 60px
  log-time-card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "{spacing.card-padding}"
  medicine-card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
  button-primary:
    backgroundColor: "{colors.primary-fill}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.button}"
    height: 60px
  button-secondary:
    backgroundColor: "{colors.fill}"
    textColor: "{colors.primary}"
    rounded: "{rounded.button}"
    height: 60px
  plus-button:
    backgroundColor: "{colors.fill}"
    textColor: "{colors.primary}"
    size: 44px
    rounded: "{rounded.full}"
  scan-bar:
    backgroundColor: "{colors.primary-fill}"
    textColor: "{colors.on-primary}"
    height: 60px
    rounded: "{rounded.full}"
  pill-icon:
    backgroundColor: "{colors.primary-fill}"
    size: 40px
    rounded: "{rounded.full}"
---

# YaoYao design system

## Overview

YaoYao follows the **Medications page of the Apple Health app**, so it should feel just as calm and trustworthy.
The home screen ("ยาของฉัน · Medications") reads top to bottom:

0. **Two big buttons at the top** switch the page: **บันทึกการทานยา · Log** and **ยาของคุณ · Your Medications** (the chosen one filled green). They stay pinned under the navigation bar.
1. **Log ▸ the day and the week:** "วันนี้ 18 ตุลาคม" and a strip of 7 days. Each day's circle fills with green as doses are taken. Tap a day to see its log.
2. **Log ▸ no medicines yet:** a `ContentUnavailableView` pointing to the green scan button at the bottom (the old red box is gone).
3. **Log ▸ checklist by meal:** one white card per meal: **มื้อเช้า · มื้อกลางวัน · มื้อเย็น · ก่อนนอน**, at the times the user eats
   (`MealTimes`, set in the tutorial and Settings; defaults 07:00, 12:00, 17:30, 21:00). Inside: **ก่อนอาหาร · 06:30 น.** (30 minutes
   before; Settings ▸ เวลาอาหาร ▸ ยาก่อนอาหาร picks 10–60), then a **meal block** in the middle ("🍴 ทานอาหารเช้า · 07:00 น."), then **พร้อมอาหาร** and **หลังอาหาร · 07:15 น.**
   (15 minutes after). Bedtime has no meal block and never says "หลังอาหาร". Each medicine has a big tick box (and YaoYao's summary
   as bullets under the name). **Tap the box to tick it off**: it moves to Taken, like completing an item in Reminders. Press and hold
   a medicine to mark it skipped; the round **…** opens the full log sheet, where **tapping a medicine's name** opens it in
   Your Medications. A badge shows "ถึงเวลาแล้ว" or "เลยเวลาแล้ว".
   - **Ticking before the time** (more than 30 minutes early, e.g. a dinner medicine at 10:00) asks first: "ยังไม่ถึงเวลา ·
     Amlodipine ต้องทานหลังอาหารเย็น เวลา 17:45 น. ตอนนี้ 10:00 น. ทานแล้วจริงหรือไม่" (**ยังไม่ได้ทาน** / **ทานแล้ว**). Same on the medicine page chips.
   - **Log ▸ When needed (ยาเมื่อมีอาการ)**, at the top, above breakfast. Its round **…** is a menu: **ดูรายละเอียด** (the log sheet) and
     **ย้ายไปไว้ใต้มื้ออาหาร / ย้ายขึ้นไว้บนสุด**, which moves it below the meals and back (remembered, and the page scrolls to follow it): medicines with no set time, like paracetamol ("ครั้งละ 1 เม็ด ห่างกันอย่างน้อย 6 ชม. เมื่อมีอาการ").
     Each has a **timeline** (`DoseTimeline`): ✓ each dose in the last 24 hours ("10:15 น. ทานแล้ว · 3 ชม. ที่แล้ว"), then
     🕒 "ตอนนี้ 13:15 น. · รออีก 3 ชม.", then ⏳ "16:15 น. ทานได้อีกครั้ง" (green line between doses, orange while waiting).
     Each medicine has the same big **tick box** as the meals (no separate Taken button). It stays ticked for the day; tapping it again
     asks **ทานอีกครั้งตอนนี้** or **ยกเลิกครั้งล่าสุด** (a tick by mistake). Logging it too soon asks first ("ยังไม่ครบเวลา").
     Drops, sprays and inhalers say **ใช้** instead of **ทาน** (`Medicine.thaiVerb`).
4. **Log ▸ Taken (ทานแล้ว):** what was taken (green ✓) or skipped (⊖, struck through), by time. Tap a tick to undo it (back to the checklist); tap a time for its log sheet.
5. **Your Medications ▸ the medicines:** white cards in groups by what they're for ("Heart & blood pressure", "Diabetes"…), always shown as a plain list (the swipe stack was removed: people preferred seeing every card). Each card has a read-aloud speaker next to the name. Tap a group's header to fold it. **Edit** deletes medicines.
6. **How many are left** (this used to be a separate Medicine Storage list): each medicine card shows "เหลือ 24 เม็ด", and the medicine's own screen has a
   **จำนวนยาที่เหลือ · How many are left** card: the count, a bar, about how many days that lasts, the warning level, and a button to set or refill it.
   YaoYao takes one dose off each time a dose is logged **Taken** (and puts it back if it's changed). **"Running low"** shows at the level the user sets
   for each medicine (e.g. 10 or 5 left); until they set one, it's about a week's worth.
7. The disclaimer.
8. **The scan bar** floats at the bottom in Liquid Glass from the very first launch, where a thumb can reach it: one big green **ถ่ายรูปซองยา · Scan a medicine label** button. Tapping it asks **ถ่ายรูป · Take photo** or **เลือกจากคลังภาพ · Choose from Photos** (with no camera, it goes straight to Photos).

The page is one column on iPhone and iPad (at most 800 pt wide), since the two buttons switch between Log and Your Medications.

**The first time** YaoYao opens, a short tutorial (`TutorialView`) explains it in 5 big pages: choose the language, scan, **your meal times** (`MealTimesEditor`), log Taken or Skipped, Reminders and pill counts. It has **Skip**, and Settings can show it again.
**Top left** is the light or dark theme button (`AppearanceMenu`): Automatic, Light (white) or Dark (black). The language is chosen on the first tutorial page or in Settings.

**Who it's for.** Our main users are **older Thai adults (60+)** who take several medicines a day, plus the **family members** who set the app up and check on them.
We design for them **quietly**: YaoYao looks like a normal Apple app, but every detail works for weaker eyes, shakier hands and less confidence with technology:

- Text is big and grows with the iPhone/iPad text-size setting (Dynamic Type), up to the accessibility sizes.
  **Settings ▸ ขนาดตัวอักษร** (`TextSize`) sets it for YaoYao only: ตามเครื่อง (follows the device, up to AX3), ปกติ, ใหญ่, ใหญ่มาก,
  ใหญ่พิเศษ (AX1) or ใหญ่ที่สุด (AX2), applied with `.dynamicTypeSize` at the root. Things pinned to the screen stop growing
  so the content stays visible: the Log / Your Medications buttons at AX1, the scan bar at AX2, day circles at xxLarge.
- Main tap targets are **60 pt** tall, and nothing you tap is smaller than **44 pt** (Apple's minimum). Aim for 52 pt or more.
- **One language at a time**: all Thai or all English, picked in Settings (or the first tutorial page). Write every string as `language("ไทย", "English")`.
- Each screen has **one** obvious next step.
- Nothing relies on color alone. Every state has an icon **or** a word (✓ ทานแล้ว, ข้าม, เลยเวลาแล้ว).
- Medicines can be **read aloud**.

It never feels babyish or "for old people". Family members use it too, and nobody likes an app that talks down to them.

**Why these rules** (sources in [docs/design/research.md](docs/design/research.md)):
- A review of 74 studies on health apps for older adults recommends large sans-serif text, high contrast, simple taps, labeled buttons, a flat structure with the main functions on the home screen, and audio alongside text.
- Studies on iPads with people aged 62–84 point to about 18 pt text. Our rows use `.title3` (20 pt) and grow with Dynamic Type.
- In a study of 1,100 Thai adults aged 45+, people with a chronic disease were *less* likely to want a health app. Fear of mistakes and privacy worries held people back.
  So YaoYao makes every log easy to change, and it says that photos stay on the device.
- Thai trials found pictograms on medicine labels helped elderly patients take their medicine correctly.
  So every medicine kind and meal instruction gets an SF Symbol, not just words.
- Apple Health's Medications page is our model: Log cards, "Taken / Skipped", and a Logged list you can change.

## Colors

- **Tone first: neutrals carry the layout, green is the accent.** Three neutral steps, light to dark:
  - the page (`background`, light gray-blue)
  - the cards (`surface`, white)
  - small fills inside cards (`fill`, soft gray-blue)

  Never use green tints as card or button backgrounds. They look washed out next to the green accent.
- **Green** is YaoYao's brand (`Theme.accent`, `Theme.accentFill`): the scan button, the chosen home button, pill icons, icons and group headers.
  Use only **one big filled call to action per screen**: the scan bar on home, and **Taken** or **Done** in the log sheet.
  Green also means taken: the filled **Taken** button (`Theme.greenFill`), ✓ marks and the week-strip circles (`Theme.green`).
- **Red** (`Theme.red`, `Theme.redFill`) is only for things that need care: **Skipped**, expired, delete. Taken (green) and Skipped (red) are easy to tell apart.
- **Yellow** (`Theme.yellow`) is only a background behind text, for a *state*: the "ถึงเวลาแล้ว · Time to take" badge and chip.
  A due Log card also gets a green border. Never use yellow for text or thin lines: it can't be read on white.
- **Orange** means late. It always comes with a word ("เลยเวลาแล้ว · Late"). **Text on orange must be dark**, because white on orange is too hard to read.
- In code, colors come from `Theme` (`Theme.accent`, `Theme.accentFill`, `Theme.red`, `Theme.redFill`, `Theme.yellow`, `Theme.background`, `Theme.surface`, `Theme.fill`, `Theme.green`, `Theme.greenFill`). The light and dark versions live in `Assets.xcassets`. Never hard-code a hex value in Swift.

## Typography

- Use SwiftUI text styles (`.title`, `.title3`, `.headline`, `.body`), never fixed point sizes, so Dynamic Type works.
  Icons drawn at a fixed size (`.system(size:)`) are fine only inside fixed-size circles.
- Section titles ("Log", "Your Medications") use `.title.bold()`. Times and medicine names use `.title3`.
- Avoid `.caption` and `.caption2` for anything a user must read. Badges use `.subheadline.bold()` or bigger.
- Use `.bold()` rather than `fontWeight(.bold)`.

## Layout

- The page is one scrolling column, at most 800 pt wide, on iPhone and iPad. The Log / Your Medications buttons switch what it shows.
- Sections are 28 pt apart. Cards use 20 pt padding and 12–14 pt between rows.
- **Never cut text off with "…".** Let it wrap (`.fixedSize(horizontal: false, vertical: true)`), use `ViewThatFits` to put things one above the other when they don't fit side by side, and size fixed things with `@ScaledMetric` so they grow with the text.
- **At accessibility text sizes, rows stack vertically** (icon above text, time above "3 hr. ago") instead of squeezing. Check `dynamicTypeSize.isAccessibilitySize`.
- Keep the main action where a thumb can reach it. In sheets, **Done** sits in a bar fixed at the bottom.

## Elevation & Depth

Flat, like Health. White cards sit on the light-gray background without shadows. Depth only comes from Liquid Glass: the navigation bar, sheets, and the floating scan bar.
Pill icons use a soft green gradient (`Theme.accentFill.gradient`).

## Shapes

- Cards: 24 pt. Buttons: 16–18 pt. Pill icons, badges and the week-strip circles: fully round.
- Always `RoundedRectangle(cornerRadius:style: .continuous)`, the Apple squircle.

## Components

| Component | File | Notes |
|---|---|---|
| Home buttons | `ContentView.swift` (`tabButtons`) | Log / Your Medications, at least 60 pt: the icon above the words, both centered. Side by side (one above the other with very big text), pinned with `safeAreaInset(edge: .top)` on `.bar` |
| Scan bar | `Views/ScanBar.swift` | Floats at the bottom (`safeAreaInset`) from the first launch. One `.glassProminent` green button; a `confirmationDialog` offers Take photo / Choose from Photos (`photosPicker(isPresented:)`). Max 560 pt wide |
| Week strip | `Views/WeekStrip.swift` | 4 weeks you can page through. Each day's circle fills with the share of doses taken. Under it: "ใช้ยาแล้ว 3 จาก 4 ครั้ง" ("ใช้ยา", not "ทาน": drops and creams aren't eaten). The date on top (with a green ⌄) opens the month calendar |
| Month calendar | `Views/MonthCalendarSheet.swift` | A popover on iPad, a sheet on iPhone. One white card per month ("ตุลาคม 2569"), scroll up for earlier months (up to a year, from the first medicine). Each day has its ring (`DayRing`); tap a day to see it. Days to come are dimmed |
| Text size | `Models/TextSize.swift`, `SettingsView.swift` | An inline list in Settings; each choice is drawn at its own size |
| Read aloud automatically | `SettingsView.swift` (2nd section), `ScanResultView.swift` | `@AppStorage("autoReadAloud")`, on by default: YaoYao reads the label aloud right after each photo. The switch is near the top of Settings and under the scan result's "อ่านออกเสียง" button. The speaker buttons always work |
| Meal card (Log) | `Views/MealCard.swift` | A white card per meal: meal name + badge + round **…** (full sheet), then parts in order: ก่อนอาหาร, the meal block (`Theme.fill`, fork and knife), พร้อมอาหาร / at the meal, หลังอาหาร, each with its time. One row per medicine: a 44 pt tick box (green ring), the name, the amount as bullets (`BulletList`, no meal word: the part says it), and alerts (`MedicineAlerts`). Tap = taken; press and hold = Taken / Skipped menu |
| Meal times | `Views/MealTimesEditor.swift`, `Models/MealTimes.swift` | One time picker per meal and bedtime (24-hour in Thai). In the tutorial and Settings. Changing a time moves every tick with its meal |
| When needed | `Views/AsNeededCard.swift`, `Views/DoseTimeline.swift` | At the top of Log, or below the meals (a labeled move button; `asNeededAtBottom`). A white card: "ยาเมื่อมีอาการ", then per medicine the name, bullets (incl. "ห่างกันอย่างน้อย 6 ชั่วโมง"), alerts, a timeline on `fill` (doses → now → next allowed), and a full-width green **Taken** button. Too soon → an alert first |
| Log sheet | `Views/DoseLogSheet.swift` | "ยามื้อเช้า": "Log All as Taken", then per medicine "หลังอาหารเช้า · 07:15 น." and **Skipped / Taken**, then **Done**. The name (with a green ›) saves the choices, closes the sheet and opens the medicine in Your Medications |
| Taken card | `Views/LoggedCard.swift` | "ทานแล้ว · Taken" in green, grouped by meal ("มื้อเช้า"; "when needed" doses by time). ✓ (green) or ⊖ (struck through) per medicine, "3 hr. ago". Tap a row to undo, tap a meal for its sheet |
| Medicine groups | `ContentView.swift` (`sectionHeader`) | Tap the header to fold or unfold. Shows the count and a chevron (⌄ open, › closed) |
| How many are left | `Views/StockCard.swift`, `Views/StockEditorSheet.swift` | On the medicine's screen. Count left, a green bar (orange when low), days left, the warning level, "Running low" badge, and a set / refill button. The sheet sets or refills the count and the warning level (quick 5 / 10 / 20) |
| Directions | `Views/DirectionsView.swift` | The label's own words, big and green, under "วิธีใช้ตามฉลาก (ทุกคำ)". English adds YaoYao's summary, marked "check it against the label" |
| Expiry | `Views/ExpiryLabel.swift` | "หมดอายุ 31 ธ.ค. 2570" (Buddhist year in Thai). Expired: red icon and tint; within 30 days: orange. Shown on the card and log sheet only when expired or soon |
| Same medicine twice | `Views/DuplicateMedicineAlert.swift` | Before saving a medicine that's already saved: "You already have this medicine", with **Add anyway** or **Cancel**. Mentions different strengths |
| Tutorial | `Views/TutorialView.swift` | First launch only (`hasSeenTutorial`). Big icon, title and words per page, **Next** at the bottom, **Skip** at the top |
| Medicine card | `Views/MedicineCard.swift` | Label photo (or a pill icon on green), the name with a plain green speaker right next to it (read aloud, no circle), kind and strength, YaoYao's summary as bullets (how much, when, meals), alerts (`MedicineAlerts`), and the › arrow centered on the right. The card is split into several links so the speaker can sit inside it |
| Pill icon | `Views/PillIcon.swift` | SF Symbol for the medicine's kind (tablet, eye drops, inhaler…) on a green circle |
| Big button | `Views/BigButtonLabel.swift` | 60 pt, full width. `filled: true` for the main action |
| Theme menu | `Views/AppearanceMenu.swift` | Top left: Automatic, Light (white), Dark (black). Also in Settings |
| Disclaimer | ContentView, detail, scan result | "ไม่ใช่คำแนะนำทางการแพทย์ · Not medical advice" in footnote style |

## Do's and Don'ts

- **Keep the label's directions word for word** (`Medicine.labelDirections`): the scan result and the medicine's own screen show them in full
  (`DirectionsView`), and the voice reads them as printed. Short lists (the Log checklist, Your Medications) show YaoYao's summary
  as bullet points instead (`summaryBullets`, `BulletList`), e.g. "• พ่นจมูกทั้ง 2 ข้าง ข้างละ 2 ที • วันละ 2 ครั้ง: เช้า เย็น".
  The summary must never drop a detail: "พ่นจมูก 2 ข้าง ข้างละ 2 ที" must never become "พ่นจมูก 2 ครั้ง".
- **Show what matters before the tick:** expired or expiring soon, running low, and the label's warnings appear under the medicine's
  name in the checklist and on its card (`MedicineAlerts`).
- **Say what a foreign name is.** In Thai, lists show what the medicine is first, then its name in brackets (`Medicine.title`):
  from the name list ("ยาฆ่าเชื้อแบคทีเรีย (Dicloxacillin)"), else how it's used ("ยาหยอดตา (Poly)", "ยาพ่นจมูก (Otrivin)"),
  else its group from the rules or the AI ("ยาเบาหวาน (Xyz)"). Thai names like "ฟ้าทะลายโจร" stay as they are.
- **The envelope's "หมายเหตุ" notes stay out of the Log** (checklist, When needed, log sheet). They're on the medicine's own screen and card.
- **"When needed" medicines keep their gap:** "ห่างกันอย่างน้อย 6 ชั่วโมง" is always one of their bullets, and YaoYao never lets
  a second dose be logged before the gap without asking.
- **Bullets are in the main text color** (black, or white in dark mode), not gray, so they're easy to read. The envelope's
  "หมายเหตุ" heading is left out of warnings (`cleanWarnings`); the note itself is kept.

- Do write every string as `language("ไทย", "English")`, and check both languages.
- Do pair every color with an SF Symbol or a word.
- Do give every icon-only button an `accessibilityLabel` in both languages.
- Do test with the largest Dynamic Type size, dark mode, VoiceOver, and both languages.
- Do use `ContentUnavailableView` for empty states.
- Don't put white text on orange, yellow or light green.
- Don't use green or red tints as backgrounds for cards or secondary buttons. Use `Theme.surface` and `Theme.fill`.
- Don't use fixed font sizes for text, or `.caption` for anything users must read.
- Don't use a symbol that could scare or mislead. For example, avoid a syringe for a diabetes **tablet**.
- Don't hide features on iPhone that exist on iPad.
- Don't use real people's health data in screenshots or previews. Use the made-up envelopes in `SampleLabels` (PDPA).
- Don't add custom fonts, shadows, emoji icons or decorative gradients beyond the pill icons. Stay native, like Health.

## Checking a design

- In Claude Code, say "use jenny-design-review on <screen>". With other tools, use [ai/prompts/08-design-review.md](ai/prompts/08-design-review.md).
- Before the demo, run [ai/prompts/09-accessibility-check.md](ai/prompts/09-accessibility-check.md) and test with a real older person using [ai/prompts/10-user-test.md](ai/prompts/10-user-test.md).
- Ideas the research suggests, ranked, are in [docs/design/research.md](docs/design/research.md) section 6.
