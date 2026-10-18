# Jerry's notes (for switching PCs)

Written 18 Oct 2026 (Day 2), at the end of a long Claude session. Everything here is what *you* need. The full app status for the team and for AI chats is in [ai/project-status.md](ai/project-status.md).

---

## 1. Before you leave this PC ⚠️

These are **only on this computer**. They are not on GitHub:

| What | Where | What to do |
|---|---|---|
| **Research notes** (Thai medicine label datasets, OCR, synthetic data) | `research_notes/` (100 KB) | Copy the folder to the new PC (AirDrop or USB), or ask Claude to commit it |
| **Claude's memory of how you like to work** | `~/.claude/projects/-Users-sccths-Documents-SuperJerry/memory/` | Optional. The same rules are in `AGENTS.md`, so a new PC is fine without it |
| **This notes file** | `JERRY-NOTES.md` | It's only on GitHub if you commit it. Otherwise copy it too |
| Envelope test output (300 fake envelope photos) | `tools/envelope-test/out/` (31 MB) | Not needed: it can be regenerated. The test's code is on GitHub in PR #7 |
| Old copy of the plan | `claude-plan/` | Not needed: the same plan is in `docs/pill-reader/plan.md` |

**Not on this PC either:** `SuperJerry/AICluster.swift` (the AI-cluster key) was never created here. On the new PC, make it from the Team card if you need it (see README → Secrets). Never commit it.

## 2. On the new PC

```bash
git clone https://github.com/JerryThePenguin7/young-ios-team-super-jerry.git
```
```bash
open young-ios-team-super-jerry/SuperJerry.xcodeproj
```

- Use **Xcode 26 or 27**. If Xcode 27 asks to "update to recommended settings / project format", say **No**.
- To run it on the iPad, set *your* Team in Signing & Capabilities, but **don't commit that change**.
- Then copy `research_notes/` into the project folder.

## 3. Where things are right now

- **Newest version:** GitHub `main` at commit `48795a1` (PR #12). This PC is on it too.
- **Open PR:** #7 (`feature/envelope-test`), the envelope accuracy test (300 fake envelopes, ~99% read correctly). It's not merged yet; check with the team.
- **Merged today (by me + Claude):**
  - #1: the first Health-style design, plus `DESIGN.md` and the SwiftUI Pro skill
  - #3: the floating scan bar, a plain +, folding groups, gray and white colors
  - #4: `ai/project-status.md` (the "read me first" for new chats)
  - #9: the UI UX Pro Max skill
  - #11: polish (one set of corner radii, round buttons, tap feedback)
  - #12: the new week view and one-step-bigger text
- **Merged today (by your friend):** #2, #5, #6, #8, #10, #13 (tabs, checklist, one scan button, Medicine Storage, plain lists, and more)

## 4. To-do (what we planned)

- [ ] **3. Color rule: the focus action is filled, secondary actions are outlined.** Wait for your friend to finish, then do it from the newest `main`:

  | Where | Change to |
  |---|---|
  | Tabs | the chosen one filled, the other outlined |
  | Log sheet: Skip / Taken | outlined until picked, filled once picked |
  | "Log All as Taken" | green outline |
  | Round +, …, speaker | thin outline, or just the icon for "…" |
  | Delete this medicine | red outline |
  | Scan, Done, Read aloud, the ticked circle | keep filled |

- [ ] **4. A slim divider between medicines inside a Log card**, starting at the medicine's name, like iOS lists.
- [ ] **One-step-bigger text in your friend's files** (home, Log cards, Taken card, medicine card, tutorial, scan bar). You said the small text was about 14 pt, so make it bigger, but not too big.
- [ ] **Tell your friend:** at the largest accessibility text size, the tabs and the scan button get very tall, and the scan label is cut off ("Scan a medicin…").
- [ ] **Build on an Intel Mac with Xcode 26.** So far only Xcode 27 has been tested.
- [ ] **Test on the real iPad:** the camera with the printed fake envelopes, VoiceOver, Apple Reminders alerts.
- [ ] **Impact numbers for the pitch:** test with a real grandparent using `ai/prompts/10-user-test.md`, then put the numbers in the README.
- [ ] Pitch deck PDF, demo recording, zip the project for staff (`ai/prompts/06-pre-demo-check.md`, `07-pitch-prep.md`).

## 5. How to use AI on this project

- **New Claude chat?** Start with: *"Read ai/project-status.md first."* `AGENTS.md` and `DESIGN.md` load on their own.
- **Skills** in `.claude/skills/` (Claude Code uses them automatically):
  - `jenny-design-review`: say *"use jenny-design-review on the home screen"* to get screenshots, scores and a list of fixes.
  - `ui-ux-pro-max`: UX and SwiftUI lookups only. `DESIGN.md` always wins.
  - `swiftui-pro`, `ios-design-guidelines`, `ipados-design-guidelines`: SwiftUI and Apple design rules.
- **Copy-paste prompts** for other AI tools: `ai/prompts/01–11`.
- **How we work:**
  1. Branch from `main`.
  2. Open a pull request.
  3. Before merging, check that `main` hasn't changed, look at the diff, and build.
  4. Then merge.

  Never push straight to `main` (Claude's safety check blocks it anyway).

## 6. Gotchas we hit today

- **Building with Xcode 27 changes two files on its own:** `project.pbxproj` and `SuperJerry/InfoPlist.xcstrings`. Don't commit those. Undo them with:
  ```bash
  git checkout -- SuperJerry.xcodeproj/project.pbxproj SuperJerry/InfoPlist.xcstrings
  ```
- **Your friend and you edit the same screens.** Pull before you start (`git pull`). If a PR says "conflicting", keep *their* version of the screens they're working on.
- **The bundle ID changes with the signing team** (we saw `Jenny.JennyNagig` and `Jenny.JennyNagig6767`). For simulator commands, read it from the built app instead of guessing.
- **Sample data in a simulator** (made-up medicines only, PDPA):
  ```bash
  python3 .claude/skills/jenny-design-review/seed_sample_medicines.py <simulator-id> <bundle-id>
  ```
- **The Intel Macs' simulator** has no Apple Intelligence and no camera. Test those on the iPad.
