# Super Jerry 🐭

Team **Super Jerry**'s iOS app for **YIDH26, the Young iOS Developer Hackathon 2026** at Srinakharinwirot University (SWU), October 2026.
The theme is AI that runs on Apple devices.

👉 **Read [ai/what-we-are-building.md](ai/what-we-are-building.md) first.** It covers what we're building, the AI options, judging, and how we work.

- Full rules and schedule: [ai/context/competition-brief.md](ai/context/competition-brief.md)
- Rules every AI coding agent follows: [AGENTS.md](AGENTS.md)
- What's done and what's left (also the first read for a new AI chat): [ai/project-status.md](ai/project-status.md)
- How Jenny looks, and why: [DESIGN.md](DESIGN.md)
- Copy-paste prompts for the team: [ai/prompts/](ai/prompts/)

## The idea: Jenny 💊

> Take a photo of a medicine envelope, and Jenny reads it out loud in big, clear Thai, then remembers it for you.

- **Who has the problem:** older people (e.g. our grandparents) who take several medicines every day.
- **The problem:** the labels are tiny, the drug names are in English, and every envelope looks the same,
  so they take the wrong pill, at the wrong time, or forget it.
- **Our solution (one core feature): the camera.** Open Jenny and tap the big **ถ่ายรูปซองยา** button.
  Take a photo of a Thai medicine envelope, and Jenny shows **huge text** (what, how many, when) and **reads it aloud in Thai**.
  Tap **Save**, and the medicine is kept with its label photo, sorted into a group (heart, diabetes, eyes…).
  Jenny puts it in **Apple Reminders**, which reminds you at each pill time.
- **AI we use and why:** Apple's **Vision** reads the label text on the device (a neural network on the Neural Engine),
  then our **Thai label rules** understand it ("ครั้งละ 1 เม็ด วันละ 2 ครั้ง หลังอาหาร"). It all works offline, and health data never leaves the device.
  We tested Apple's on-device language model (Foundation Models): it doesn't support Thai and it blocked medicine text as
  "sensitive content", so the rules do the understanding. See [docs/pill-reader/ai-explained.md](docs/pill-reader/ai-explained.md).
  Names come from a **medicine name list** in the app (486 medicines: common hospital medicines, Thai herbal medicines like
  มะแว้ง/MAWANG and ฟ้าทะลายโจร, eye drops, creams, inhalers). Vision gets the list as custom words, and Jenny matches it
  against the label even with OCR spelling mistakes. Grow it from the official TMT list: see "Medicine names" below.
- **Impact (numbers!):** _TODO: run the impact test in [docs/pill-reader/plan.md](docs/pill-reader/plan.md) section 3.3 and put the numbers here._

The full plan (facts, pitch script, judge Q&A) is in [docs/pill-reader/plan.md](docs/pill-reader/plan.md). It calls the app ยาใจ; the app is named Jenny.

### How to use it (on the iPad)
0. **First time:** a short tutorial shows how Jenny works. Pick **ภาษาไทย** or **English** on its first page (change it later in Settings).
   **Settings ▸ ขนาดตัวอักษร (Text size)** makes all of Jenny's text bigger, from Normal up to Largest.
   The whole app switches: screens, the read-aloud voice, and the Apple Reminders text. The two languages are never mixed on one screen.
   The button at the top left switches between a light (white) and a dark (black) look.
1. **Scan a label:** tap the red **Scan a medicine label** button at the bottom, then **Take photo** (allow the camera the first time)
   or **Choose from Photos**.
   Fill the photo with the label, in good light.
2. **Result:** Jenny shows and reads aloud the label's directions **word for word** (never shortened), plus the expiry date
   if the label has one ("EXP" / "หมดอายุ"). Tap **Read aloud** to hear it again. Fix anything with **Edit**, or **Retake**.
   Then **Save medicine**. If you already saved the same medicine, Jenny warns you first (**Add anyway** or **Cancel**).
3. **Home** looks like the Health app's Medications page. Two big buttons at the top switch between **Log** and **Your Medications**.
   - **Log ▸ Today, October 18** and a week strip. Each day's circle fills up green as you take that day's doses. Tap a day to see its log.
     Tap the date itself for a **calendar by month** to look further back.
   - **Log ▸ by meal:** one card per meal (Breakfast, Lunch, Dinner, Bedtime) at the times you eat (set in the tutorial or Settings).
     Before-meal medicines sit above the meal (30 minutes before), after-meal ones below it (15 minutes after).
     **Tick the box** next to a medicine when you've taken it (ticking long before its time asks "Did you really take it?" first). Press and hold to skip it; **…** opens the full sheet
     (Log All as Taken, Skipped), where tapping a medicine's name opens it in Your Medications.
     A card says **Time to take** when it's due and **Late** if it was missed.
   - **When needed (ยาเมื่อมีอาการ)**, at the top (move it below the meals with its button): medicines with no set time, like Paracetamol. Tap **Taken** when you take one. Jenny shows
     how many times today and, from the label ("ห่างกันอย่างน้อย 6 ชม."), when the next dose is allowed. Too soon? It asks first.
   - **Taken:** what you took (✓) or skipped, and how long ago. Tap a medicine to undo it.
   - **Your Medications ▸** each medicine with its label photo, kind and strength, and schedule, in groups (Heart,
     Diabetes, Eyes & ears…). Tap a group's header to fold it. The speaker next to a name reads it aloud.
     **Edit** lets you delete medicines.
   - **How many are left:** each medicine card shows the count. Tap a medicine, then **Add how many** in "How many are left". Each time you log **Taken** (the green button), Jenny takes
     one dose off by itself, and shows about how many days are left. Set **when to warn** for each
     medicine (e.g. at 10 or 5 left); until you do, "Running low" shows at about a week's worth.
