---
version: alpha
name: Jenny
description: >-
  Jenny's look, modeled on the Medications page of the Apple Health app. A warm white canvas,
  one big red box for the main feature (scan a medicine label), Health-style Log cards for each pill time,
  and white medicine cards grouped by what they're for. Built for older Thai adults who take several
  medicines a day, and for the family members who help them, without looking like a "special" app.

colors:
  # Brand red (asset "JennyRed"): icons, red text, the + and ✓ marks. Dark mode: #FF6961.
  primary: "#D32F2F"
  primary-dark-mode: "#FF6961"
  # The red box, pill icons and filled buttons with white text (asset "JennyCard"). Dark mode: #B3261E.
  primary-fill: "#D32F2F"
  primary-fill-dark-mode: "#B3261E"
  on-primary: "#FFFFFF"
  # Page background (asset "JennyBackground"): warm white. Dark mode: #140A0B.
  background: "#FFF5F5"
  background-dark-mode: "#140A0B"
  # Medicine cards, sheets' cards, reminder card (asset "JennySurface"). Dark mode: #261416.
  surface: "#FFFFFF"
  surface-dark-mode: "#261416"
  # Log cards: brand red at 8% on the background. Logged card: primary at 5%.
  log-card: "color-mix(in srgb, #D32F2F 8%, #FFF5F5)"
  on-surface: "#000000"
  # "Late" state. Always with a word, never color alone.
  late: "#FF9500"

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
    backgroundColor: "{colors.log-card}"
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
    backgroundColor: "color-mix(in srgb, #D32F2F 12%, transparent)"
    textColor: "{colors.primary}"
    rounded: "{rounded.button}"
    height: 60px
  pill-icon:
    backgroundColor: "{colors.primary-fill}"
    size: 40px
    rounded: "{rounded.full}"
---

# Jenny design system

## Overview

Jenny follows the **Medications page of the Apple Health app**, so it should feel just as calm and trustworthy.
The home screen ("ยาของฉัน · Medications") reads top to bottom:

1. **The day and the week:** "วันนี้ 18 ตุลาคม" and a strip of 7 days. Each day's circle fills with red as doses are taken. Tap a day to see its log.
2. **The red box:** Jenny's main feature. **ถ่ายรูป · Take photo** (white button) and **เลือกจากคลังภาพ · Choose from Photos** (outlined).
3. **Log:** one card per pill time ("8:00 น.") with the medicines still to take. Tap a card to log them as taken or skipped. A badge shows "ถึงเวลาแล้ว" or "เลยเวลาแล้ว".
4. **Logged:** what was taken (✓) or skipped, by time. Tap a time to change it.
5. **Your Medications:** white cards grouped by what they're for ("Heart & blood pressure", "Diabetes"…), each with a read-aloud button.
6. The disclaimer.

On iPad, Log and Your Medications sit side by side.

**Who it's for.** Our main users are **older Thai adults (60+)** who take several medicines a day, plus the **family members** who set the app up and check on them.
We design for them **quietly**: Jenny looks like a normal Apple app, but every detail works for weaker eyes, shakier hands and less confidence with technology:

