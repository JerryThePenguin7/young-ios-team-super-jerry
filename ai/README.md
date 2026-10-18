# ai/ — the team's AI folder

Everything our AI tools (and we) need to stay on the same page.

| File | What it's for |
|---|---|
| [what-we-are-building.md](what-we-are-building.md) | **Start here.** The goal, the 3 AI options (a menu, not a checklist), judging, team rules, and every source |
| [context/competition-brief.md](context/competition-brief.md) | Full rules, schedule, team kit, AI cluster models and setup |
| [context/kickoff-transcript-th.txt](context/kickoff-transcript-th.txt) | Raw Thai transcript of the kickoff talk (noisy) |
| [prompts/](prompts/) | Copy-paste prompts for Xcode agents, OpenCode, Claude, or ChatGPT |

Agents also read [`../AGENTS.md`](../AGENTS.md) automatically (Claude reads it through `CLAUDE.md`).
That file holds the hard rules: iOS 26 target, Xcode 26 + 27, no secrets, plan first.

## How to use the prompts

1. **Commit first** (`⌘⌥C` in Xcode) so you can undo anything the agent does.
2. Open a prompt in `prompts/`, copy it, and fill in the `[brackets]`.
3. Read the agent's **plan** before you approve it.
4. Review the diff, run it on the iPad, then push your branch.

| Prompt | Use it when |
|---|---|
| [01-find-the-problem.md](prompts/01-find-the-problem.md) | Day 1: brainstorm and pick a real problem |
| [02-pick-the-ai.md](prompts/02-pick-the-ai.md) | Deciding which AI option fits the problem |
| [03-new-feature.md](prompts/03-new-feature.md) | Building any feature (handbook GOAL/CONTEXT/CONSTRAINTS template) |
| [04-fix-a-bug.md](prompts/04-fix-a-bug.md) | Something crashes or doesn't work |
| [05-add-ai-cluster.md](prompts/05-add-ai-cluster.md) | Connecting to the event's AI cluster with an on-device fallback |
| [06-pre-demo-check.md](prompts/06-pre-demo-check.md) | Before submitting or demoing |
| [07-pitch-prep.md](prompts/07-pitch-prep.md) | Writing the 5-min pitch and preparing for judge questions |
| [08-design-review.md](prompts/08-design-review.md) | Getting an honest critique of a screen (scores, personas, P0–P3 fixes) |
| [09-accessibility-check.md](prompts/09-accessibility-check.md) | Checking Apple's Accessibility Nutrition Labels, plus a hands-on iPad checklist |
| [10-user-test.md](prompts/10-user-test.md) | Testing with a real older person and turning it into impact numbers |
| [11-design-a-screen.md](prompts/11-design-a-screen.md) | Adding or redesigning a screen in Jenny's Health style |

### Claude Code skills (in `.claude/skills/`)

Claude Code picks these up automatically. Other tools can read the same files.

| Skill | What it does |
|---|---|
| `jenny-design-review` | **Ours.** Builds the app, takes simulator screenshots (light, dark, biggest text, iPhone + iPad), scores 6 areas, tests with our personas. Say "use jenny-design-review on …" |
| `swiftui-pro` | Writes and reviews modern SwiftUI (Paul Hudson, MIT) |
| `ios-design-guidelines`, `ipados-design-guidelines` | Apple HIG rules with SwiftUI examples (platform-design-skills, MIT) |

Why we chose these, and what we left out: [docs/design/research.md](../docs/design/research.md) section 5.

Add new prompts when one works well, so the whole team can reuse it.
