# 09 — Accessibility check

Accessibility is our users' everyday reality, and it's the easiest way to impress judges on the Design criterion.
This check follows Apple's **App Store Accessibility Nutrition Labels**, so we can honestly say in the pitch which ones Jenny supports.

```text
Check [screen or "the whole app"] for accessibility. Don't change code yet. Read DESIGN.md first.
For each item, answer Pass / Fail / Needs iPad test, with the file:line for every Fail:

1. Larger Text: does all text use text styles (no fixed font sizes, except @ScaledMetric)? Does the layout
   still work at the largest accessibility size (stacks instead of squeezing, nothing cut off)?
2. Differentiate Without Color Alone: does every status (taken, due, late) have an icon AND a word?
3. Sufficient Contrast: is any text orange, green, or light gray on white? Is any text hard to read in dark mode?
4. VoiceOver: does every button say what it does, including icon-only toolbar buttons? Are headers marked
   (.accessibilityAddTraits(.isHeader))? Does "ทานแล้ว" say which medicine it's for?
5. Reduced Motion: are custom animations turned off when Reduce Motion is on?
6. Dark Interface: do all colors come from Theme / Assets with a dark version?
7. Voice Control: does every button have a visible name you could say ("Tap Read aloud")?
8. Touch targets: is anything you can tap smaller than 52 × 52 pt?

Then list the fixes from most to least important for older users. Wait for my approval.
```

Then by hand on the iPad (Settings ▸ Accessibility):
- [ ] **VoiceOver** on: do the whole flow (photo → result → save → tick a dose) with your eyes closed
- [ ] **Display & Text Size ▸ Larger Text** at the maximum: every screen still readable
- [ ] **Bold Text**, **Increase Contrast**, and **Reduce Motion** on: nothing breaks
- [ ] **Voice Control**: say "Tap ถ่ายรูปซองยา"

Source for the labels: [Apple: Overview of Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
