# Competition Brief — YIDH26 (Young iOS Developer Hackathon 2026) @ SWU

Sources:
- **Official handbook (read this!):** https://swiftcodingclubth.github.io/yidh26-swift-handbook/
  ([repo](https://github.com/swiftcodingclubth/yidh26-swift-handbook), organized with Swift Coding Club TH)
- The kickoff briefing at Srinakharinwirot University (audio, transcribed and translated from Thai).
  The audio was noisy, so details marked **(?)** are unsure. Raw transcript: [kickoff-transcript-th.txt](kickoff-transcript-th.txt)

If anything here conflicts with the staff (พี่ๆ / TA) or the handbook, they're right. Update this file.

## TL;DR

- **3-day camp.** Day 1 is kickoff + workshops (until ~15:00–16:00), and you start building the same day. **Real build time is about 2 days.**
- **Theme: AI that runs on Apple devices.** Don't just wrap ChatGPT. Use on-device models, Core ML, sensors, and the event's AI cluster.
- **Start from a real person's real problem.** Not "we want to build an app." Today's first task: **define the problem.**
- **One core feature that works live.** Open the app → the value shows up immediately. No sign-up, login, or onboarding.
- **Deliverables:** Xcode project (to staff, early) + pitch deck **as a PDF** + a **live demo**.
- **Pitch:** 5 min + ~2 min judge Q&A.

## The 3 rules (handbook)

1. **Commit before letting an AI agent edit code**, every time, so you can roll back.
2. **No API keys or personal data** in prompts or commits.
3. **Health data = synthetic only.** No real patient data (PDPA).

## Team kit

| Device | Qty | Software | Use for |
|---|---|---|---|
| MacBook Pro (Apple Silicon) | 1 | macOS 26.6+, **Xcode 27** | Main machine: iOS 27 APIs, Xcode agents (Claude/Codex), Core AI |
| MacBook Pro (Intel) | 2 | macOS 15.6+, **Xcode 26** | SwiftUI, building, iPad testing, Git, OpenCode agent |
| iPad (M chip) | 1 | iPadOS 27, Developer Mode | **Test device.** Apple Intelligence + camera. LiDAR only if it's an iPad Pro (check the Team card) |

**Team card** (secret: don't post it or commit it): team number, **official team GitHub repo URL**, **AI cluster API key**, Wi-Fi.

**The project must build on Xcode 26 *and* 27.** Keep the deployment target at **iOS 26**, and say **no** if Xcode 27 offers to "update project format / recommended settings."
Wrap iOS 27-only code like this:

```swift
#if compiler(>=6.4)   // Swift 6.4 = Xcode 27
if #available(iOS 27, *) { /* iOS 27 API */ }
#endif
```

Personal Team signing: apps expire after 7 days and you can only create a limited number of App IDs per week. **Reuse one project.** If you get "bundle identifier not available," follow the Team card or ask a TA.

## Workshops (Day 1)

| # | Topic | Highlights |
|---|---|---|
| 1 | Build your first app with coding agents (**everyone**) | Git/GitHub team workflow, Xcode agents, OpenCode, prompting |
| 2 | Foundation Models + on-prem AI | On-device AFM 3, Private Cloud Compute, the event's AI cluster, `@Generable`, tool calling |
| 3 | Core ML + Create ML ([page](https://swiftcodingclubth.github.io/yidh26-swift-handbook/workshop-3/)) | Sensors (Core Motion, barometer, Sound Analysis with 300+ sounds, LiDAR via ARKit), train a model in Create ML, run it with Core ML, Core AI on-device LLM |
| 4 | App Intents | One action in Shortcuts, Spotlight, Siri, widgets, and Control Center; App Schema for Siri AI (iOS 27) |
| 5 | Vision + VisionKit | Document scanning, live text/QR, text recognition, 21-point hand pose |

The afternoon workshops are pick-by-idea. If the team splits up, whoever goes to **Room A** takes the Apple Silicon Mac.

## Picking the AI (bigger model ≠ more points)

The judges said a team using the small on-device model can beat a team using a big cluster model **if their choice fits the problem better**. Explain *why* you chose it in the pitch.

| Where it runs | What | Good for | Needs |
|---|---|---|---|
| **On-device** | **AFM 3** (Foundation Models, `LanguageModelSession`) | Short summaries, extraction, `@Generable` structs, tool calling. Free, private, offline, fast | iPad with Apple Intelligence (Advanced tier needs M3/M4 + 12 GB) |
| **On-device** | **Core ML / Create ML**, Apple's pretrained models | Classify text, images, or sounds; detect objects. Train your own in seconds | Labeled data (for custom models) |
| **On-device** | **Core AI** (open-source LLMs and Whisper on device) | Turn ML results into friendly text; offline speech-to-text | Xcode 27 |
| **Apple servers** | **Private Cloud Compute** (bigger AFM 3) | Harder language tasks, still private | Internet |
| **Event AI cluster** | Mac Studios + Mac minis, through the `HackathonAI` Swift package | Better Thai, reasoning, OCR, TTS/ASR, medical terms | Event Wi-Fi + team API key |

**AI cluster models** (`https://github.com/swiftcodingclubth/yidh26-ai`, **exact version 0.0.2**):

| Swift | Model | Use for |
|---|---|---|
| `HackathonAI.smartRoute` (`"@route/sccth-gq"`) | Gemma 4 26B / Qwen3.6 35B (auto-routed) | Default: summaries, Q&A, Thai, structured output |
| `.reasoning` | Qwen3.8 27B (text + images) | Multi-step reasoning, documents, reading charts. Slower |
| `.medical` | MedGemma 1.5 4B | Medical terms. **Synthetic data only, not a diagnosis.** Say so in the UI |
| `.ocr` | Typhoon OCR 1.5 2B | Thai and English text from photos |
| `.tts` / `.asr` | Qwen3-TTS / Qwen3-ASR | Speech out / speech in (Thai and English) |

Cluster gotchas:
- Put the key in `AICluster.swift`. **That file is in our `.gitignore`.** Never commit it.
- Info.plist needs `NSLocalNetworkUsageDescription` + `NSAppTransportSecurity › NSAllowsArbitraryLoads = YES`. **Don't** add `NSAllowsLocalNetworking`, or ATS will block the connection.
- Don't call the model in a loop or on every keystroke. Cap `maximumResponseTokens`. Prefer Smart Route.
- **Always have an on-device fallback.** The Wi-Fi can die mid-demo, so test with Wi-Fi off before you pitch.

## Examples from the kickoff

- **Kurashiru (a Japanese recipe app)** moved from the OpenAI API to on-device AI. API costs are tiny per call but huge at millions of users.
- **Rural screening:** on-device results come back in seconds without internet, instead of "upload a photo and wait."
- **A transcription company** moved to Whisper on its own Mac cluster to cut cost and keep recordings private.
- **An airline with cockpit iPads:** works offline, uses Face ID as a digital signature, and logs turbulence with the gyroscope.

**3 takeaways:** (1) find and validate a real problem (ask people who have it), (2) do small work on-device and send to cloud or cluster only when needed, (3) show **measurable impact**: hours saved, money saved, fewer errors.

## Schedule (as briefed)

| When | What |
|---|---|
| Day 1 | Kickoff → ~4 workshops (rotating (?)) until ~15:00–16:00 → start building. **Define your problem today.** |
| Day 2 | Build. Mentor clinics (tech + UX/design mentors from industry), Apple Vision Pro try-out |
| Before pitching | **Submit the Xcode project** to staff early so they can load demo devices. Make sure it builds. Ask staff to check it first |
| Pitch day | **5-min pitch + ~2-min Q&A** with judges from several industries. Demo live |

**Point system:** earn points by attending workshops and answering quiz questions. Spend them to **skip the queue at mentor clinics**.

## Judging (100 pts, 5 criteria)

1. **Real-World Impact:** solves a real problem for real users.
2. **Use of AI / tech:** the right model or framework for the job.
3. **Technical Execution:** works with no bugs; the core flow is complete.
4. **Design (UX/UI):** follows Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines). AI-generated UI is OK, but it must still feel right.
5. **Pitch, Q&A, Ownership:** a clear pitch and good answers, and **everyone on the team takes part** and can explain the project.

> Something was said about "the first 60 points" covering the problem/impact side (?). Either way, **problem + impact weigh the most.**

## Submission & pitch rules

- Pitch deck **PDF only**, no animations.
- **No unauthorized logos or trademarks** in slides. Ask staff first.
- The demo must work live. Keep a backup screen recording.
- AI coding agents are allowed (and encouraged).

## Past edition

- YIDH 2025 at Mahidol ICT (26–28 Apr 2025), with OBEC (สพฐ.) and Swift Coding Club TH; finalists from 5 regions:
  https://www.ict.mahidol.ac.th/younghackathon/
