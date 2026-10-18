---
version: alpha
name: Jenny
description: >-
  Jenny's look, modeled on the Medications page of the Apple Health app. A calm light-gray canvas with
  white cards, red used only as the accent and green for "Taken", Health-style Log cards for each pill time, white medicine
  cards in a swipeable widget stack you tap to spread out, Medicine Storage that counts pills down, and a floating Liquid Glass scan button at the bottom. Built for older Thai adults who take several
  medicines a day, and for the family members who help them, without looking like a "special" app.

colors:
  # Brand red (asset "JennyRed"): icons, red text, the + and ✓ marks. Dark mode: #FF6961.
  primary: "#D32F2F"
  primary-dark-mode: "#FF6961"
  # The red box, pill icons and filled buttons with white text (asset "JennyCard"). Dark mode: #B3261E.
  primary-fill: "#D32F2F"
  primary-fill-dark-mode: "#B3261E"
  on-primary: "#FFFFFF"
  # Page background (asset "JennyBackground"): neutral light gray. Dark mode: black.
  background: "#F2F2F5"
  background-dark-mode: "#000000"
  # Every card: Log, Logged, medicines, reminders, sheets (asset "JennySurface"). Dark mode: #1C1C1E.
  surface: "#FFFFFF"
  surface-dark-mode: "#1C1C1E"
  # Soft gray for secondary buttons and icon circles on a card (asset "JennyFill"). Dark mode: #2C2C2E.
  # Red text on it is 4.57:1 (light) and 4.94:1 (dark).
  fill: "#F5F5F7"
  fill-dark-mode: "#2C2C2E"
  on-surface: "#000000"
  # "Late" and "Running low" states. Always with a word, never color alone.
  late: "#FF9500"
  # "Taken" (asset "JennyGreen"): ✓ marks, green words, week-strip circles. Dark mode: #30D158. 5.14:1 on white.
  taken: "#1E7E34"
  taken-dark-mode: "#30D158"
  # The filled Taken button with white text (asset "JennyGreenFill"), both modes. White on it is 5.14:1.
  taken-fill: "#1E7E34"

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

# Jenny design system

## Overview

Jenny follows the **Medications page of the Apple Health app**, so it should feel just as calm and trustworthy.
The home screen ("ยาของฉัน · Medications") reads top to bottom:

