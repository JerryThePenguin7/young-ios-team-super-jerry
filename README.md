# Super Jerry 🐭

Team **Super Jerry**'s iOS app for **YIDH26, the Young iOS Developer Hackathon 2026** at Srinakharinwirot University (SWU), October 2026.
The theme is AI that runs on Apple devices.

👉 **Read [ai/what-we-are-building.md](ai/what-we-are-building.md) first.** It covers what we're building, the AI options, judging, and how we work.

- Full rules and schedule: [ai/context/competition-brief.md](ai/context/competition-brief.md)
- Rules every AI coding agent follows: [AGENTS.md](AGENTS.md)
- Copy-paste prompts for the team: [ai/prompts/](ai/prompts/)

## The idea: Jenny 💊

> Take a photo of a medicine envelope, and Jenny reads it out loud in big, clear Thai, then remembers it for you.

- **Who has the problem:** older people (e.g. our grandparents) who take several medicines every day.
- **The problem:** the labels are tiny, the drug names are in English, and every envelope looks the same,
  so they take the wrong pill, at the wrong time, or forget it.
- **Our solution (one core feature): the camera.** Open Jenny and tap the big **ถ่ายรูปซองยา** button.
  Take a photo of a Thai medicine envelope, and Jenny shows **huge text** (what, how many, when) and **reads it aloud in Thai**.
  Tap **Save**, and the medicine is kept with its label photo. Jenny reminds you at each pill time, and you tick each dose when you take it.
- **AI we use and why:** Apple's **Vision** reads the label text on the device (a neural network on the Neural Engine),
  then our **Thai label rules** understand it ("ครั้งละ 1 เม็ด วันละ 2 ครั้ง หลังอาหาร"). It all works offline, and health data never leaves the device.
  We tested Apple's on-device language model (Foundation Models): it doesn't support Thai and it blocked medicine text as
  "sensitive content", so the rules do the understanding. See [docs/pill-reader/ai-explained.md](docs/pill-reader/ai-explained.md).
- **Impact (numbers!):** _TODO: run the impact test in [docs/pill-reader/plan.md](docs/pill-reader/plan.md) section 3.3 and put the numbers here._

The full plan (facts, pitch script, judge Q&A) is in [docs/pill-reader/plan.md](docs/pill-reader/plan.md). It calls the app ยาใจ; the app is named Jenny.

### How to use it (on the iPad)
1. **ถ่ายรูปซองยา · Take a photo:** the first time, allow the camera. Fill the photo with the label, in good light.
2. **Result:** Jenny reads the label aloud (turn this off in Settings). Tap **อ่านออกเสียง** to hear it again.
   Fix anything with **แก้ไข · Edit**, or **ถ่ายใหม่ · Retake**. Then **บันทึกยา · Save medicine**.
3. **Home ▸ ยาของฉัน · My medicines:** each medicine shows its label photo. Tap a time chip (เช้า, เย็น…) to tick it as taken today.
   **ถึงเวลาทานยา · Time to take** appears at the top when a dose is due.
4. **Reminders:** tap **ให้ Jenny เตือนเวลาทานยา**, or use Settings. One notification per pill time: เช้า 08:00, กลางวัน 12:00, เย็น 18:00, ก่อนนอน 21:00.
5. **Tap a medicine** to see the big photo, the scanned text, edit it, or delete it.

No camera (e.g. the simulator)? The big button picks a photo from the library instead. To test, print the 5 fake envelopes
in [docs/pill-reader/plan.md](docs/pill-reader/plan.md) section 10.1 (made-up data only, PDPA).

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
