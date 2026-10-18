---
version: alpha
name: Jenny
description: >-
  Jenny's look, inspired by the Apple Health app. A calm gray canvas with white rounded cards,
  one red accent for the single most important action on each screen, SF Symbols on every header,
  and big rounded numbers. Built for older Thai adults who take several medicines a day,
  and for the family members who help them, without looking like a "special" app.

colors:
  # Brand red (asset "JennyRed"): buttons, icons, red text. Dark mode: #FF6961.
  primary: "#D32F2F"
  primary-dark-mode: "#FF6961"
  # Filled red buttons with white text (asset "JennyCard"). Dark mode: #B3261E.
  primary-fill: "#D32F2F"
  primary-fill-dark-mode: "#B3261E"
  on-primary: "#FFFFFF"
  # Page background (asset "JennyBackground"), like Health's grouped gray. Dark mode: #000000.
  background: "#F2F2F7"
  background-dark-mode: "#000000"
  # Cards and rows (asset "JennySurface"). Dark mode: #1C1C1E.
  surface: "#FFFFFF"
  surface-dark-mode: "#1C1C1E"
  on-surface: "#000000"
  on-surface-secondary: "#3C3C4399"
  # Dose states. Always paired with an SF Symbol and a word, never color alone.
  taken: "#34C759"
  late: "#FF9500"
  due: "#D32F2F"

typography:
  # Sizes are the iOS defaults at the standard text size. In SwiftUI, always use the text style
  # (e.g. .largeTitle) so text grows with the user's Dynamic Type setting.
  large-title:
    fontFamily: "SF Pro, system-ui"
    fontSize: 34px
    fontWeight: 700
  title:
    fontFamily: "SF Pro, system-ui"
    fontSize: 22px
    fontWeight: 700
  card-title:
    fontFamily: "SF Pro, system-ui"
    fontSize: 17px
    fontWeight: 600
  body:
    fontFamily: "SF Pro, system-ui"
    fontSize: 17px
    fontWeight: 400
  big-number:
    fontFamily: "SF Pro Rounded, system-ui"
    fontSize: 46px
    fontWeight: 800
  footnote:
    fontFamily: "SF Pro, system-ui"
    fontSize: 13px
    fontWeight: 400

rounded:
  sm: 12px
  md: 16px
  card: 20px
  hero: 28px
  full: 9999px

spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  card-padding: 16px

components:
  button-primary:
    backgroundColor: "{colors.primary-fill}"
    textColor: "{colors.on-primary}"
    typography: "{typography.card-title}"
    rounded: "{rounded.md}"
    height: 60px
  button-secondary:
    backgroundColor: "color-mix(in srgb, #D32F2F 12%, transparent)"
    textColor: "{colors.primary}"
    typography: "{typography.card-title}"
    rounded: "{rounded.md}"
    height: 60px
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "{spacing.card-padding}"
  card-header:
    textColor: "{colors.primary}"
    typography: "{typography.card-title}"
  dose-check:
    size: 52px
    rounded: "{rounded.full}"
  chip:
    rounded: "{rounded.full}"
    height: 52px
---

# Jenny design system

## Overview

Jenny should feel like a page of the **Apple Health app**: calm, tidy and trustworthy. The canvas is gray and the content sits in white cards.
Each card starts with a small colored header (an SF Symbol plus a title, like "💊 ยาของฉัน") and then shows one big, easy fact.

**Who it's for.** Our main users are **older Thai adults (60+)** who take several medicines a day, plus the **family members** who set the app up and check on them.
We design for them **quietly**: the app looks like a normal, modern Apple app, but every detail works for weaker eyes, shakier hands and less tech confidence:

- Text is big and grows with the iPhone/iPad text-size setting (Dynamic Type), all the way to the accessibility sizes.
- Main tap targets are **60 pt** tall, and nothing you tap is smaller than **52 pt**. Apple's minimum is 44 pt.
- Thai comes first and English follows: `ถ่ายรูปซองยา · Take a photo`.
- Each screen has **one** obvious next step, shown in red.
- Nothing relies on color alone. Every state has an icon **and** a word, because many older eyes see red and green poorly.
- Every important text can be **read aloud**.

The UI never feels babyish or "for old people". Family members use it too, and nobody likes an app that talks down to them.

**Why these rules** (sources in [docs/design/research.md](docs/design/research.md)):
- A review of 74 studies on health apps for older adults recommends large sans-serif text, high contrast, simple taps, labeled buttons, a flat structure with the main functions on the home screen, and audio alongside text.
- Studies on iPads with people aged 62–84 point to about 18 pt text. Our `.body` is 17 pt and grows with Dynamic Type, and the key facts are bigger.
- In a study of 1,100 Thai adults aged 45+, people with a chronic disease were *less* likely to want a health app. Fear of mistakes and privacy worries held people back.
  So Jenny makes every action easy to undo, and it says that photos stay on the device.
- Thai trials found pictograms on medicine labels helped elderly patients take their medicine correctly.
  So every time and meal instruction gets an SF Symbol, not just words.
