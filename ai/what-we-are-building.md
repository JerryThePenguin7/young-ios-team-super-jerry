# What we're building, and where every fact came from

Written 2026-10-17 (Day 1 of the camp). This is the "same page" doc for team **Super Jerry**.
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
| **Foundation Models** (Apple's on-device LLM, AFM 3) | On the iPad | Short text jobs: summarize, extract, classify, fill a form. Free, private, offline |
| **Core ML / Create ML** (+ sensors: camera, LiDAR, motion, microphone) | On the iPad | Recognizing things: photos, sounds, movement, or a model we train ourselves |
| **MLX on the event's Mac cluster** (8 Mac Studios + 6 Mac minis) | Organizers' Macs, over event Wi-Fi | The job is too heavy for the iPad: better Thai, reasoning, OCR, speech |

**Use more than one only when each has a real job.** Two examples:
- Core ML recognizes something → Foundation Models turns the result into advice.
- The cluster does the heavy work → on-device AI takes over when the Wi-Fi dies. The handbook recommends this fallback.

If a judge asks "why did you need this?", we must have an answer.

## 3. Order of work

1. **Problem first.** Find a real person with a real problem and ask them about it. "My grandma forgets which pills she's taken" beats "a health app."
2. **Then pick the AI** that fits, from the table above.
3. **Build one core feature** that shows its value as soon as the app opens. No login, sign-up, or onboarding.
4. **Measure the impact:** hours saved, money saved, fewer mistakes. Put the numbers in the pitch.

## 4. How we'll be judged (100 pts, 5 criteria)

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
| 2 | **Official handbook (source)** https://github.com/swiftcodingclubth/yidh26-swift-handbook | The organizers' workshop handbook (MkDocs source + starter Xcode projects for workshops 3–5) | Team kit (1 Apple Silicon Mac, 2 Intel Macs, 1 iPad), Team card, the 3 rules, Xcode 26/27 compatibility, AI cluster models + setup, Git workflow |
| 3 | **Handbook website** https://swiftcodingclubth.github.io/yidh26-swift-handbook/ (Jerry sent the [Workshop 3 page](https://swiftcodingclubth.github.io/yidh26-swift-handbook/workshop-3/)) | The published version of #2 | Same as #2. Workshop 3 covers sensors (Core Motion, Sound Analysis, LiDAR), Create ML, Core ML, and Core AI |
| 4 | **This repo** `github.com/JerryThePenguin7/young-ios-team-super-jerry` (private) | Starter SwiftUI app (Hello World) | The base for the team app. Its format was changed so Xcode 26 can open it, and it gained AGENTS.md and this `ai/` folder |

### Handbook pages used most

Paths are inside the handbook repo's `docs/` folder.

- Getting started (Team card, signing, Xcode 26/27): `docs/getting-started.md`
- Hardware: `docs/workshop-1/hardware.md`
- Git & GitHub workflow: `docs/workshop-1/git.md`
- AI cluster reference (models, setup, fallback): `docs/workshop-2/hackathon-ai.md`
- Workshop overviews 1–5: `docs/workshop-*/index.md`

### Found online

| Source | Why it matters |
|---|---|
| AI cluster Swift package: https://github.com/swiftcodingclubth/yidh26-ai (exact version `0.0.2`) | How the app talks to the Mac cluster |
| Handbook repo: https://github.com/swiftcodingclubth/yidh26-swift-handbook | Starter projects for workshops 3–5 |
| Last year's event (YIDH 2025, Mahidol ICT, 26–28 Apr 2025): https://www.ict.mahidol.ac.th/younghackathon/ | Background: same organizers (Swift Coding Club TH, OBEC), finalists from 5 regions |
| News about YIDH 2025: https://news.ict.mahidol.ac.th/hackathon-young-ios-developer-at-muict/ | 20 teams, 5 winning teams, 2 days of hacking + clinics, then pitching |
| Swift Coding Club Thailand: https://www.swiftcodingclubth.com | The organizing community |
| Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines | Basis of the design criterion |

> Not related, but it came up in searches: Apple's Swift Student Challenge is a separate yearly contest (Feb). It is not this event.

---

## 7. Still unknown — ask staff

- [ ] Exact pitch day/time and the submission deadline
- [ ] Our official team repo URL (Team card)
- [ ] AI cluster rate limit per team (handbook says TBC)
- [ ] How "the first 60 points" split across criteria (heard in the audio but unclear)
- [ ] Whether our iPad is a Pro (LiDAR) and has the M3/M4 + 12 GB needed for AFM 3 Core Advanced
