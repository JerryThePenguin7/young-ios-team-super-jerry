# Envelope test: how accurate is Jenny's label reader?

No public dataset of Thai medicine envelopes (ซองยา) with correct answers exists
(see `reports/Thai medicine label test datasets.md`). So this makes its own:
fake envelopes where we already know the right answer, then checks what Jenny reads.

Everything is made up (fake hospital, fake patient, fake HN), so there is no real health data (PDPA).

## Run it (on a Mac)

```bash
tools/envelope-test/run.sh          # 300 envelopes, seed 1
tools/envelope-test/run.sh 1000 7   # 1000 envelopes, seed 7
```

It takes about 40 seconds for 300. The same seed always makes the same envelopes, so you can
compare scores before and after you change the reader.

## What it does

1. **`MakeEnvelopes`** draws each envelope: a random medicine from 50 common ones (tablets, capsules,
   syrups, eye drops, creams, an inhaler, ORS), real Thai label wording, 6 Thai fonts, sometimes Thai digits (๑๒๓).
   Then it makes it look like a phone photo: tilt, blur, shadow, grain, faded print, smaller size
   (easy / medium / hard). Each `0001.jpg` gets a `0001.json` with the printed lines and the right answer.
2. **`ScoreEnvelopes`** is built together with Jenny's real reader files (`LabelReader`, `LabelParser`,
   `MedicineNames`…), reads each photo with Vision using the same settings as `TextReader.swift`,
   and compares every field with the answer.

Each envelope is scored twice:

| Column | What it tells you |
|---|---|
| **Perfect text** | The reader gets the exact printed lines. Wrong here = **a rule in `LabelReader`/`LabelParser` needs fixing.** |
| **Photo (OCR)** | The reader gets what Vision read from the photo. Wrong only here = **the camera/OCR misread it.** |

Results print in the terminal. Every mistake, with what was expected, what Jenny got, and what Vision read,
is in `tools/envelope-test/out/report.md`.

## Notes

- Nothing here is part of the app, and no packages are added. It only needs Xcode's `swiftc`.
- Thai OCR needs Vision's `.accurate` level. If a Mac's Vision can't read Thai, the scorer says so and stops.
- Fake envelopes are tidier than real ones. For pitch numbers, also print 30–50 of them, photograph them
  with the iPad, and score those photos with the same answer files.
