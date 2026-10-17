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
- **Our solution (one core feature):** open the app and see today's pills right away. Tap a big button when you take one.
  Jenny reminds you at each pill time and points out anything missed.
  To add medicines, paste the prescription instructions and Jenny sets up the times.
- **AI we use and why:** **Foundation Models** (on-device) reads the prescription text into a schedule (`@Generable`).
  It's a short text task, it works offline, and health information never leaves the device.
  When Apple Intelligence isn't available, a basic offline reader takes over, and the app always shows which one answered.
- **Impact (numbers!):** _TODO: ask a real person how many doses they miss per week, then measure with the History tab._

### How to try it
1. **Today:** sample (made-up) medicines load on first launch. Tap **Mark as taken** on a card. Missed doses turn red.
2. **Medicines ▸ Add with Jenny:** tap **Use an example**, then **Let Jenny read it**, then **Add**.
3. **History:** this week's percent of doses taken.
4. **Settings (gear on Today):** turn on reminders, or **Send a test reminder in 5 seconds** for the demo.

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
