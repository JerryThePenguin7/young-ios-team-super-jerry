# 05 — Connect to the AI cluster (with on-device fallback)

Only if the team decided the cluster is the right fit (see prompt 02). **One person** adds the package
and pushes it before anyone else branches, so we don't get `project.pbxproj` conflicts.

Before running this prompt, do these yourself (never paste the API key into a prompt):
1. File ▸ Add Package Dependencies… → `https://github.com/swiftcodingclubth/yidh26-ai` → **Exact Version `0.0.2`** → add `HackathonAI` to the SuperJerry target.
2. Create `SuperJerry/AICluster.swift` with the key from the Team card (the template is in the README). It's gitignored.

```text
GOAL:        Make [feature, e.g. "summarize the scanned label"] call the AI cluster using HackathonAI.smartRoute,
             and fall back to on-device LanguageModelSession when the cluster fails.
CONTEXT:     [files], SuperJerry/AICluster.swift (exists locally; don't print or commit the key),
             ai/context/competition-brief.md (AI cluster section).
CONSTRAINTS: Follow the handbook pattern: try aiCluster.respond(...), catch → on-device.
             Show in the UI who answered ("AI cluster" / "On-device"). Only call the model on a button tap,
             never in a loop or on every keystroke. Set maximumResponseTokens. Info.plist needs
             NSLocalNetworkUsageDescription + NSAllowsArbitraryLoads (NOT NSAllowsLocalNetworking).
             iOS 26 target; don't use LanguageModelSession(model: aiCluster.languageModel(...)) unless wrapped for iOS 27.
DONE WHEN:   It builds, works on event Wi-Fi, AND still works with Wi-Fi turned off.
PROCESS:     Show me a plan first. Wait for my approval before editing.
```
