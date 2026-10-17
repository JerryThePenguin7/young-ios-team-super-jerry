# 06 — Pre-demo check

Run this a few hours before submitting, not 10 minutes before.

```text
We're about to submit and demo the app live to judges. Review the project (read AGENTS.md and
ai/what-we-are-building.md) and check, without changing code yet:
1. Could anything crash during the core flow? (force unwraps, missing permissions in Info.plist,
   model-unavailable cases, no network)
2. Does it still work with Wi-Fi off? Is there an on-device fallback for every AI call?
3. Does anything use an iOS 27-only API without the #if compiler(>=6.4) guard?
4. Are there secrets, API keys, or real personal/health data anywhere in the repo or git history?
5. Does the UI follow Apple's HIG: dark mode, Dynamic Type, SF Symbols, clear empty/loading/error states?
List the problems from most to least risky for a live demo, with the fix for each. Wait for my approval before fixing.
```

Then by hand:
- [ ] Fresh clone builds on an Intel Mac (Xcode 26) and the Apple Silicon Mac (Xcode 27)
- [ ] Runs on the team iPad, demo flow tried 3 times in a row
- [ ] Backup screen recording of the demo saved
- [ ] Xcode project zipped and sent to staff
- [ ] Pitch deck exported as PDF (no animations, no unauthorized logos)
