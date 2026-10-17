# Super Jerry 🐭

Team **Super Jerry**'s iOS app for the **Young iOS Hackathon @ Srinakharinwirot University (SWU)**, October 2026.
The theme is AI that runs on Apple devices.

👉 **Read [docs/COMPETITION.md](docs/COMPETITION.md) first.** It covers the rules, judging criteria, schedule, and what to submit.

## The idea

> _TODO: fill in once we pick it (first task on Day 1)._

- **Who has the problem:**
- **The problem:**
- **Our solution (one core feature):**
- **AI we use and why:** Foundation Models / Core ML / MLX cluster
- **Impact (numbers!):**

## Team

| Name | Role |
|---|---|
| Jerry | |
| | |
| | |

## Getting started

Requirements: **Xcode 26 or 27**. The deployment target is iOS 26, so it works on the event's Intel Macs too.
If Xcode 27 asks to "update to recommended settings / project format," click **No**, or teammates on Xcode 26 can't open the project.

> The organizers also give us an official team repo on the Team card. This repo is our own copy for sharing.
> Before final submission, push the same code to the official repo (or follow whatever the staff say).

```bash
git clone <this repo url>
cd SuperJerry
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

let aiCluster = HackathonAI(baseURL: "http://10.1.117.186:3949", apiKey: "team-XX-xxxx")

extension HackathonAI {
    static let smartRoute: ModelID = "@route/sccth-gq"
}
```

## Submission checklist

- [ ] App builds and runs on a clean clone
- [ ] Core feature works offline / live with no crashes
- [ ] Xcode project zipped and sent to staff (early!)
- [ ] Pitch deck exported as **PDF** (no animations, no unauthorized logos)
- [ ] Backup screen recording of the demo
- [ ] Everyone on the team can explain the problem, the AI choice, and the demo