- Apple Health's Medications feature is our model for logging doses: log from one place, and fix a mistake by tapping again.

## Colors

- **Red (`primary`)** is Jenny's brand. Use it for the main action, card headers and the dose amount. Use only **one filled red button** per screen.
- **Gray background + white cards**, like Health. In dark mode this becomes black with dark gray cards.
- **Green (`taken`)** means taken, **orange (`late`)** means late or "please check", and **red (`due`)** means it's time now.
- In code, colors come from `Theme` (`Theme.red`, `Theme.card`, `Theme.background`, `Theme.surface`, `Theme.taken`, `Theme.late`). Their light and dark versions live in `Assets.xcassets`. Never hard-code a hex value in Swift.

## Typography

- Use SwiftUI text styles (`.largeTitle`, `.title2`, `.headline`, `.body`), never fixed point sizes, so Dynamic Type works.
- Use **SF Rounded, heavy** (`.fontDesign(.rounded)`) for big numbers, like Health's figures: the amount (`ครั้งละ 1 เม็ด`) and today's progress (`2/5`).
  For a custom size, use `@ScaledMetric` so it still scales.
- Use `.bold()` rather than `fontWeight(.bold)`.
- Avoid `.caption` and `.caption2`. The smallest style is `.footnote`, and it's only for disclaimers.

## Layout

- The home screen is a single scrolling column of cards, limited to about 1000 pt wide on iPad so lines don't get too long.
  The medicine list becomes a grid on wide screens (`LazyVGrid`, `.adaptive(minimum: 340)`).
- Cards are spaced `spacing.xl` (24 pt) apart, and content inside a card is spaced 12–16 pt.
- **Home order:** ① *Time to take* (only when a dose is due) → ② the camera (the main feature) → ③ *Today*: a progress ring and the day's schedule, where you tick doses → ④ *My medicines* → ⑤ the disclaimer.
- Keep the main action where a thumb can reach it. On the scan result, **Save** sits in a bar fixed at the bottom of the screen.

## Elevation & Depth

Flat, like Health. Cards sit on the gray background without any shadows. Depth only comes from the system's Liquid Glass bars (navigation bar, toolbar, sheets).
The camera hero card is the one exception: it uses a soft red gradient so it stands out as the main feature.

## Shapes

- Cards: 20 pt corners (`Theme.cornerRadius`). The hero card and sheets: 28 pt.
- Buttons: 16 pt corners. Chips, check circles and small badges: fully round (capsule or circle).
- Label photos: 16 pt corners, so every envelope is easy to recognize at a glance.

## Components

- **SummaryCard** (`Views/SummaryCard.swift`): a Health-style card. Its header has an SF Symbol and title in the card's tint color, with an optional detail on the right (a time or a count), followed by the content.
- **Buttons** (`Views/BigButtonStyle.swift`): `.buttonStyle(.bigProminent)` makes a filled red button (one per screen), and `.buttonStyle(.big)` makes a light red one.
  Both are at least 60 pt tall, full width, with an SF Symbol and a two-language title, and they dim and shrink slightly when pressed (no motion with Reduce Motion on).
- **Dose check** (`Views/TodayScheduleCard.swift`): a 52 pt circle. Empty means not taken yet, a green check means taken, and an orange ring plus the word `เลยเวลา` means late. Tapping it again un-ticks the dose.
- **Progress ring** (`Views/TodayProgressRing.swift`): shows how many of today's doses are taken, like Health's activity rings, with the count in big rounded numbers.
- **DoseChips**: capsules that show a medicine's times (เช้า · 8:00). On a saved medicine you can tap them to tick the dose.
- **Disclaimer**: every screen with medicine facts ends with `ไม่ใช่คำแนะนำทางการแพทย์ · Not medical advice` in footnote style.

## Do's and Don'ts

- Do keep Thai first and English second, joined by ` · `.
- Do pair every color with an SF Symbol and a word.
- Do give every icon-only button an `accessibilityLabel`.
- Do test with the largest Dynamic Type size, dark mode, and VoiceOver.
- Do use `ContentUnavailableView` for empty states.
- Don't use more than one filled red button on a screen.
- Don't use fixed font sizes, `.caption2`, or text in light gray on gray.
- Don't hide features on iPhone that exist on iPad.
- Don't use real people's health data in screenshots or previews. Use the made-up envelopes in `SampleLabels` (PDPA).
- Don't add custom fonts, shadows or decorative gradients. Stay native, like Health.

## Checking a design

- In Claude Code, say "use jenny-design-review on <screen>". With other tools, use [ai/prompts/08-design-review.md](ai/prompts/08-design-review.md).
- Before the demo, run [ai/prompts/09-accessibility-check.md](ai/prompts/09-accessibility-check.md) and test with a real older person using [ai/prompts/10-user-test.md](ai/prompts/10-user-test.md).
- Ideas the research suggests, ranked, are in [docs/design/research.md](docs/design/research.md) section 6. They include buttons on the reminder notification, a Skip option, and meal pictograms.