4. **Apple Reminders:** tap **Remind me in Reminders** (or Settings), and allow Full Access. Jenny makes a list
   called **Jenny Medicines** (ยา Jenny in Thai) with a repeating reminder per medicine at its time around each meal (e.g. 06:30 before breakfast, 07:15 after),
   each with an alert. Tick them off in Reminders (they also show on an Apple Watch). Jenny sends no notifications of its own.
5. **Tap a medicine** to see the big photo, how and when to take it, today's ticks, the scanned text, edit it, or delete it.

No camera (e.g. the simulator)? The big button picks a photo from the library instead. To test, print the 5 fake envelopes
in [docs/pill-reader/plan.md](docs/pill-reader/plan.md) section 10.1 (made-up data only, PDPA).

### Medicine names (and how to add more)
The list is [SuperJerry/Understanding/medicine-names.json](SuperJerry/Understanding/medicine-names.json). Each medicine has a
`name`, other spellings in `aliases` (Thai or English), a short friendly Thai description in `thai` (general categories only),
and an optional `form` (`eyeDrops`, `topical`, `inhaler`… which sets หยด, ทา, พัฟ).
- **Add one by hand:** copy an entry in the JSON, change it, build again.
- **Add thousands from TMT** (Thai Medicines Terminology, the official Thai drug list): make a free account at
  [this.or.th](https://this.or.th/service/tmt/download/), download the latest release zip, unzip it, then run
  `python3 tools/tmt_to_medicine_names.py ~/Downloads/TMTRF…` and build again. Check TMT's license before sharing the data.
- **Jenny also learns:** a name you saved (or corrected) once is recognised the next time you scan that envelope.

### Groups and Core AI
Every medicine in the name list has a group, and unknown ones are grouped by how they're used (eye drops → ตาและหู, creams → ผิวหนัง).
Only medicines Jenny still can't place go to an on-device AI: **Core AI** (iOS 27) if it's set up, otherwise Apple Intelligence
for English names, otherwise "อื่น ๆ" (you can change the group in Edit). The result screen says who grouped it.

**Turning on Core AI (optional, on the M-chip Mac with Xcode 27, as in handbook workshop 3):**
1. File ▸ Add Package Dependencies… → `https://github.com/apple/coreai-models.git` → product **CoreAILM** → SuperJerry target.
   (This is a new package, so the team agrees first. Intel Macs on Xcode 26 still build, because the code is behind `#if canImport`.)
2. Get the model folder `qwen3_0_6b_mixed_4bit_8bit_static` (~430 MB) from a TA. Drag the **whole folder** into Xcode as a
   **folder reference** (blue folder), target SuperJerry.
3. Signing & Capabilities ▸ **+ Capability** ▸ **Increased Memory Limit**. (Untested with a free Personal Team; ask a TA if it fails.)
4. Run on the iPad (iOS 27). The first grouping is slow while Core AI prepares the model. If the model isn't there, Jenny just skips it.

## Team

| Name | Role |
|---|---|
| Jerry | |
| | |
| | |

## Getting started

Requirements: **Xcode 26 or 27**. The deployment target is iOS 26, so it works on the event's Intel Macs too.
Test on the **team iPad**: the camera, sensors, and Apple Intelligence don't work in the Intel Macs' simulator.
If Xcode 27 asks to "update to recommended settings / project format," click **No**, or teammates on Xcode 26 can't open the project.

> The organizers also give us an official team repo on the Team card. This repo is our own copy for sharing.
> Before final submission, push the same code to the official repo (or follow whatever the staff say).

```bash
git clone <this repo url>
cd young-ios-team-super-jerry
open SuperJerry.xcodeproj
```

Then pick a simulator (e.g. iPhone 17) and press **⌘R**.

> To run on a real device, set your own **Team** under *Signing & Capabilities*.
> Don't commit that change; personal signing settings differ per person.

## Working together

- Pull before you start: `git pull`
- Work on a branch per feature: `git switch -c feature/camera-scan`
- Commit small and often, then open a Pull Request into `main`.
- **Don't edit the same SwiftUI file as a teammate at the same time.** Merge conflicts in `project.pbxproj` are painful.
  Ping the group chat before adding new files to the Xcode project.

## Secrets

The AI-cluster API key from the Team card goes in `SuperJerry/AICluster.swift`. That file is **gitignored**, so each teammate creates it locally:

```swift
import HackathonAI

// Address: from staff / Team card (the handbook says TBC). Key: from the Team card.
let aiCluster = HackathonAI(baseURL: "http://[address from staff]", apiKey: "team-XX-xxxx")
```

Then call it with `try await aiCluster.respond(to: "...")` (model `.chat` by default).
See [ai/context/competition-brief.md](ai/context/competition-brief.md#ai-cluster-hackathonai-package) for the models and the Info.plist settings.

## Submission checklist

- [ ] App builds and runs on a clean clone
- [ ] Core feature works offline / live with no crashes
- [ ] Xcode project zipped and sent to staff (early!)
- [ ] Pitch deck exported as **PDF** (no animations, no unauthorized logos)
- [ ] Backup screen recording of the demo
- [ ] Everyone on the team can explain the problem, the AI choice, and the demo
