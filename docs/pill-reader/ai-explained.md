# ยาใจ: the AI parts, explained simply

Team Super Jerry · YIDH26 · 2026-10-17
The full plan (schedule, code, pitch, Q&A) is in [plan.md](plan.md). This page explains **what we use and why**, in plain words.

---

## 1. What the app does
Point the iPad at a Thai medicine envelope (ซองยา). The app shows **big text** (what the medicine is, how many, and when), **reads it aloud in Thai**,
and adds it to **today's medicine list**.

## 2. Where we are right now

| Part | Status |
|---|---|
| Plan (idea, facts, schedule, pitch, Q&A) | ✅ Done ([plan.md](plan.md)) |
| Spike test (a quick experiment: "what works on the iPad?") | ✅ Done in the simulator (code kept on branch `feature/pill-reader`, removed from the app) |
| **PillInfo**: the container for one medicine's info | ✅ Done |
| **Thai rules (LabelParser)**: understands the label text | ✅ Done, **5/5** test labels correct |
| Camera → read label → big card → read aloud → save, plus today's ticks and reminders | 🟡 **Built (the Jenny app)**. Not yet tested in Xcode or on the iPad |
| AI cluster helper | ❌ Not set up yet |
| Spike test on the **real iPad** | ❌ Not done yet |
| Build on an **Intel Mac (Xcode 26)** | ❌ Not checked yet |

**Update:** the pill reader is now the **Jenny** app (red and white). The camera is the main feature: the home screen is a big
"ถ่ายรูปซองยา" button. The spike test was removed (its results are below). Next: build it in Xcode and try it on the real iPad.

---

## 3. The 3 AI options from the hackathon, simply

### Option 1: Foundation Models 🧠 = the "brain"
- **One** small chatbot-style AI made by Apple, living **inside** the iPad. Like a mini ChatGPT that works without internet.
- Good at short text jobs: summarizing, sorting, filling in a form from text.
- **Not** made for medicine labels, and **not** made for Thai.

### Option 2: Core ML + Vision 👁️ = the "eyes"
These are two different things:

| | What it is | Do we train it? |
|---|---|---|
| **Core ML** | The "engine" that runs AI models on the iPad | You *can* train your own model (with Create ML) and put it in the app |
| **Vision** | Apple's **ready-made, already trained** AI that sees things in photos: text, faces, objects | ❌ No. Apple already trained it. We just use it |
| **VisionKit** | **Ready-made camera screens** built on top of Vision (live text scanner, document scanner) | ❌ No |

Vision is the engine, and VisionKit is a ready-made car built around that engine. **We use plain Vision** (take a photo → read the text).

### Option 3: AI cluster 🖥️ = sending to a server
- We send text or a photo to the **organizers' Mac computers at the event**, and they send an answer back.
- Their AI models are **bigger and understand Thai well** (including a Thai OCR model and a medical model).
- It **only works on event Wi-Fi**.

### Vision vs Foundation Models

| | **Vision** 👁️ | **Foundation Models** 🧠 |
|---|---|---|
| Job | **Sees** things in pictures | **Understands and writes** language |
| You give it | 📷 a photo | 📝 text |
| It gives back | the text in the photo | answers, summaries, filled-in info |
| Trained by | Apple | Apple |
| Runs on | the iPad (works offline) | the iPad (works offline) |
| Thai? | ✅ **Reads Thai** | ❌ **Doesn't understand Thai** |

---

## 4. What "Thai rules" means
**Normal code we wrote ourselves.** It isn't AI and doesn't learn. It works like **Ctrl+F (search)**: it looks for special Thai words on the label and fills in the values the app needs.

Example label:
```
Metformin 500 mg
รับประทานครั้งละ 1 เม็ด วันละ 2 ครั้ง
หลังอาหาร เช้า-เย็น
```
("Take 1 tablet each time, 2 times a day, after meals, morning and evening.")

| The rule looks for… | Found | So the app knows… |
|---|---|---|
| An English word + number + "mg" | "Metformin 500 mg" | 💊 name = Metformin, strength = 500 mg |
| "ครั้งละ ___ เม็ด" (___ tablets each time) | "ครั้งละ 1 เม็ด" | 1 tablet each time |
| "เช้า" (morning) | ✅ | ☀️ morning |
| "เย็น" (evening) | ✅ | 🌆 evening |
| "หลังอาหาร" (after meals) | ✅ | 🍚 after meals |

These values go into **PillInfo**. The result card and the voice then use them.

**Why it works:** Thai hospital labels almost always use the same phrases (ครั้งละ… วันละ… หลังอาหาร…), so simple searching is enough.
It's fast, works offline, and gives the same answer every time.

---

## 5. How the plan changed after the test

**Before (the original idea):**
```
📷 Photo → Vision reads the text → Foundation Models understands the Thai → 💊 card
```

