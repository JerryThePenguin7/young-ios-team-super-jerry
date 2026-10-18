# What we're building, and where every fact came from

> **Update (Day 2):** we picked the idea. It's **Jenny**, which reads Thai medicine envelopes for older adults.
> For what the app does today and what's left, see [project-status.md](project-status.md). This file still holds the rules, judging and sources.

Written 2026-10-17 (Day 1 of the camp). Last verified 2026-10-17 15:00 against every source below. This is the "same page" doc for team **Super Jerry**.
For the full rules, see [context/competition-brief.md](context/competition-brief.md).
AI agents: read this before suggesting features. Humans: read this before the first team meeting.

---

## 1. The project in one sentence

> **An iPad/iPhone app built in Xcode (Swift + SwiftUI) that solves one real, specific problem for one real kind of person,
> uses Apple-device AI wherever that's the right tool, and works live in a demo.**

- **Competition:** YIDH26, the Young iOS Developer Hackathon 2026, held at Srinakharinwirot University (SWU) and run with Swift Coding Club TH.
- **Format:** a 3-day camp with about 2 days of real build time. It ends with a live demo plus a 5-min pitch and ~2 min of judge Q&A.
- **Deliverables:** the Xcode project (handed to staff early), a pitch deck **as a PDF** with no animations, and a working **live demo**.

## 2. The 3 AI options — pick, don't collect

The kickoff talk listed **3 options to choose from**. It does **not** require using all 3.
The speakers said "you don't need to use all of them, choose by what you need" and that "a bigger model doesn't mean more points."

