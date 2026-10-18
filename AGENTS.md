# AGENTS.md

Rules for any coding agent (Xcode agents, OpenCode, Claude, Codex, or others) working in this project.
Based on the YIDH26 handbook template. Read `ai/what-we-are-building.md` before suggesting features.

## About this app
Team **Super Jerry**'s SwiftUI app for iPad/iPhone, built at the Young iOS Developer Hackathon 2026 (YIDH26) at Srinakharinwirot University.
It solves one real problem for one real kind of person, using AI that runs on Apple devices.
<!-- Team: once the idea is picked, replace the line above with one sentence: who it's for + what problem it solves. -->

## Our team uses TWO Xcode versions. Code must build in BOTH.
- 1 M-chip Mac with **Xcode 27** (iOS 27 SDK).
- 2 Intel Macs with **Xcode 26** (iOS 26 SDK). These Macs cannot build iOS 27-only code.
- If code builds in Xcode 27 but not in Xcode 26, it is broken for 2 of our 3 machines.

## Hard rules
1. **Deployment target stays iOS 26.0.** Do not change it.
2. **Do not use iOS 27-only APIs** unless the user asks for one. When they do, wrap it like this so Xcode 26 still compiles:
   ```swift
   #if compiler(>=6.4)   // Swift 6.4 ships with Xcode 27
   if #available(iOS 27, *) {
       // iOS 27-only code
   }
   #endif
   ```
   For a framework that only exists in the iOS 27 SDK, also guard the import with `#if canImport(FrameworkName)`.
3. **Do not change project settings.** That includes the project format (keep objectVersion 77), the signing team, the bundle identifier, and the deployment target. Do not accept "Update to recommended settings."
4. **Do not edit `project.pbxproj` by hand.** Put new Swift files inside `SuperJerry/`. Xcode picks them up automatically (synchronized folder).
5. **No new Swift packages or dependencies** unless the user approves first. The one planned package is the AI cluster:
   `https://github.com/swiftcodingclubth/yidh26-ai`, **exact version `0.0.2`**, library `HackathonAI`.
6. **Never put secrets in code or commits**: API keys, passwords, tokens, personal data.
   The AI cluster key lives only in `SuperJerry/AICluster.swift`, which is gitignored.
7. **Health data: synthetic only** (PDPA). Medical-model output must be labeled "not medical advice" in the UI.

## AI in this app
The 3 options are a **menu, not a checklist**. Use the one that fits the problem, and say why:
- **Foundation Models** (`LanguageModelSession`, on-device AFM 3): short text tasks. Check `SystemLanguageModel.default.availability`
  and hide or fall back when it's unavailable. The Intel Macs' simulator has no Apple Intelligence, so test on the iPad.
- **Core ML / Create ML** (+ Vision, Sound Analysis, Core Motion, ARKit/LiDAR): recognizing images, sounds, text, and motion.
  **Core AI** (open-source models on device) is iOS 27 only: guard it with `#if compiler(>=6.4)` + `#if canImport(CoreAILanguageModels)`.
- **AI cluster** via `HackathonAI` (MLX on the organizers' Macs): heavy tasks, better Thai, OCR, speech. Event Wi-Fi only.
  - Use `aiCluster.respond(...)` / `streamResponse(...)` with model `.chat` (default), `.reasoning`, `.ocr`, `.medical`, `.tts`, or `.asr`.
    It works on iOS 26 and returns `String`.
  - `LanguageModelSession(model: aiCluster.languageModel(.chat))` needs Xcode 27 **and** iOS 27 at runtime. Only use it inside the iOS 27 guard,
    with the `respond(...)` path as the fallback.
  - **Always include an on-device fallback** and show in the UI who answered ("AI cluster" / "On-device").
- Thai text recognition (Vision/VisionKit) must include `"th-TH"` in the recognition languages.
- Camera, LiDAR, and motion don't work in the simulator: check availability and permissions before using them, and never crash.
- This project has no Info.plist file (it's generated). Add privacy keys (`NSCameraUsageDescription`, etc.) in target ▸ Info, not as a hand-written plist.

## How to work
- **Plan first.** Show a short plan and the files you will change. Wait for approval before editing.
- Keep each task small: one feature or one fix at a time.
- Work on the current feature branch. Never commit to `main`, never force-push, and never rewrite history.
- After changing code, build it:
  `xcodebuild -project SuperJerry.xcodeproj -scheme SuperJerry -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`
- Finish by listing what you changed and how the user can test it (Preview, Simulator, or iPad).

## Design
- **Read `DESIGN.md` before any UI work.** It defines Jenny's Apple Health–style look, the colors in `Theme`, the button styles, and who we design for.
- The research behind it (older users, Apple Health, sources) is in `docs/design/research.md`.
- Skills in `.claude/skills/`:
  - `jenny-design-review` (ours): use it to review or critique any screen.
  - Third-party, MIT: `swiftui-pro` (SwiftUI code), `ios-design-guidelines`, `ipados-design-guidelines` (Apple HIG rules). Don't edit their files.
  - **Our rules beat any skill.** `swiftui-pro` assumes iOS 27 and Swift 6.4, but we stay on iOS 26 and code that Xcode 26 can build.
    If a HIG skill disagrees with `DESIGN.md`, follow `DESIGN.md`.

## Code style
- SwiftUI only (no UIKit unless needed). One main view per file.
- Add a `#Preview` for every new view.
- Use clear names and short functions. Add comments only where the code isn't obvious.
- Follow Apple's Human Interface Guidelines: system colors, SF Symbols, Dynamic Type, and dark mode.

## Talking to the user
- The user is a high-school student. Explain changes simply.
- Reply in the language the user writes in (Thai or English).

## More context
- `ai/what-we-are-building.md`: the goal, the AI options, judging, and team workflow (**start here**)
- `ai/context/competition-brief.md`: full rules, schedule, AI cluster models
- `ai/prompts/`: ready-made prompts the team uses
