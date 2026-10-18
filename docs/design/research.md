# Design research: older users, medication apps, and AI design tools

Research date: 18 October 2026. It backs up [DESIGN.md](../../DESIGN.md) and the design skills and prompts in this repo.
Every claim links to its source. Numbers marked **(secondary)** come from a search summary or a third-party page and should be checked against the original before we quote them in the pitch.

---

## 1. Who we design for

### Thai older adults and phones

- **Smartphone use is growing.** The NSO Statistical Yearbook 2025 shows about 11.87 million people aged 60+ using a mobile phone in 2024. The chart was hard to read, so check the table before quoting it **(secondary)**. Source: [NSO Statistical Yearbook Thailand 2025, ch. 16](https://www.nso.go.th/public/e-book/Statistical-Yearbook/SYB-2025/514/)
- **About half want to use health apps.** A study of 1,100 Thai adults aged 45+ (mean age 62.3) found that 48.8% intended to use mHealth apps and 51.2% did not. Source: [Buawangpong et al., JMIR Human Factors 2025](https://pmc.ncbi.nlm.nih.gov/articles/PMC11908770/)
  - Owning a smartphone raised the odds of wanting to use one (adjusted OR 2.81).
  - Having a chronic disease *lowered* the odds (adjusted OR 0.63). Our users are exactly that group, so the app has to feel easy and safe.
  - Less fear of making mistakes, higher perceived ease of use, and lower "gerontechnology anxiety" all went with higher intention.
  - Worries about privacy, data security and whether the app works went with lower intention.
  - **What this means for Jenny:** show "stays on this device" clearly, make every action easy to undo (tap a dose again to un-tick it), and show that the app works on the first try.
- **Literacy.** More than 7.5% of Thai people over 50 are reported to be illiterate, which is one reason pictograms matter **(secondary)**. Source: [IJPS, pictograms for Thai patients with low literacy](https://ijpsonline.com/articles/development-and-evaluation-of-a-pictogram-for-thai-patients-with-low-literate-skills-3590.html)

### Pictograms on medicine labels (Thai studies)

- **Yala RCT (2022):** adherence was 94.22 ± 4.86% with pictorial labels versus 76.10 ± 6.05 without, with the benefit seen "especially [for] the elderly and illiterate patients" **(secondary)**. Source: [TUHJ article](https://he02.tci-thaijo.org/index.php/TUHJ/article/view/260568)
- **Hat Yai RCT (2019):** tested pharmaceutical pictograms with elderly patients who have chronic diseases (25 vs 25). Results not yet read. Source: [HITAP DB](https://db.hitap.net/articles/3252)
- **What this means for Jenny:** pair every meal and time instruction with a picture, not just words. The SF Symbols we use (sunrise for morning, a fork and knife for meals) are a start. A clearer "before / after / with food" pictogram is a strong next step.

## 2. Research-backed rules for older users

| Topic | What the research says | Source | Jenny today |
|---|---|---|---|
| **Text size** | Studies with people aged 62–84 on iPads recommend about **18 pt**, and reviews give 14–22 pt for English text. One reading study notes that very large text slows reading, so "bigger may not always mean better" | [Font-size review, PMC9376262](https://pmc.ncbi.nlm.nih.gov/articles/PMC9376262/), including Chatrangsan & Petrie (2019) | ✅ The smallest text we use is `.body` (17 pt) and it grows with Dynamic Type. Key facts use `.title3` or larger |
| **Let users choose the size** | Make it easy to change the text size | [Toptal guide](https://www.toptal.com/designers/ui/ui-design-for-older-adults); [Liu et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8510293/) | ✅ Dynamic Type, and layouts stack at accessibility sizes |
| **Touch targets** | Treat 44 pt as the bare minimum for older users and add spacing between controls | [Toptal guide](https://www.toptal.com/designers/ui/ui-design-for-older-adults); [systematic review 2025](https://link.springer.com/article/10.1007/s40520-025-03157-7) | ✅ 52–60 pt |
| **Simple taps** | Use simple taps, avoid zoom and complex gestures, use large labeled buttons | [Liu et al. 2021, JAMIA](https://pmc.ncbi.nlm.nih.gov/articles/PMC8510293/) (74 studies) | ✅ Tap-only. ⚠️ Settings and Add in the toolbar are icon-only |
| **Flat navigation** | Put the main functions on the home screen, use few menus and a clear back button | Liu et al. 2021 | ✅ Everything starts on one home screen |
| **Text style** | Sans-serif, bold for key points, avoid italics and ALL CAPS | Liu et al. 2021 | ✅ SF Pro, bold key facts |
| **Contrast** | Dark text on a light background, a limited palette | Liu et al. 2021 | ✅ Orange and green only on icons, never text |
| **Less typing** | Use voice and button inputs instead of typing | Liu et al. 2021 | ✅ The camera does the typing. Read aloud is built in |
| **Audio** | Offer audio and vibration alongside visuals | Liu et al. 2021 | ✅ Thai read-aloud plus success haptics |
| **Reminders** | Reminders improved medication adherence in several studies | Liu et al. 2021 | ✅ One notification per pill time |
| **Family** | Older adults value family and caregiver support | [Buawangpong 2025](https://pmc.ncbi.nlm.nih.gov/articles/PMC11908770/); Liu et al. 2021 | ❌ Not yet (idea below) |

## 3. What Apple Health's Medications feature does (and what users complain about)

Source: [Apple Support: Add and log medications](https://support.apple.com/en-ca/105064); [TidBITS review and user thread](https://tidbits.com/2022/10/07/an-apple-a-day-ios-16-medications-feature-provides-alerts-logging-and-peace-of-mind/)

- **Taken *and* Skipped.** You can log a dose as Taken or Skipped, and you can fix the time it was taken. Jenny only has Taken.
- **Follow-up reminder.** Health can remind you again 30 minutes later if you haven't logged the dose. Jenny reminds you only once.
- **Answer from the notification.** On iPhone you reply Taken or Skipped right from the notification. Jenny makes you open the app.
- **User complaints:**
  - Logging a dose outside a reminder takes too many taps. Jenny's Today card already fixes this.
  - Notifications vanish after a few minutes, with no badge.
  - Multi-dose schedules are awkward to set up.

## 4. Checklists judges and Apple care about

- **App Store Accessibility Nutrition Labels** (Apple's official definitions). Source: [App Store Connect Help](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
  - **Larger Text:** text can grow to 200% or more.
  - **Differentiate Without Color Alone:** shapes or text carry meaning, not just color.
  - **Sufficient Contrast:** text and icons stand out from the background.
  - Also VoiceOver, Voice Control, Dark Interface, and Reduced Motion.
  - **Jenny can honestly claim Larger Text, Differentiate Without Color Alone, Dark Interface and Reduced Motion. VoiceOver still needs a test on the iPad.**
- **Apple Design Awards "Inclusivity":** apps that support "a diversity of backgrounds, abilities, and languages", with VoiceOver, Dynamic Type and localization as examples. Source: [MacTech (2022 finalists)](https://www.mactech.com/2022/05/31/apple-announces-finalists-for-2022-apple-design-awards)
- **WWDC24 "Get started with Dynamic Type":** covers finding scaling issues and the Large Content Viewer for small icons in bars. Source: [developer.apple.com/videos/play/wwdc2024/10074](https://developer.apple.com/videos/play/wwdc2024/10074/)

## 5. AI design skills and tools we looked at

| Tool | License · stars · last update | Decision | Why |
|---|---|---|---|
| [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) (SwiftUI Pro) | MIT · 6.2k · Oct 2026 | ✅ Installed: `.claude/skills/swiftui-pro` | Modern SwiftUI code and review, accessibility, HIG basics |
| [ehmo/platform-design-skills](https://github.com/ehmo/platform-design-skills) (iOS + iPadOS) | MIT · 615 · Mar 2026 | ✅ Installed: `.claude/skills/ios-design-guidelines`, `ipados-design-guidelines` | Design rules (HIG) with SwiftUI examples. Markdown only. The iPad skill matters because we demo on an iPad |
| [google-labs-code/design.md](https://github.com/google-labs-code/design.md) | Apache-2.0 · 28k | ✅ Used its format for `DESIGN.md` | Standard way to describe a design system to any AI agent |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 · 82k · Oct 2026 | ❌ Not installed, ideas used | Its setup downloads and runs a binary on first use. We adapted its **native audit** scoring, **persona testing** and **Nielsen heuristics** ideas into `.claude/skills/jenny-design-review` and prompt 08 (our own wording) |
| [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | MIT · 137k | ❌ Not installed | Mostly web: style, palette and font data plus Python scripts. Our look is already decided in DESIGN.md |
| [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) | MIT · 3.7k · Oct 2026 | ⏸ Alternative | Very good, but overlaps SwiftUI Pro. Two SwiftUI skills could give conflicting advice |
| [dpearson2699/swift-ios-skills](https://github.com/dpearson2699/swift-ios-skills) (`ios-accessibility`, `push-notifications`) | PolyForm Perimeter (source-available, **not** open source) · 1.2k | ⏸ Not installed | Useful, but the license isn't open source. Revisit only if we need it |
| [Dimillian/Skills](https://github.com/Dimillian/Skills) | MIT · 4k · Mar 2026 | ⏸ Not needed now | Overlaps SwiftUI Pro. Its Liquid Glass skill could help later |
| [anthropics/skills `frontend-design`](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Apache-2.0 | ❌ | Web only |
| [twostraws/Swift-Agent-Skills](https://github.com/twostraws/Swift-Agent-Skills) | MIT · 2.9k | 📚 Directory | The best index to search when we need a new skill. Being listed there is not an endorsement |

## 6. Ideas this research suggests (not built yet)

Ranked by impact for our users and for judging:

1. **Answer from the notification:** "ทานแล้ว · Taken" and "เตือนอีก 10 นาที · Remind me in 10 min" buttons on the reminder (actionable notifications, `UNNotificationAction`).
   - Health does this, and it saves an older user from finding and opening the app.
   - Test on the iPad, because notification delivery isn't guaranteed. Source: [Apple: Declaring actionable notification types](https://developer.apple.com/documentation/usernotifications/declaring-your-actionable-notification-types)
2. **Follow-up reminder** 30 minutes later if a dose isn't ticked, like Health.
3. **Meal-timing pictograms** (before, after or with food) on the result and detail screens, backed by the Thai pictogram trials above.
4. **"ข้าม · Skip"** next to "ทานแล้ว", so a skipped dose isn't shown as "late" all day.
5. **Labeled toolbar buttons**, or the Large Content Viewer for Settings and Add, since older users do better with labeled buttons (Liu 2021).
6. **Family summary:** a share button that sends today's ticks to a family member through the share sheet. It stays private because the user chooses to send it.