- Text is big and grows with the iPhone/iPad text-size setting (Dynamic Type), up to the accessibility sizes.
- Main tap targets are **60 pt** tall, and nothing you tap is smaller than **44 pt** (Apple's minimum). Aim for 52 pt or more.
- **One language at a time**: all Thai or all English, picked with the globe menu. Write every string as `language("ไทย", "English")`.
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

- **Red** is Jenny's brand: the red box, pill icons, the + and ✓ marks, and group headers.
  Use only **one big red call to action per screen**: the red box on home, and **Taken** or **Done** in the log sheet.
- **Warm white background** (`#FFF5F5`) with **white cards**. Log cards are a soft red tint, and the Logged card is a soft gray tint.
- **Orange** means late. It always comes with a word ("เลยเวลาแล้ว · Late"). **Text on orange must be dark**, because white on orange is too hard to read.
- In code, colors come from `Theme` (`Theme.red`, `Theme.card`, `Theme.background`, `Theme.surface`). The light and dark versions live in `Assets.xcassets`. Never hard-code a hex value in Swift.

## Typography

- Use SwiftUI text styles (`.title`, `.title3`, `.headline`, `.body`), never fixed point sizes, so Dynamic Type works.
  Icons drawn at a fixed size (`.system(size:)`) are fine only inside fixed-size circles.
- Section titles ("Log", "Your Medications") use `.title.bold()`. Times and medicine names use `.title3`.
- Avoid `.caption` and `.caption2` for anything a user must read. Badges use `.subheadline.bold()` or bigger.
- Use `.bold()` rather than `fontWeight(.bold)`.

## Layout

- The page is one scrolling column, at most 1100 pt wide. On iPad (regular width), the Log column and the Your Medications column sit side by side.
- Sections are 28 pt apart. Cards use 20 pt padding and 12–14 pt between rows.
- **At accessibility text sizes, rows stack vertically** (icon above text, time above "3 hr. ago") instead of squeezing. Check `dynamicTypeSize.isAccessibilitySize`.
- Keep the main action where a thumb can reach it. In sheets, **Done** sits in a bar fixed at the bottom.

## Elevation & Depth

Flat, like Health. Cards sit on the background without shadows. Depth only comes from the system's Liquid Glass bars and sheets.
The red box uses a soft red gradient (`Theme.card.gradient`) so it stands out as the main feature, and pill icons use the same gradient.

## Shapes

- The red box: 28 pt corners. Cards: 24 pt. Buttons: 16–18 pt. Pill icons, badges and the week-strip circles: fully round.
- Always `RoundedRectangle(cornerRadius:style: .continuous)`, the Apple squircle.

## Components

| Component | File | Notes |
|---|---|---|
| Red box | `Views/CameraCard.swift` | White main button plus a white-outlined second button. The buttons sit side by side when there's room (`ViewThatFits`) |
| Week strip | `Views/WeekStrip.swift` | 4 weeks you can page through. Each day's circle fills with the share of doses taken |
| Log card | `Views/LogTimeCard.swift` | The whole card is the button. Time + badge + the medicines still to take |
| Log sheet | `Views/DoseLogSheet.swift` | "Log All as Taken", then per medicine **Skipped / Taken**, then **Done** |
| Logged card | `Views/LoggedCard.swift` | ✓ or ⊖ per medicine, "3 hr. ago", tap a time to change it |
| Medicine card | `Views/MedicineCard.swift` | Label photo (or a pill icon on red), name, kind and strength, schedule, meals, and a round read-aloud button |
| Pill icon | `Views/PillIcon.swift` | SF Symbol for the medicine's kind (tablet, eye drops, inhaler…) on a red circle |
| Big button | `Views/BigButtonLabel.swift` | 60 pt, full width. `filled: true` for the main action |
| Language menu | `Views/LanguageMenu.swift` | The globe in the toolbar: ภาษาไทย / English |
| Disclaimer | ContentView, detail, scan result | "ไม่ใช่คำแนะนำทางการแพทย์ · Not medical advice" in footnote style |

## Do's and Don'ts

- Do write every string as `language("ไทย", "English")`, and check both languages.
- Do pair every color with an SF Symbol or a word.
- Do give every icon-only button an `accessibilityLabel` in both languages.
- Do test with the largest Dynamic Type size, dark mode, VoiceOver, and both languages.
- Do use `ContentUnavailableView` for empty states.
- Don't put white text on orange or on light red.
- Don't use fixed font sizes for text, or `.caption` for anything users must read.
- Don't use a symbol that could scare or mislead. For example, avoid a syringe for a diabetes **tablet**.
- Don't hide features on iPhone that exist on iPad.
- Don't use real people's health data in screenshots or previews. Use the made-up envelopes in `SampleLabels` (PDPA).
- Don't add custom fonts, shadows, emoji icons or decorative gradients beyond the red box. Stay native, like Health.

## Checking a design

- In Claude Code, say "use jenny-design-review on <screen>". With other tools, use [ai/prompts/08-design-review.md](ai/prompts/08-design-review.md).
- Before the demo, run [ai/prompts/09-accessibility-check.md](ai/prompts/09-accessibility-check.md) and test with a real older person using [ai/prompts/10-user-test.md](ai/prompts/10-user-test.md).
- Ideas the research suggests, ranked, are in [docs/design/research.md](docs/design/research.md) section 6.