| Option | Runs where | Pick it when |
|---|---|---|
| **1. Foundation Models** (Apple's on-device LLM, AFM 3) | On the iPad | Short text jobs: summarize, extract, classify, fill a form. Free, private, offline. Small, not ChatGPT-level |
| **2. Core ML + Core AI** (train your own with **Create ML**) | On the iPad (Neural Engine) | Recognizing things (photos, sounds, text, movement) with a model we train, or running an open-source model on the device. Core AI needs Xcode 27 + iOS 27 |
| **3. MLX on the event's Mac cluster** (8 Mac Studios + 6 Mac minis, via the `HackathonAI` package) | Organizers' Macs, over event Wi-Fi only | The job is too heavy for the iPad: better Thai, reasoning, OCR, speech, medical terms |

**Sensors are their own point, not an AI option.** The talk said Apple devices have great sensors (camera, LiDAR on iPad Pro, gyroscope, microphone, Face ID).
They pair well with any of the 3 options, e.g. camera → Core ML, or microphone → speech-to-text.
Details for each option, including what needs iOS 27 and the cluster setup, are in [the competition brief](context/competition-brief.md#picking-the-ai-a-menu-not-a-checklist).

**Use more than one only when each has a real job.** Two examples:
- Core ML recognizes something from the camera → Foundation Models turns the result into advice.
- The cluster does the heavy work → on-device AI takes over when the Wi-Fi dies. The handbook recommends this fallback.

If a judge asks "why did you need this?", we must have an answer.

## 3. Order of work

1. **Problem first.** Find a real person with a real problem and ask them about it. "My grandma forgets which pills she's taken" beats "a health app."
2. **Then pick the AI** that fits, from the table above.
3. **Build one core feature** that shows its value as soon as the app opens. No login, sign-up, or onboarding.
4. **Measure the impact:** hours saved, money saved, fewer mistakes. Put the numbers in the pitch.

## 4. How we'll be judged (5 criteria; the point split isn't clear yet)

1. **Real-world impact:** solves a real problem for real users. *This weighs the most.*
2. **Use of AI / tech:** the right tool for the job, not the biggest.
3. **Technical execution:** works live with no crashes, and the core flow is complete.
4. **Design (UX/UI):** feels like an Apple app (Human Interface Guidelines).
5. **Pitch, Q&A, ownership:** **everyone** on the team can explain the problem, the AI choice, and the demo.

## 5. How the team works

- **Code goes in ONE shared repo:** the **official team repo** from the organizers' Team card.
  Until we have it, we use this repo, `JerryThePenguin7/young-ios-team-super-jerry` (private). Then we move it over and stop using this one.
- The project must open in **Xcode 26 (Intel Macs) and Xcode 27 (Apple Silicon Mac)**. Keep the iOS 26 target, and say **No** to "update project format."
- **Never commit the AI cluster API key.** It goes in `AICluster.swift`, which is gitignored.
- `main` always builds. Use short branches, pull before working, and commit before letting an AI agent edit code.
- One person adds packages and changes project settings. Nobody commits their personal signing team.
- Health data must be **synthetic only** (PDPA).

---

## 6. All sources so far

### From Jerry

| # | Source | What it is | What we took from it |
|---|---|---|---|
| 1 | **Voice memo** "Srinakharinwirot University.m4a" (28 min, Thai, recorded at the SWU kickoff 2026-10-17) | The organizers' kickoff briefing | The theme, the 3 AI options, examples, the 3 takeaways, the schedule, the point system, the 5 judging criteria, submission rules. Transcribed with Whisper large-v3; the audio is noisy, so unsure details are marked **(?)** in the brief. Raw text: [context/kickoff-transcript-th.txt](context/kickoff-transcript-th.txt). Ask Jerry for the audio |
| 2 | **Official handbook (source)** https://github.com/swiftcodingclubth/yidh26-swift-handbook | The organizers' workshop handbook (MkDocs source + starter Xcode projects for workshops 3–5). Same content as the website | Team kit (1 Apple Silicon Mac, 2 Intel Macs, 1 iPad), Team card, the 3 rules, Xcode 26/27 compatibility, AI cluster models + setup, Git workflow |
| 3 | **Handbook website** https://swiftcodingclubth.github.io/yidh26-swift-handbook/ (Jerry sent the [Workshop 3 page](https://swiftcodingclubth.github.io/yidh26-swift-handbook/workshop-3/)) | The published version of #2 | Same as #2. Workshop 3 covers sensors (Core Motion, Sound Analysis, LiDAR), Create ML, Core ML, and Core AI. **The organizers keep updating it during the event**: on 2026-10-17 at 14:00 they switched the cluster setup to `.chat` and made the address TBC. Always check the website |
| 4 | **This repo** `github.com/JerryThePenguin7/young-ios-team-super-jerry` (private) | Starter SwiftUI app (Hello World) | The base for the team app. Its format was changed so Xcode 26 can open it, and it gained AGENTS.md and this `ai/` folder |

### Handbook pages used most

Paths are inside the handbook repo's `docs/` folder.

- Getting started (Team card, signing, Xcode 26/27): `docs/getting-started.md`
- Hardware: `docs/workshop-1/hardware.md`
- Git & GitHub workflow: `docs/workshop-1/git.md`
- Prompt template, guardrails, and the `AGENTS.md` template: `docs/workshop-1/prompting.md`
- Xcode agents / OpenCode: `docs/workshop-1/xcode-agents.md`, `docs/workshop-1/opencode.md`
- Choosing a model (AFM 3 Core / Advanced / PCC / cluster): `docs/workshop-2/models.md`, `docs/workshop-2/foundation-models.md`
- AI cluster reference (models, setup, errors, fallback): `docs/workshop-2/hackathon-ai.md`
- Core AI (on-device open-source models, iOS 27): `docs/workshop-3/core-ai.md`
- Sensors, Create ML, Core ML, LiDAR: `docs/workshop-3/*.md`
- Vision / VisionKit (Thai `th-TH`, camera on a real iPad only): `docs/workshop-5/*.md`
- "Add to your app" checklists with Info.plist keys + agent prompts: `docs/workshop-3/4/5/add-to-your-app.md`
- Workshop overviews 1–5: `docs/workshop-*/index.md`

### Found online

| Source | Why it matters |
|---|---|
| AI cluster Swift package: https://github.com/swiftcodingclubth/yidh26-ai (exact version `0.0.2`, tags `0.0.1`, `0.0.2`) | How the app talks to the Mac cluster. Its README confirms `.chat`, `respond`/`streamResponse`, OCR/TTS/ASR, and that `LanguageModelSession` with a cluster model is iOS 27 only |
| Handbook repo: https://github.com/swiftcodingclubth/yidh26-swift-handbook | Starter projects for workshops 3–5 |
| Last year's event (YIDH 2025, Mahidol ICT, 26–28 Apr 2025): https://www.ict.mahidol.ac.th/younghackathon/ | Background: same organizers (Swift Coding Club TH, OBEC), finalists from 5 regions |
| News about YIDH 2025: https://news.ict.mahidol.ac.th/hackathon-young-ios-developer-at-muict/ | 20 teams, 5 winning teams, 2 days of hacking + clinics, then pitching |
| Swift Coding Club Thailand: https://www.swiftcodingclubth.com | The organizing community |
| Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines | Basis of the design criterion |

> Not related, but it came up in searches: Apple's Swift Student Challenge is a separate yearly contest (Feb). It is not this event.

---

## 7. Still unknown — ask staff

- [ ] Exact pitch day/time, the submission deadline, and whether there's a final round after the first 5-min round
- [ ] Our official team repo URL (Team card)
- [ ] **AI cluster address** (handbook now says TBC) and the rate limit per team (TBC)
- [ ] The point split across the 5 criteria (the audio mentions "the first 60 points" and "10 points" but is unclear)
- [ ] How workshop/clinic points are earned and spent (staff said they'd explain on Day 2)
- [ ] Whether our iPad is a Pro (LiDAR) and has the M3/M4 + 12 GB needed for AFM 3 Core Advanced
