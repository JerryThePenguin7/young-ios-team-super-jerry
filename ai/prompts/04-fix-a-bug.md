# 04 — Fix a bug

Give the agent the symptom, the error, and the location. Don't just say "fix the bug."

```text
BUG:         [what you did → what happened → what you expected,
              e.g. "Tapping Save crashes with 'index out of range' in NoteStore.swift line 42."]
ERROR:       [paste the exact error from Xcode's console]
WHERE:       [device: iPad / Simulator, Xcode 26 or 27]
CONSTRAINTS: Fix the cause, not just the symptom. Don't change unrelated files or project settings.
             Must still build on Xcode 26 and 27 (see AGENTS.md).
PROCESS:     Explain the cause first and propose a fix. Wait for my approval before editing.
```

If it builds on Xcode 27 but not Xcode 26, say that. It's usually an iOS 27-only API that needs `#if compiler(>=6.4)`.
