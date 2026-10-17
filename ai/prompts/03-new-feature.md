# 03 — New feature

The handbook's prompt template. Use it with Xcode agents or OpenCode. One feature per prompt.

```text
GOAL:        [one clear result, e.g. "Add a screen that scans a pill bottle label with the camera and shows the drug name."]
CONTEXT:     [files or screens involved, e.g. ContentView.swift, ScanView.swift]
CONSTRAINTS: SwiftUI only, iOS 26 deployment target, no iOS 27-only APIs (or wrap them per AGENTS.md),
             no new packages, don't touch project settings or project.pbxproj.
DONE WHEN:   It builds with xcodebuild, it works in the Preview / on the iPad,
             and existing features still work.
PROCESS:     Show me a plan first. Wait for my approval before editing.
```

Good vs bad:

| ✗ Bad | ✓ Good |
|---|---|
| "Make the app look better" | "Add dark mode support to ScanView using system colors." |
| "Add all the features from our idea" | One task per prompt, one feature at a time |