**Now (Plan B):**
```
📷 Photo → Vision reads the text → Thai rules find the special words → 💊 card + 🔊 voice
              (Apple's AI)               (our own code)
```
Later: the **AI cluster** can help with messy labels the rules can't handle (event Wi-Fi only).

The Thai rules were always in the plan as the **backup**. The test showed Foundation Models can't do Thai, so the backup became the **main brain**.

---

## 6. Spike test results (iPad Pro 11" simulator, iOS 27.0, 2026-10-17)

| # | Question | Answer |
|---|---|---|
| 1 | Can the iPad read Thai text from a photo (Vision)? | ✅ Yes |
| 2 | Is Apple's on-device AI turned on? | ✅ Yes |
| 3 | Does Apple's on-device AI understand Thai? | ❌ **No.** Thai is not on its language list, even in iOS 27 |
| 4 | Will it read a medicine label? | ❌ No. It refused: **"May contain sensitive content"** |
| 5 | Is there a Thai voice to read aloud? | ✅ Yes, **Kanya (th-TH)** |
| 6 | Do our Thai rules work? | ✅ **5 out of 5** test labels correct |
| 7 | Real photo of a printed envelope | Not tried yet (needs a photo) |
| 8 | Apple's cloud AI (Private Cloud Compute)? | ⚠️ Available, but needs a special permission (the entitlement `com.apple.developer.private-cloud-compute`) in project settings |

⚠️ These are **simulator** results. Run the test on the **real iPad** to confirm.

### About the "sensitive content" block (test 4)
- **We did NOT get past it.** We only found the problem.
- Apple's AI has a **guardrail** (safety filter). It probably saw medicine/health text and got cautious. We're not 100% sure: it might also have been confused by Thai, which it doesn't understand.
- **Why it doesn't stop us:** the Thai rules read labels without Apple's AI.
- Other options:
  1. Try Apple's looser safety setting (`.permissiveContentTransformations`). **Not tried yet.** Even if it works, Apple's AI still doesn't understand Thai.
  2. Use the **AI cluster** for hard cases. **Not set up yet.** It understands Thai well, but needs event Wi-Fi.

---

## 7. Two bugs we found (and fixed) during the test
1. **The app froze.** Asking iOS for its list of voices (`AVSpeechSynthesisVoice.speechVoices()`) locks up the app if it runs on the main thread.
   Fix: ask from a background task (`Task.detached { … }`).
2. **The app crashed.** Calling Apple's cloud AI (Private Cloud Compute) without its special permission crashes the app instead of showing an error.
   Fix: the test now only checks whether it's available. Adding the permission is a project-settings change, so the team must approve it first, and it may not work with a free Personal Team.

---

## 7b. Update (Day 2): names and units
Testing on real envelopes found two problems: traditional medicines like **MAWANG (มะแว้ง)** were missed (the rules
needed "Name + mg"), and **eye drops showed เม็ด instead of หยด**. The fix, all on the device:
1. **A medicine name list** (`medicine-names.json`, 486 medicines incl. Thai herbal medicines and eye drops), matched against the
   label with spelling tolerance, and given to Vision as custom words. It can grow from the official **TMT** list (see README).
2. **Dosage-form words:** หยอดตา/หยอดหู → หยด, สูด/พ่น → พัฟ, ทาบาง ๆ/ครีม → no count, ช้อนชา, ซอง, อม, เหน็บ, plus "1-2" ranges,
   "%" strengths, which eye (ขวา/ซ้าย/ทั้ง 2 ข้าง), "วันละ 3-4 ครั้ง" and "ทุก 6 ชั่วโมง".
3. **Honesty on screen:** guessed names, units, or times show an orange "โปรดตรวจสอบ" (please check).
4. **Learning:** names the user saved before are recognised next time.

Your Thai rules (LabelParser) are unchanged and still pass 5/5; the new `LabelReader` runs them first and fills in the gaps.

## 8. Words to know

| Word | Meaning |
|---|---|
| **Spike test** | A quick experiment *before* building, to find out what works. Like testing whether ice holds before walking on it |
| **Branch** | A separate copy of the code, so `main` stays safe |
| **Commit** | Saving a snapshot of the work |
| **Push** | Uploading commits to GitHub so teammates can download them |
| **On-device** | Runs on the iPad itself: private, offline, free |
| **Guardrail** | A safety filter inside an AI that refuses some content |
| **Entitlement** | A special permission an app must have to use some Apple features |
| **OCR** | Turning a photo of text into real text (what Vision does) |
| **PillInfo** | Our container for one medicine's info |
| **LabelParser** | Our Thai rules code |

---

## 9. What's next
1. **Run the spike test on the real iPad**: switch to `feature/pill-reader`, choose the iPad in Xcode, press ⌘R, tap **Run spike test**, then tap **Share report**.
2. **Build on an Intel Mac** (Xcode 26) to make sure it works there too.
3. **Build the real app:** scan → big card → read aloud → today's list (steps 2–6 in [plan.md](plan.md) section 9).
4. Later: add the **AI cluster** helper for messy labels.
