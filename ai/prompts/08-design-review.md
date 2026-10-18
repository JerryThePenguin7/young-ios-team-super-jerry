# 08 — Design review

Get an honest critique of a screen before judges see it. In Claude Code, just say **"use jenny-design-review on the home screen"**: the skill does all of this, including simulator screenshots.
Use this prompt with other tools (Xcode agents, OpenCode, ChatGPT). If the tool can't see the app, attach screenshots: light, dark, and the biggest text size.

```text
Review the design of [screen, e.g. the home screen / ScanResultView.swift]. Don't change any code.
First read DESIGN.md (our design system: Apple Health style), docs/design/research.md
(rules for older users), and AGENTS.md.

Our users are Thai adults aged 60+ who take several medicines a day (weak eyes, shaky hands,
read Thai only, afraid of pressing the wrong thing), plus the family members who help them.

Score each area 0–4 with one line of reasoning:
1. Accessibility (VoiceOver labels, Dynamic Type up to the largest size, Reduce Motion, contrast)
2. Fit for older users (tap targets 60 pt main / 44 pt minimum, labeled buttons, taps only, one obvious next step,
   icon or word for every state, both Thai and English work)
3. Apple platform fit (native controls, SF Symbols, sheets, large titles, safe areas)
4. Follows DESIGN.md (Theme colors only, reuses the red box / Log cards / BigButtonLabel / PillIcon,
   one big red call to action, every string in language("ไทย", "English"))
   Also flag "AI slop": generic hero sections, emoji icons, left-stripe cards, cards in cards, custom fonts,
   vague labels like a bare "+", filler copy, many different corner radii or reds.
5. Adapts to iPhone and iPad (no stretched phone layout on iPad)
6. Clarity and trust (empty/loading/error states, "not medical advice", "stays on this device", easy undo)

Then walk through the core flow as: (a) a 72-year-old grandmother using it alone, (b) her daughter
setting it up, (c) a VoiceOver user, (d) a hackathon judge with 5 minutes. Where does each get stuck?

List problems as P0 (breaks the demo) to P3 (nice to have), each with the file:line, who it hurts,
and a one-sentence fix. Finish with the single best next fix. Wait for my approval before fixing anything.
```

Then fix **one** problem per prompt with [03-new-feature.md](03-new-feature.md), and build after each fix.
