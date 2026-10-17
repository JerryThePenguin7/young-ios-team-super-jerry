# CLAUDE.md — Super Jerry

Context for Claude (and other AI assistants) working in this repo.

## What this is

Team **Super Jerry**'s entry for the **Young iOS Hackathon at Srinakharinwirot University (Oct 2026)**.
It's a ~2-day build, judged on a live demo + 5-min pitch. The full rules are in `docs/COMPETITION.md`; read it before suggesting features.

## Priorities (in order)

1. **One core feature that works live.** No login, sign-up, onboarding, or settings unless they're the point.
2. **AI that runs on Apple devices.** Prefer `FoundationModels` (on-device LLM) or Core ML/Create ML.
   Use the organizers' MLX Mac cluster only for heavy or sensitive workloads. Don't call OpenAI or other cloud LLM APIs.
3. **Design follows Apple HIG.** Use native SwiftUI components, SF Symbols, Dynamic Type, and dark mode.
4. **Never crash in the demo.** Handle model-unavailable cases (e.g. `SystemLanguageModel.default.availability`)
   with a graceful fallback or sample data.

## Official handbook

The event handbook (workshops, AI cluster, code snippets) lives at
https://swiftcodingclubth.github.io/yidh26-swift-handbook/. A local copy may be at `../yidh26-swift-handbook-main/`.
Prefer its patterns (e.g. `HackathonAI` package usage, on-device fallback) over inventing new ones.

## Tech

- Swift + SwiftUI. **Must build on both Xcode 26 (Intel Macs) and Xcode 27 (Apple Silicon Mac).**
  - Deployment target stays **iOS 26**. Keep the project format at objectVersion 77; don't accept Xcode's "update project format" prompt.
  - Wrap iOS 27-only APIs in `#if compiler(>=6.4)` + `if #available(iOS 27, *)`.
- Test device is an M-chip iPad (iPadOS 27). Camera, sensors, and Apple Intelligence need the real iPad, not the simulator.
- AI cluster: package `https://github.com/swiftcodingclubth/yidh26-ai` @ exact `0.0.2`, library `HackathonAI`.
  The API key goes in `SuperJerry/AICluster.swift`, which is **gitignored. Never commit keys.**
  Always provide an on-device (`LanguageModelSession`) fallback when the cluster is unreachable.
- Health features: synthetic data only, and the UI must say results aren't medical advice.
- Project: `SuperJerry.xcodeproj`, sources in `SuperJerry/`. Entry point `MyApp.swift`.
- Build check (no signing):
  ```bash
  xcodebuild -project SuperJerry.xcodeproj -scheme SuperJerry -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
  ```
- No third-party dependencies unless the team agrees. Fewer moving parts means fewer demo-day surprises.

## Conventions

- Keep it simple: one `View` per file, plain `@Observable` models, no heavy architecture.
- Teammates are high-school students who are learning, so keep code readable with short comments where it's non-obvious.
- Don't commit personal signing changes (`DEVELOPMENT_TEAM`, bundle ID tweaks) or `xcuserdata/`.
