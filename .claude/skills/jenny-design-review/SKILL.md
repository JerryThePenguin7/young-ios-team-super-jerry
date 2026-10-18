---
name: jenny-design-review
description: Review Jenny's UI and UX like an Apple design reviewer and an older Thai user would. Use when asked to review, critique, audit, or check the design, a screen, accessibility, or "does this look right", or before a demo. Builds the app, takes simulator screenshots (light, dark, big text, iPhone and iPad), scores 6 areas, tests with Jenny's personas, and reports problems by priority without changing code.
---

# Jenny design review

You are reviewing **Jenny**, a SwiftUI app that reads Thai medicine envelopes aloud for older adults. Judge it the way three people would: an Apple design reviewer, a 72-year-old Thai user, and a hackathon judge.

**Never change code during a review.** Report the problems and wait for the user to pick what to fix (AGENTS.md: plan first).

## 1. Load the context

Read these before looking at anything:
- `DESIGN.md`: Jenny's tokens, components, and do's and don'ts. **It is the source of truth for the look.**
- `docs/design/research.md`: the research rules for older users, and what Apple Health does.
- `AGENTS.md`: the hard rules (iOS 26, Xcode 26 must build, no secrets, synthetic data only).
- The SwiftUI files for the screens being reviewed.

When you need the rule behind a finding, the skills `ios-design-guidelines`, `ipados-design-guidelines`, and `swiftui-pro` are installed next to this one.
If one of them disagrees with `DESIGN.md`, `DESIGN.md` wins. For example, Jenny deliberately uses Health-style cards instead of inset lists on the home screen.

## 2. Look at the real app, not just the code

Build and run it in the simulator, then take screenshots. Use the UDID, not the device name.

```bash
xcrun simctl list devices available | grep -E "iPhone|iPad"
xcodebuild -project SuperJerry.xcodeproj -scheme SuperJerry -destination 'id=<UDID>' -derivedDataPath <scratch>/dd build CODE_SIGNING_ALLOWED=NO
xcrun simctl install <UDID> <scratch>/dd/Build/Products/Debug-iphonesimulator/SuperJerry.app
```

Fill the app with **made-up** medicines (PDPA: never real health data) by running `python3 .claude/skills/jenny-design-review/seed_sample_medicines.py <UDID> <bundle id>`.
The bundle ID is in the built app's `Info.plist` (`CFBundleIdentifier`). Then launch the app with `xcrun simctl launch --terminate-running-process <UDID> <bundle id>`.

Capture each screen being reviewed in all four of these states, on **one iPhone and one iPad**:

| State | Command |
|---|---|
| Default | `xcrun simctl ui <UDID> appearance light` + `content_size large` |
| Dark | `xcrun simctl ui <UDID> appearance dark` |
| Biggest text | `xcrun simctl ui <UDID> content_size accessibility-extra-extra-extra-large` |
| Screenshot | `xcrun simctl io <UDID> screenshot <scratch>/shots/<screen>-<state>.png` |

Wait about 2 seconds after each change before taking the screenshot. Reset to light mode and `large` text when you finish.
Say which findings come from screenshots and which from reading code. The camera, VoiceOver, and real hands need the iPad, so list those as "check on the iPad".

## 3. Score six areas (0–4 each)

0 = broken · 1 = major gaps · 2 = partial · 3 = good, small gaps · 4 = excellent

1. **Accessibility:**
   - VoiceOver labels on every control. Icon-only buttons need `accessibilityLabel`.
   - A logical reading order and headers (`.isHeader`).
   - Dynamic Type up to the largest size with no clipping or overlap.
   - Reduce Motion honored.
   - Contrast in both light and dark.
2. **Fit for older users** (`docs/design/research.md` section 2):
   - Tap targets: 60 pt for main buttons, nothing under 52 pt.
   - Labeled buttons rather than bare icons.
   - Taps only, with no hidden gestures.
   - Thai first, then English.
   - One obvious next step per screen.
   - Every state shown with an icon **and** a word.
   - Read aloud available.
3. **Apple platform fit (HIG):**
   - Native controls, `NavigationStack`, and sheets with Cancel/Done.
   - SF Symbols only.
   - Edge-swipe back works.
   - Large titles on top-level screens.
   - Nothing under the Dynamic Island or the home indicator.
4. **Follows DESIGN.md:**
   - Colors come from `Theme` only, never raw hex in Swift.
   - The `.big` and `.bigProminent` button styles, with at most one filled red button per screen.
   - `SummaryCard` for cards, corner radii from `Theme`, and no shadows.
5. **Adapts to the device:**
   - The iPad layout uses the extra width (grid, max width) instead of a stretched phone layout.
   - Rotation works.
   - The keyboard doesn't hide text fields in the editor.
6. **Clarity and trust:**
   - Plain words.
   - Empty, loading, and error states handled (`ContentUnavailableView`, the "couldn't read the label" card).
   - "Not medical advice" on every screen with medicine facts.
   - "Stays on this device" visible.
   - Easy undo, so tapping a dose again un-ticks it.

## 4. Test with Jenny's personas

Walk through the core flow as each person: open the app → take a photo or pick one → result → save → tick a dose. Write down where each one would get stuck.

- **คุณยายสมศรี, 72 (main user):**
  - Has diabetes and high blood pressure and takes 4 medicines.
  - Reading glasses, slightly shaky hands, reads Thai only, worried about "pressing the wrong thing".
  - Can she do the flow without help? Can she read everything at arm's length?
- **คุณแก้ว, 45 (her daughter):**
  - Sets the app up and checks in by phone.
  - Can she add a medicine by hand quickly? Can she tell at a glance what Mum has taken today?
- **A VoiceOver user:**
  - Does every control say what it does? Is "ทานแล้ว" announced with the medicine's name?
- **A hackathon judge** (5 minutes, knows the HIG):
  - Does it feel like an Apple app in the first 10 seconds?
  - Is the AI's value (the camera reading a Thai label) obvious?
  - Would anything break during a live demo?

## 5. Report

Use this format. Only include real problems, no nitpicks. Sort issues by priority.

```markdown
## Design review: <screens> (<date>)
Evidence: <devices / states captured, or "code only">

| Area | Score | One-line reason |
|---|---|---|
| Accessibility | x/4 | … |
| Older users | x/4 | … |
| Apple platform fit | x/4 | … |
| Follows DESIGN.md | x/4 | … |
| Adapts to device | x/4 | … |
| Clarity & trust | x/4 | … |
| **Total** | **xx/24** | |

### What's working (keep these)
- …

### Problems
**P0 (breaks the demo or blocks a user):**
1. <screen> · `<file>:<line>`: <problem>. Who it hurts: <persona>. Fix: <one sentence>.
**P1 (hurts older users or judges notice it):** …
**P2 (polish):** …
**P3 (nice to have):** …

### Check on the iPad (can't verify in the simulator)
- …

### Suggested next fix
<The single change with the best impact for the effort, and which files it touches.>
```

Then ask which problems to fix. Fix them one at a time, as separate small tasks, building after each.
