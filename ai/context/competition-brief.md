# Competition Brief — YIDH26 (Young iOS Developer Hackathon 2026) @ SWU

Last checked: **2026-10-17, 15:00**, against the online handbook (latest commit `be9adb4`, 14:00), the `yidh26-ai` package README,
and the kickoff audio transcript.

**Sources** (full list in [../what-we-are-building.md](../what-we-are-building.md#6-all-sources-so-far)):
- **Official handbook:** https://swiftcodingclubth.github.io/yidh26-swift-handbook/ ([repo](https://github.com/swiftcodingclubth/yidh26-swift-handbook)).
  The organizers update it **during the event**, so check the website, not an old download.
- **Kickoff briefing at SWU** (audio, transcribed and translated from Thai). The audio is noisy, so items marked **(?)** are unsure.
  Raw text: [kickoff-transcript-th.txt](kickoff-transcript-th.txt)

If anything here conflicts with the staff (พี่ๆ / TA) or the handbook, they're right. Update this file.

---

## TL;DR

- **3-day camp.** Day 1 is kickoff + workshops (until ~15:00–16:00), and you start building the same day. **Real build time is about 2 days.**
- **Theme: AI that runs on Apple devices.** Don't just wrap ChatGPT or another cloud API.
- **Start from a real person's real problem**, not "we want to build an app." **First task on Day 1: define the problem.**
- **One core feature that works live.** Open the app → the value shows up immediately. No sign-up, login, or onboarding.
- **Deliverables:** the Xcode project (zipped, uploaded via a link staff give you, **early**), a pitch deck **as a PDF**, and a **live demo**.
- **Pitch:** first round = **5 min pitch + ~2 min Q&A** (~7 min total). Judges come from several industries.

## The 3 rules (handbook)

1. **Commit before letting an AI agent edit code**, every time, so you can roll back.
2. **No API keys or personal data** in prompts or commits.
3. **Health data = synthetic only.** No real patient data (PDPA).

---

## Team kit & setup

| Device | Qty | Software | Use for |
|---|---|---|---|
| MacBook Pro (Apple Silicon) | 1 | macOS 26.6+, **Xcode 27** | Main machine: iOS 27 APIs, Xcode agents, Core AI, Private Cloud Compute |
| MacBook Pro (Intel) | 2 | macOS 15.6+, **Xcode 26** | SwiftUI, building, iPad testing, Git, OpenCode agent |
| iPad (M chip) | 1 | iPadOS 27, Developer Mode | **Test device and demo device.** Apple Intelligence + camera. LiDAR only on iPad Pro |

**Team card** (secret: don't post it or commit it): team number, **official team GitHub repo URL**, **AI cluster API key**, Wi-Fi, and your **iPad model**.

**Before the event:** everyone needs an Apple ID (free) and a GitHub account. Usernames go to the organizers so they can add you to the team repo.

**Setup on Day 1:**
1. Check the Team card.
2. Sign in to Xcode with your Apple ID (Settings ▸ Accounts) to get a *Personal Team*.
3. On the iPad, turn on Developer Mode (Settings ▸ Privacy & Security), then restart it.
4. Run the app on the iPad. The first time, trust the developer in Settings ▸ General ▸ VPN & Device Management.
5. Clone the team repo.

**Personal Team limits:** apps expire after 7 days, and you can only create a few new App IDs per week. **Reuse one project.**
If you see "bundle identifier is not available," a teammate's Personal Team already took that ID. Follow the Team card or ask a TA.

### The project must build on Xcode 26 *and* 27

- Keep the deployment target at **iOS 26**. Say **No** if Xcode 27 offers to "update project format / recommended settings."
- Wrap iOS 27-only code:

  ```swift
  #if compiler(>=6.4)   // Swift 6.4 = Xcode 27
  if #available(iOS 27, *) { /* iOS 27 API */ }
  #endif
  ```
  For frameworks that only exist in the iOS 27 SDK (e.g. Core AI), also use `#if canImport(CoreAILanguageModels)`.

### What runs where

| Feature | Intel Mac (Xcode 26) | Apple Silicon Mac (Xcode 27) | Simulator | Team iPad |
|---|:---:|:---:|:---:|:---:|
| SwiftUI, Git, OpenCode | ✓ | ✓ | ✓ | ✓ |
| Xcode agents (Claude / Codex / Antigravity) | ✗ | ✓ | — | — |
| Foundation Models (AFM 3 Core) | ✓ build | ✓ | ✗ on Intel Mac's simulator | ✓ |
| iOS 27 APIs: PCC, AFM 3 Core Advanced, Core AI, Siri AI / App Schema | ✗ | ✓ | — | ✓ (iPadOS 27) |
| Camera features (VisionKit scan, hand pose, live object detection), LiDAR | ✓ build | ✓ build | ✗ no camera | ✓ (LiDAR: iPad Pro only) |
| Core Motion / barometer | ✓ build | ✓ build | ✗ no sensors | ✓ |
| Read text from a photo, classify an image, sounds | ✓ | ✓ | ✓ (drag a photo onto the simulator) | ✓ |

**Always test on the real iPad.** The simulator can't fake the camera or sensors.

### AI coding agents

- **Xcode agents** (Apple Silicon Mac only) use the team's signed-in account, which has a **usage limit for the whole hackathon**.
  Save it for new features and hard bugs.
- **OpenCode** (any Mac, free model from OpenCode Zen) runs in Terminal. Use **Plan** mode first, then **Build** mode (Tab switches).
  `/undo` reverts its last edit. It can't see Xcode Previews, so build in Xcode yourself.
- `AGENTS.md` at the repo root holds the rules every agent follows. Ours is filled in.

---

## Workshops (Day 1)

| # | Topic | Highlights |
|---|---|---|
| 1 | Build your first app with coding agents (**mandatory, everyone**) | Git/GitHub team workflow, Xcode agents, OpenCode, prompting, `AGENTS.md` |
| 2 | Foundation Models + on-prem AI | On-device AFM 3, Private Cloud Compute, the AI cluster, `@Generable`, streaming, tool calling. Exercise: StudyNotes app |
| 3 | Core ML + Create ML | Sensors (Core Motion, barometer, Sound Analysis with 300+ sounds, LiDAR via ARKit), train a model in Create ML, Core ML, pretrained models (MobileNetV2, YOLOv3), Core AI |
| 4 | App Intents | One action available in Shortcuts, Spotlight, Siri, widgets, and Control Center. App Schema for Siri AI (iOS 27 only) |
| 5 | Vision + VisionKit | Live text/QR scanning, document scanning, reading text from photos, 21-point hand pose |

- After Workshop 1, the **afternoon workshops (2–5) are electives**. The audio says about 4 workshops run in **2 rounds, round-robin** (?). **Pick them based on your idea.**
- If the team splits up, whoever goes to **Room A** takes the Apple Silicon Mac.
- Each workshop has a starter project in the handbook repo (`starter/workshop-3`, `-4`, `-5`). Its "add to your app" page has files to copy and ready-made agent prompts.

---

## Picking the AI: a menu, not a checklist

From the kickoff: *"we have 3 options for you"* and *"you don't need to use all of them, choose by what you need."*
**A bigger model doesn't mean more points.** A team using the small on-device model can beat a team on a big cluster model
if their choice fits the problem better. **Explain why you chose it in the pitch.**

**The 3 options from the kickoff talk:**
1. **Foundation Models**: Apple's on-device LLM. Free, offline, private. Good for short, focused text tasks, but it's small, not ChatGPT-level.
2. **Core ML + Core AI** (with **Create ML** to train your own): run your own or open-source models on the device's Neural Engine. Offline and fast.
3. **MLX on the Mac cluster**: **8 Mac Studios + 6 Mac minis** brought by the organizers, running bigger open models. Use it for heavy work,
   or for sensitive data you don't want on a third-party cloud. There's a session on how to use it.

Separately, the talk said **Apple devices have great sensors**, e.g. **LiDAR** on iPad Pro / iPhone Pro, plus camera, gyroscope, Face ID, and microphone.

### Detail per option (handbook)

| Where | What | Good for | Requires |
|---|---|---|---|
| On-device | **AFM 3 Core** (`LanguageModelSession`) | Summarize, extract, classify, `@Generable` structs, tool calling (keep it to ≤3–5 tools) | Any M-chip iPad with Apple Intelligence on. Check `SystemLanguageModel.default.availability` |
| On-device | **AFM 3 Core Advanced** | Smarter reasoning, understands images | **iOS 27** + M3/M4 iPad with ≥12 GB memory (or iPhone 17 Pro) |
| On-device | **Core ML / Create ML** | Classify text, images, or sounds; detect objects; pretrained MobileNetV2 / YOLOv3 | Labeled data for custom models. Create ML text models are **English-only** unless you train them on Thai data |
| On-device | **Core AI** | Open-source LLMs (Qwen3 0.6B), speech-to-text (Whisper), image models, used through `LanguageModelSession` | **Xcode 27 + iOS 27**. Get the ~430 MB model **from a TA**. Needs the Increased Memory Limit entitlement (untested with Personal Team) |
| Apple's servers | **AFM 3 on Private Cloud Compute** | Harder language tasks, still private, free | **iOS 27 / Xcode 27** + internet |
| Event cluster | **AI cluster** via the `HackathonAI` package | Better Thai, reasoning, OCR, speech, medical terms | Event Wi-Fi + team API key |

### AI cluster (`HackathonAI` package)

- Package: `https://github.com/swiftcodingclubth/yidh26-ai`, **Exact Version `0.0.2`**, library `HackathonAI`. Works on iOS 26+ (Xcode 26 or 27).
- **Address + key:** the address is **TBC** in the handbook (it was changed today). Get it from staff or the Team card.
  Put both in `AICluster.swift`, which is **gitignored in our repo**:
  ```swift
  import HackathonAI
  let aiCluster = HackathonAI(baseURL: "http://[address from staff]", apiKey: "team-XX-xxxx")
  ```
- **Models** (names in the package; the real model IDs get mapped when the event network is ready; call `models()` to see what's live):

| Swift | Model | Use for |
|---|---|---|
| `.chat` (default) | **Smart Route**: Gemma 4 26B / Qwen3.6 35B, picked automatically, 3 machines | Summaries, Q&A, Thai, `@Generable`, tool calling. **Start here** |
| `.reasoning` | Qwen3.8 27B, 4 machines, accepts images | Multi-step reasoning, documents, charts. Slower |
| `.medical` | MedGemma 1.5 4B | Medical terms. **Synthetic data only, not a diagnosis.** Say so in the UI |
| `.ocr` | Typhoon OCR 1.5 2B | Thai + English text from photos (`recognizeText(in:)`) |
| `.tts` / `.asr` | Qwen3-TTS 1.7B / Qwen3-ASR 1.7B | Text → speech (`speak`) / speech → text in Thai or English (`transcribe`) |

- **Two ways to call it:**
  - **Works everywhere (iOS 26):** `aiCluster.respond(to:...)`, `streamResponse`, `respond(to:generating:)` for `@Generable`. Returns a `String`, so there's no `.content`.
  - **iOS 27 only:** `LanguageModelSession(model: aiCluster.languageModel(.chat), tools: ...)` for conversation memory + tool calling.
    This needs **Xcode 27 to build AND an iPad on iOS 27 to run**, wrapped in `#if compiler(>=6.4)` + `if #available(iOS 27, *)`, with the `respond(...)` path as the fallback.
- **Info.plist:** add `NSLocalNetworkUsageDescription` + `NSAppTransportSecurity › NSAllowsArbitraryLoads = YES`. **Don't** add `NSAllowsLocalNetworking`, or iOS will ignore the other one.
  Our project has **no Info.plist file** (Xcode generates it), so add these in **target ▸ Info**. Xcode will then create the file.
- **Errors (`HackathonAIError`):**

  | Error | Meaning |
  |---|---|
  | `.unreachable` | Off the event Wi-Fi, or the cluster is down |
  | `.blockedByAppTransportSecurity` | The Info.plist setting is missing |
  | `.unauthorized` | Wrong key |
  | `.rateLimited(retryAfter:)` | Too many calls. Wait (the rate limit is TBC) |
  | `.modelNotFound` | Wrong model name. Call `models()` |

- **Habits:**
  - Call the model on a button tap, never in a loop or on every keystroke.
  - Cap `maximumResponseTokens`.
  - Prefer `.chat` over `.reasoning`.
  - **Always have an on-device fallback**, and show in the UI who answered.
  - Test with Wi-Fi **off** before the demo.

### Other gotchas from the workshops

- **Thai text recognition:** pass `"th-TH"` in the recognition languages (VisionKit `.text(languages:)` / Vision `recognitionLanguages`), or Thai gets skipped.
- **Permissions** (target ▸ Info):
  - `NSCameraUsageDescription`: camera, LiDAR, scanning. Without it, the app **crashes** when it opens the camera.
  - `NSMicrophoneUsageDescription`: Sound Analysis.
  - `NSMotionUsageDescription`: barometer, pedometer, activity.
- **Check before using:** LiDAR availability, `DataScannerViewController.isSupported/isAvailable`, model availability. Hide the feature or fall back; never crash.
- **Privacy:** camera, microphone, and motion data are personal. If the app saves them or sends them to the cluster, tell the user.
- **iOS 27 extras (Xcode 27):**
  - Send images straight to Foundation Models (`Attachment`) and use `OCRTool` / `BarcodeReaderTool`.
  - Siri AI App Schema (`@AppIntent(schema:)`). Let Xcode autocomplete generate it; agents don't know it yet.

---

## Examples from the kickoff talk

- **Kurashiru (a Japanese recipe app):** moved a scanning feature from the OpenAI API to on-device AI. Cost per call is tiny, but at hundreds of thousands to millions of users it adds up.
- **Rural use case (?):** an on-device model gives results in seconds without internet, instead of "upload a photo and wait."
- **A transcription/meeting-notes company:** switched from paid speech-to-text APIs to Whisper on its own Mac cluster. That saved money and kept private recordings in-house.
- **A health research project in Europe (?)** used on-device machine learning with health data.
- **An airline using iPads in the cockpit:** works offline in the air, uses Face ID / Touch ID as a digital signature instead of paper, and uses the gyroscope to log turbulence for future flights.

**The 3 takeaways they summarized:**
1. **Find the problem first.** If you're not sure it's real, ask someone who has it: friends, family, someone close to you. Validate before building.
2. **Do the small work on-device** (read, extract, summarize). Send to the cloud or cluster only when you must.
3. **Show measurable impact:** hours saved, money saved, fewer errors. Put numbers in the pitch.

---

## Schedule (from the audio only; the handbook has no schedule)

| When | What |
|---|---|
| Day 1 | Kickoff → Workshop 1 (everyone) → elective workshops in 2 rounds (?) until ~15:00–16:00 → start building. **Define your problem today.** |
| Day 2 | Build. Mentor clinics: tech, plus **UX/design mentors from industry every day**. Apple Vision Pro try-out. The point system is explained in detail (?) |
| Before pitching | **Submit the Xcode project** (zip, via the staff's link) so they can load demo devices. Make sure it builds and runs first, and **ask staff to check it** before your slot. The demo device is the iPad. If the app is iPhone-only, staff have iPhones (?) |
| Day 2–3 (?) | **Pitching, first round:** 5-min pitch + ~2-min Q&A. "First round" suggests finalists may pitch again (?) |

## Point system

- Earn points by **attending workshops** and **answering quiz questions** during them (e.g. "Who is Apple's CEO?").
- **Spend points** to skip the queue at mentor clinics. Useful when everyone wants help at the same time. Time your clinic visits well.

## Judging (5 criteria; total points unclear in the audio)

1. **Real-World Impact:** does it solve a real problem for real users? Not just a demo of basic app features.
2. **Use of AI / technology:** the right model or framework for the job. "A team using the Foundation Model could score higher than a team using MLX," depending on the real use.
3. **Technical Execution:** the app actually works, with no bugs, and the core flow is complete.
4. **Design (UX/UI):** follow Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines). It should look like a real, usable app.
   AI agents are allowed, but AI-generated design must still look and feel right.
5. **Pitch + Q&A + Ownership:** a clear pitch, good answers, and **everyone on the team takes part** and understands the problem. Not one person doing everything.

> Scoring split **(?)**: the audio mentions "the first 60 points" (problem/impact side) and "10 points" around pitch/Q&A/ownership.
> Neither was clear, so ask staff. Either way, **problem + impact weigh the most.**

## Submission & pitch rules

- **Code:** the Xcode project folder, zipped, via the staff link. Submit **early** and get staff to check that it runs.
- **Pitch deck:** **PDF only**, no animations (too many teams, too little time).
- **No unauthorized logos or trademarks** in slides. Ask staff first if you really need one.
- **Live demo** in real time on the event's device. Keep a backup screen recording.
- AI coding agents in Xcode are allowed.

## Past edition

- YIDH 2025 at Mahidol ICT (26–28 Apr 2025), with OBEC (สพฐ.), Authorized Apple Partner Education, and Swift Coding Club TH.
  It was the final round for secondary-school teams from 5 regions; 20 teams took part and 5 won awards.
  https://www.ict.mahidol.ac.th/younghackathon/ · https://news.ict.mahidol.ac.th/hackathon-young-ios-developer-at-muict/
