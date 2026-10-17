# Super Jerry 🐭

Team **Super Jerry**'s iOS app for **YIDH26, the Young iOS Developer Hackathon 2026** at Srinakharinwirot University (SWU), October 2026.
The theme is AI that runs on Apple devices.

👉 **Read [ai/what-we-are-building.md](ai/what-we-are-building.md) first.** It covers what we're building, the AI options, judging, and how we work.

- Full rules and schedule: [ai/context/competition-brief.md](ai/context/competition-brief.md)
- Rules every AI coding agent follows: [AGENTS.md](AGENTS.md)
- Copy-paste prompts for the team: [ai/prompts/](ai/prompts/)

## The idea: Jenny 💊

> Jenny is a medicine reminder that "nags" you (kindly) until you've taken your pills.

- **Who has the problem:** older people (e.g. our grandparents) who take several medicines every day.
- **The problem:** they forget whether they've already taken a pill, or miss a dose completely.
- **Our solution (one core feature):** point the iPad at a Thai medicine envelope (ซองยา). Jenny shows **huge text**
  (what, how many, when), **reads it aloud in Thai**, and adds it to **today's list**. Tap a big button when you take one.
  Jenny reminds you at each pill time and points out anything missed.
- **AI we use and why:** Apple's **Vision** reads the envelope text on the device (a neural network on the Neural Engine),
  then our **Thai label rules** understand it ("ครั้งละ 1 เม็ด วันละ 2 ครั้ง หลังอาหาร"). Everything works offline, and health data never leaves the device.
  We tested Apple's on-device language model (Foundation Models): it doesn't support Thai and it blocked medicine text as
  "sensitive content", so the rules do the understanding. See [docs/pill-reader/ai-explained.md](docs/pill-reader/ai-explained.md).
  Typed English instructions can still try Foundation Models first ("Add with Jenny"), with an offline reader as the backup.
  The app always shows who read it.
- **Impact (numbers!):** _TODO: run the impact test in [docs/pill-reader/plan.md](docs/pill-reader/plan.md) section 3.3 and put the numbers here._

The full plan (facts, pitch script, judge Q&A) is in [docs/pill-reader/plan.md](docs/pill-reader/plan.md). It calls the app ยาใจ; the app is now named Jenny.

### How to try it
1. **Today ▸ สแกนซองยา · Scan a medicine envelope:** take a photo (iPad), choose a photo, or **Try a sample** (works in the simulator).
   On the big card, tap **อ่านออกเสียง · Read aloud**, then **เพิ่มในยาของฉัน · Add to my medicines**.
2. **Today:** tap **Mark as taken** on a card. Missed doses turn red. Sample (made-up) medicines load on first launch.
3. **Medicines:** scan, **Add with Jenny** (type or paste), add by hand, edit, or swipe to delete.
4. **History:** this week's percent of doses taken.
5. **Settings (gear on Today):** reminders, **Send a test reminder in 5 seconds** for the demo, and the **spike test**.

> **Camera setup (once):** target ▸ Info ▸ add `Privacy - Camera Usage Description` = `ใช้กล้องเพื่ออ่านฉลากซองยา`.
> Until then, the **Take photo** button stays hidden (so the app can't crash) and **Choose photo** still works.

## Team

| Name | Role |
|---|---|
| Jerry | |
| | |
| | |

## Getting started

Requirements: **Xcode 26 or 27**. The deployment target is iOS 26, so it works on the event's Intel Macs too.
Test on the **team iPad**: the camera, sensors, and Apple Intelligence don't work in the Intel Macs' simulator.
If Xcode 27 asks to "update to recommended settings / project format," click **No**, or teammates on Xcode 26 can't open the project.

> The organizers also give us an official team repo on the Team card. This repo is our own copy for sharing.
> Before final submission, push the same code to the official repo (or follow whatever the staff say).

```bash
git clone <this repo url>
cd young-ios-team-super-jerry
open SuperJerry.xcodeproj
```

Then pick a simulator (e.g. iPhone 17) and press **⌘R**.

> To run on a real device, set your own **Team** under *Signing & Capabilities*.
> Don't commit that change; personal signing settings differ per person.

## Working together

- Pull before you start: `git pull`
- Work on a branch per feature: `git switch -c feature/camera-scan`
- Commit small and often, then open a Pull Request into `main`.
- **Don't edit the same SwiftUI file as a teammate at the same time.** Merge conflicts in `project.pbxproj` are painful.
  Ping the group chat before adding new files to the Xcode project.

## Secrets

The AI-cluster API key from the Team card goes in `SuperJerry/AICluster.swift`. That file is **gitignored**, so each teammate creates it locally:

```swift
import HackathonAI

// Address: from staff / Team card (the handbook says TBC). Key: from the Team card.
let aiCluster = HackathonAI(baseURL: "http://[address from staff]", apiKey: "team-XX-xxxx")
```

Then call it with `try await aiCluster.respond(to: "...")` (model `.chat` by default).
See [ai/context/competition-brief.md](ai/context/competition-brief.md#ai-cluster-hackathonai-package) for the models and the Info.plist settings.

## Submission checklist

- [ ] App builds and runs on a clean clone
- [ ] Core feature works offline / live with no crashes
- [ ] Xcode project zipped and sent to staff (early!)
- [ ] Pitch deck exported as **PDF** (no animations, no unauthorized logos)
- [ ] Backup screen recording of the demo
- [ ] Everyone on the team can explain the problem, the AI choice, and the demo