1. **The day and the week:** "วันนี้ 18 ตุลาคม" and a strip of 7 days. Each day's circle fills with green as doses are taken. Tap a day to see its log.
2. **The red box, only when there are no medicines yet:** it explains what Jenny does, with **ถ่ายรูป · Take photo** (white button) and **เลือกจากคลังภาพ · Choose from Photos** (outlined).
3. **Log:** one white card per pill time ("8:00 น.") with the medicines still to take and a round **+**. Tap a card to log them as taken or skipped. A badge shows "ถึงเวลาแล้ว" or "เลยเวลาแล้ว".
4. **Logged:** what was taken (✓) or skipped, by time. Tap a time to change it.
5. **Your Medications:** starts as a **widget stack**, like the Smart Stack on the iPhone and iPad Home Screen: one card in front, the next two peeking out behind it. **Swipe up or down** to flip through them (dots on the right show where you are, with a light tap you can feel). **Tap** to spread them out: the front card springs into its place in the list and the rest drop down after it. The spread-out cards are in groups by what they're for ("Heart & blood pressure", "Diabetes"…), each with a read-aloud button; tap a group's header to fold it. **Stack** packs them back up.
6. **Medicine Storage:** the same kind of widget stack (running low first), one card per medicine: how many are left, a bar, about how many days that lasts, and the warning level. Jenny takes one dose off each time a dose is logged **Taken** (and puts it back if it's changed). **"Running low"** shows at the level the user sets for each medicine (e.g. 10 or 5 left); until they set one, it's about a week's worth. Tap to spread the stack out, then tap a row to set or refill the count and the level.
7. The disclaimer.
8. **The scan bar** (once you have medicines) floats at the bottom in Liquid Glass, where a thumb can reach it: a big red **ถ่ายรูปซองยา** button and a round Photos button.

On iPad, Log and Your Medications (with Medicine Storage) sit side by side.

**The first time** Jenny opens, a short tutorial (`TutorialView`) explains it in 4 big pages: choose the language, scan, log Taken or Skipped, Reminders and Medicine Storage. It has **Skip**, and Settings can show it again.
**Top left** is the light or dark theme button (`AppearanceMenu`): Automatic, Light (white) or Dark (black). The language is chosen on the first tutorial page or in Settings.

**Who it's for.** Our main users are **older Thai adults (60+)** who take several medicines a day, plus the **family members** who set the app up and check on them.
We design for them **quietly**: Jenny looks like a normal Apple app, but every detail works for weaker eyes, shakier hands and less confidence with technology:

- Text is big and grows with the iPhone/iPad text-size setting (Dynamic Type), up to the accessibility sizes.
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
  So Jenny makes every log easy to change, and it says that photos stay on the device.
- Thai trials found pictograms on medicine labels helped elderly patients take their medicine correctly.
  So every medicine kind and meal instruction gets an SF Symbol, not just words.
- Apple Health's Medications page is our model: Log cards, "Taken / Skipped", and a Logged list you can change.

## Colors

- **Tone first: neutrals carry the layout, red is the accent.** Three neutral steps, light to dark:
  - the page (`background`, light gray)
  - the cards (`surface`, white)
  - small fills inside cards (`fill`, soft gray)

  Never use red tints as card or button backgrounds. They look washed out next to the red accent.
- **Red** is Jenny's brand: the scan button and red box, pill icons, the + and ✓ marks, and group headers.
  Use only **one big red call to action per screen**: the scan bar (or red box) on home, and **Taken** or **Done** in the log sheet.
- A red **tint** is allowed only for a *state*: the "ถึงเวลา" chip or badge. The red border on a due Log card is a state too.
- **Green** means taken: the filled **Taken** button (`Theme.greenFill`), ✓ marks, green words and the week-strip circles (`Theme.green`). It makes Taken easy to tell apart from Skipped (red) at a glance.
- **Orange** means late. It always comes with a word ("เลยเวลาแล้ว · Late"). **Text on orange must be dark**, because white on orange is too hard to read.
- In code, colors come from `Theme` (`Theme.red`, `Theme.card`, `Theme.background`, `Theme.surface`, `Theme.fill`, `Theme.green`, `Theme.greenFill`). The light and dark versions live in `Assets.xcassets`. Never hard-code a hex value in Swift.

## Typography

- Use SwiftUI text styles (`.title`, `.title3`, `.headline`, `.body`), never fixed point sizes, so Dynamic Type works.
  Icons drawn at a fixed size (`.system(size:)`) are fine only inside fixed-size circles.
- Section titles ("Log", "Your Medications") use `.title.bold()`. Times and medicine names use `.title3`.
- Avoid `.caption` and `.caption2` for anything a user must read. Badges use `.subheadline.bold()` or bigger.
- Use `.bold()` rather than `fontWeight(.bold)`.

## Layout

- The page is one scrolling column, at most 1100 pt wide. On iPad (regular width), the Log column and the Your Medications column sit side by side.
- Sections are 28 pt apart. Cards use 20 pt padding and 12–14 pt between rows.
- **Never cut text off with "…".** Let it wrap (`.fixedSize(horizontal: false, vertical: true)`), use `ViewThatFits` to put things one above the other when they don't fit side by side, and size fixed things with `@ScaledMetric` so they grow with the text.
- **At accessibility text sizes, rows stack vertically** (icon above text, time above "3 hr. ago") instead of squeezing. Check `dynamicTypeSize.isAccessibilitySize`.
- Keep the main action where a thumb can reach it. In sheets, **Done** sits in a bar fixed at the bottom.

## Elevation & Depth

Flat, like Health. White cards sit on the light-gray background without shadows. Depth only comes from Liquid Glass: the navigation bar, sheets, and the floating scan bar.
The red box uses a soft red gradient (`Theme.card.gradient`) so it stands out as the main feature, and pill icons use the same gradient.

## Shapes

- The red box: 28 pt corners. Cards: 24 pt. Buttons: 16–18 pt. Pill icons, badges and the week-strip circles: fully round.
- Always `RoundedRectangle(cornerRadius:style: .continuous)`, the Apple squircle.

## Components

| Component | File | Notes |
|---|---|---|
| Red box | `Views/CameraCard.swift` | Only shown when there are no medicines yet. White main button plus a white-outlined second button, stacked |
| Scan bar | `Views/ScanBar.swift` | Floats at the bottom (`safeAreaInset`). `.glassProminent` red button plus a `.glass` round Photos button. Max 560 pt wide |
| Week strip | `Views/WeekStrip.swift` | 4 weeks you can page through. Each day's circle fills with the share of doses taken |
| Log card | `Views/LogTimeCard.swift` | A white card. The whole card is the button. Time + badge + a round **+** (gray fill, red plus) + the medicines still to take |
| Log sheet | `Views/DoseLogSheet.swift` | "Log All as Taken", then per medicine **Skipped / Taken**, then **Done** |
| Logged card | `Views/LoggedCard.swift` | ✓ or ⊖ per medicine, "3 hr. ago", tap a time to change it |
| Widget stack | `Views/CardStack.swift` | Smart Stack style, used by Your Medications and Medicine Storage. A vertical paging scroll view, 2 cards peeking out behind (12 pt higher, 6% smaller and a little darker each), page dots on the right, a selection haptic. Tap opens it with `.spring(duration: 0.5, bounce: 0.25)` and `matchedGeometryEffect`, so each card glides into the list. VoiceOver: swipe up or down to change, double-tap to open |
| Medicine groups | `ContentView.swift` (`sectionHeader`) | Shown when the stack is spread out. Tap the header to fold or unfold. Shows the count and a chevron (⌄ open, › closed) |
| Medicine Storage | `Views/MedicineStorageSection.swift`, `Views/StockEditorSheet.swift` | A widget stack, then a list. Count left, a green bar (orange when low), days left, the warning level, "Running low" badge. The sheet also sets the warning level (quick 5 / 10 / 20). The sheet sets or refills the count |
| Directions | `Views/DirectionsView.swift` | The label's own words, big and red, under "วิธีใช้ตามฉลาก (ทุกคำ)". English adds Jenny's summary, marked "check it against the label" |
| Expiry | `Views/ExpiryLabel.swift` | "หมดอายุ 31 ธ.ค. 2570" (Buddhist year in Thai). Expired: red icon and tint; within 30 days: orange. Shown on the card and log sheet only when expired or soon |
| Same medicine twice | `Views/DuplicateMedicineAlert.swift` | Before saving a medicine that's already saved: "You already have this medicine", with **Add anyway** or **Cancel**. Mentions different strengths |
| Tutorial | `Views/TutorialView.swift` | First launch only (`hasSeenTutorial`). Big icon, title and words per page, **Next** at the bottom, **Skip** at the top |
| Medicine card | `Views/MedicineCard.swift` | Label photo (or a pill icon on red), name, kind and strength, schedule, meals, and a round read-aloud button |
| Pill icon | `Views/PillIcon.swift` | SF Symbol for the medicine's kind (tablet, eye drops, inhaler…) on a red circle |
| Big button | `Views/BigButtonLabel.swift` | 60 pt, full width. `filled: true` for the main action |
| Theme menu | `Views/AppearanceMenu.swift` | Top left: Automatic, Light (white), Dark (black). Also in Settings |
| Disclaimer | ContentView, detail, scan result | "ไม่ใช่คำแนะนำทางการแพทย์ · Not medical advice" in footnote style |

## Do's and Don'ts

- **Never summarise the label's directions.** Show and read aloud the label's own words, word for word (`Medicine.labelDirections`, `DirectionsView`).
  A summary can drop something important: "พ่นจมูก 2 ข้าง ข้างละ 2 ที" must never become "พ่นจมูก 2 ครั้ง". Jenny's own summary is only for counting
  pills and reminders, and in English it's labeled as a summary to check against the label.

- Do write every string as `language("ไทย", "English")`, and check both languages.
- Do pair every color with an SF Symbol or a word.
- Do give every icon-only button an `accessibilityLabel` in both languages.
- Do test with the largest Dynamic Type size, dark mode, VoiceOver, and both languages.
- Do use `ContentUnavailableView` for empty states.
- Don't put white text on orange or on light red.
- Don't use red tints as backgrounds for cards or secondary buttons. Use `Theme.surface` and `Theme.fill`.
- Don't use fixed font sizes for text, or `.caption` for anything users must read.
- Don't use a symbol that could scare or mislead. For example, avoid a syringe for a diabetes **tablet**.
- Don't hide features on iPhone that exist on iPad.
- Don't use real people's health data in screenshots or previews. Use the made-up envelopes in `SampleLabels` (PDPA).
- Don't add custom fonts, shadows, emoji icons or decorative gradients beyond the red box. Stay native, like Health.

## Checking a design

- In Claude Code, say "use jenny-design-review on <screen>". With other tools, use [ai/prompts/08-design-review.md](ai/prompts/08-design-review.md).
- Before the demo, run [ai/prompts/09-accessibility-check.md](ai/prompts/09-accessibility-check.md) and test with a real older person using [ai/prompts/10-user-test.md](ai/prompts/10-user-test.md).
- Ideas the research suggests, ranked, are in [docs/design/research.md](docs/design/research.md) section 6.
