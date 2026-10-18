# Synthetic Thai medicine-envelope (ซองยา) test set: generation sources, tools and evaluation

Research date: 18 October 2026. Every claim has a source link. Anything I could not confirm is marked **UNVERIFIED** or listed under Gaps. Several facts were checked directly on the team's M-chip Mac (macOS 27.0.1, Xcode 27.0), and those are marked "verified locally".

## 1. Drug name / strength sources (NLEM, TMT, Thai FDA, common OPD drugs). Which are downloadable as CSV?

### Takeaway
The best machine-readable source is **TMT (Thai Medicines Terminology)** from THIS/สมสท. It is free with registration, ships as a ZIP of Excel `.xls` files (not CSV), and its "Fully Specified Name" strings such as `zolpidem tartrate 10 mg tablet, 1 tablet (GPU)` already contain the generic name, strength and dosage form, so they map directly onto the parser's fields. The Thai FDA product-search dataset on data.go.th is an XML web service with no stated license. I could not find a CSV or Excel download of the 2568 National List of Essential Medicines (NLEM).

### Cited Findings
- The HSRI open-data portal lists the dataset "บัญชีข้อมูลยาและรหัสยามาตรฐานไทย (TMT)". The publisher is สมสท. (Thai Health Information Standards Development Center, part of HSRI). The license is "Open Data Common" and registration is required to download. The record was last updated 20 Aug 2569 (2026). Its resources are a release-note PDF, "TMT โดยสังเขป V3" (PDF), and a "TMT Release File Download" (ZIP) that links out to this.or.th — [HSRI open data: TMT](https://opendata.hsri.or.th/dataset/e85ad683-f5c5-4831-983a-1e6d077efe16)
- The release note for TMTRF20250804 (4 Aug 2025) says release files are downloaded from `https://www.this.or.th/service/tmt/download/`. A web browser for searching drugs is at `https://tmt.this.or.th/TMTBrowser.dll/...`. The contact is tmt@this.or.th — [TMT release note PDF](https://opendata.hsri.or.th/dataset/e85ad683-f5c5-4831-983a-1e6d077efe16/resource/5d91d542-1796-4c72-bd4f-ea6afa0d3309/download/releasenote_tmtrf20250804.pdf) (text extracted locally with PDFKit)
- The ZIP layout is described in the same release note:
  - `TMTRF20250804_SNAPSHOT.xls`: 33,626 active Trade Product Use (TPU) items, with columns TMTID, FSN, MANUFACTURER, CHANGEDATE
  - `_DELTA.xls`, `_FULL.xls`, and `_SNAPSHOT_GP_F.xls`: 1,821 hospital-made products
  - A Concept folder with `SUBS`, `VTM`, `GP`, `GPU`, `TP`, `TPU`, `GPP` and `TPP` `.xls` files, for example GPU with 10,760 items
  - A Relationship folder with files such as `VTMtoGP` and `GPtoGPU`, plus `MasterTMT_*.xls`
  - Sample FSNs: "zolpidem tartrate 10 mg tablet, 1 tablet (GPU)", "(loratadine 10 mg) tablet (TP)", "(tetracycline 250 mg) coated tablet, 1 tablet (TPU)"
  - Source: [TMT release note PDF](https://opendata.hsri.or.th/dataset/e85ad683-f5c5-4831-983a-1e6d077efe16/resource/5d91d542-1796-4c72-bd4f-ea6afa0d3309/download/releasenote_tmtrf20250804.pdf)
- A 2018 THIS-related post said updates came out every two weeks. That post is old, so check the current schedule — [gotoknow](https://www.gotoknow.org/posts/657800)
- A third-party Hugging Face dataset (`icdevelop/thai-pharma-kb`) has a `tmt_lookup.json` derived from TMT. It is gated (you must share contact info), AI-assisted, and says it is not pharmacist-reviewed. It is not official — [Hugging Face](https://huggingface.co/datasets/icdevelop/thai-pharma-kb)
- The Thai FDA dataset "[Web Service] สืบค้นข้อมูลผลิตภัณฑ์ยา" on data.go.th is described as follows:
  - Format: XML. Source: privus.fda.moph.go.th
  - Update frequency: daily
  - License: "License not specified"
  - Fields: not listed on the page, and several metadata fields show unrendered placeholders
  - Source: [data.go.th / GDCC](https://gdcc.data.go.th/en/dataset/web-service-drug-reg)
- The Thai FDA catalog (catalog.fda.moph.go.th) has XLS/XLSX datasets on drug *premises* licenses and on per-province product counts. These are not product names or strengths — [FDA catalog: drug location](https://catalog.fda.moph.go.th/en/dataset/drug-location); [FDA catalog: summary-pre2](https://catalog.fda.moph.go.th/en/dataset/summary-pre2/resource/ac93ce05-ae39-4cca-b29f-7202296ff96b)
- A list of common chronic-disease outpatient drugs used in RDU auxiliary-label work: allopurinol, amlodipine, enalapril, glipizide, metformin and simvastatin. Manorom Hospital developed extended labels for these six — [thaidj.org SMNJ 8006](https://thaidj.org/index.php/smnj/article/view/8006)
- The Thai FDA NDI RDU page links a document "แนวทางการใช้คำทับศัพท์ภาษาไทย ชื่อยาและรูปแบบ" (a Thai transliteration guide for drug names and dosage forms, following Royal Institute rules) as a Google Drive file. This is useful for generating the Thai generic-name line (for example "พาราเซตามอล") — [NDI drug_use/67](https://ndi.fda.moph.go.th/drug_use/detail/67)

### Inferences
- For generation, use TMT **GP/GPU** FSNs, parsed with a regex of the form `<generic> <number> <unit> <form>`, as the master drug list. Pick a subset of about 100–300 common OPD generics (antihypertensives, antidiabetics, statins, analgesics, antihistamines, antibiotics, PPIs) so the test set looks like real outpatient envelopes rather than all 10k+ products.
- Convert the `.xls` files to CSV with pandas or LibreOffice. The registration step means the team should cache a derived CSV of drug names, which are public terminology rather than patient data, and record the TMT release ID in the repo.
- The Thai transliteration guide is the right source for the Thai generic-name line that the MOPH standard label requires (see section 2).

### Gaps
- I did not find a direct CSV, Excel or open-data download of the **NLEM 2568 (บัญชียาหลักแห่งชาติ)**. Searches returned only unrelated NCI templates. The NLEM is usually published as a Royal Gazette/PDF announcement (**UNVERIFIED**).
- TMT redistribution terms: the portal says "Open Data Common", but I could not read the exact terms. Check before committing raw TMT files to a public repo.
- The field list of the FDA XML web service was not visible.

## 2. Standard Thai label wording (Thai FDA / Pharmacy Council / RDU) and auxiliary labels

### Takeaway
A MOPH-hosted document, "มาตรฐานฉลากยาสำหรับสถานพยาบาลเอกชน", lists 7 required elements and includes a full sample label. This is the best template found for the synthetic layout. RDU-programme auxiliary labels (ฉลากยาเสริม) exist and are studied in the literature, but I found no single downloadable official phrase list.

### Cited Findings
- "มาตรฐานฉลากยาสำหรับสถานพยาบาลเอกชน" is a 1-page PDF hosted on mrd.hss.moph.go.th, created July 2019 and set in TH SarabunIT๙. It requires the following on a standard label:
  1. Facility name, phone and/or address
  2. Patient name, HN (or other ID) and dispense date
  3. Drug name (generic and/or trade name in Thai and/or English, *always including the Thai generic name*), dosage form, strength, and quantity dispensed
  4. Directions for use (วิธีใช้ยา)
  5. Indication (ข้อบ่งใช้/สรรพคุณ)
  6. Warnings, precautions and/or contraindications
  7. Expiry date
  - Source: [MOPH label standard PDF](https://mrd.hss.moph.go.th/mrd1_hss/wp-content/uploads/2019/07/%e0%b8%a1%e0%b8%b2%e0%b8%95%e0%b8%a3%e0%b8%90%e0%b8%b2%e0%b8%99%e0%b8%89%e0%b8%a5%e0%b8%b2%e0%b8%81%e0%b8%a2%e0%b8%b2%e0%b8%aa%e0%b8%b3%e0%b8%ab%e0%b8%a3%e0%b8%b1%e0%b8%9a%e0%b8%aa%e0%b8%96%e0%b8%b2%e0%b8%99%e0%b8%9e%e0%b8%a2%e0%b8%b2%e0%b8%9a%e0%b8%b2%e0%b8%a5%e0%b9%80%e0%b8%ad%e0%b8%81%e0%b8%8a%e0%b8%99.pdf) (text extracted locally with PDFKit)
- The same PDF has a sample label, line by line (already synthetic):
  - "โรงพยาบาลส่งเสริมการใช้ยาอย่างสมเหตุผล โทร. 09 999 9999"
  - "นาย HN 12345/62 13/06/2562"
  - "CETAMOL (PARACETAMOL) 500 MG เม็ดกลมขาว 20"
  - "รับประทานครั้งละ 1 เม็ด"
  - "ห่างกันทุก 6 ชั่วโมง เมื่อมีอาการ"
  - "ใช้ลดไข้ แก้ปวด วันหมดอายุ 30/06/2564"
  - "ชื่อสามัญ พาราเซตามอล 500 มิลลิกรัม"
  - A warning not to use for more than 5 days or more than 8 tablets a day because of liver toxicity
  - The sample uses Buddhist-era dates (2562/2564), a TRADE (GENERIC) name in capitals, and a pill description ("เม็ดกลมขาว").
  - Source: [MOPH label standard PDF](https://mrd.hss.moph.go.th/mrd1_hss/wp-content/uploads/2019/07/%e0%b8%a1%e0%b8%b2%e0%b8%95%e0%b8%a3%e0%b8%90%e0%b8%b2%e0%b8%99%e0%b8%89%e0%b8%a5%e0%b8%b2%e0%b8%81%e0%b8%a2%e0%b8%b2%e0%b8%aa%e0%b8%b3%e0%b8%ab%e0%b8%a3%e0%b8%b1%e0%b8%9a%e0%b8%aa%e0%b8%96%e0%b8%b2%e0%b8%99%e0%b8%9e%e0%b8%a2%e0%b8%b2%e0%b8%9a%e0%b8%b2%e0%b8%a5%e0%b9%80%e0%b8%ad%e0%b8%81%e0%b8%8a%e0%b8%99.pdf)
- Mandatory warning texts for certain drugs are set by a series of MOPH announcements, "ยาที่ต้องแจ้งคำเตือนการใช้ยาในฉลากและที่เอกสารกำกับยา" (for example No. 56 and No. 68, B.E. 2562). The search result cited these; I did not open the Gazette text — [Mahidol pharmacy knowledge PDF](https://pharmacy.mahidol.ac.th/knowledge/files/0325.pdf) and search summary
- Auxiliary labels (ฉลากยาเสริม) came out of the RDU programme so that every patient can access label information and learn more about their drugs — [KKU pharmacy article (TJPP)](https://he01.tci-thaijo.org/index.php/TJPP/article/view/169745); [thaiscience SRMJ PDF](https://thaiscience.info/Journals/Article/SRMJ/10994207.pdf)
- Manorom Hospital (Chainat) based its extended labels for 6 chronic drugs on the RDU-hospital prototype labels. None reached the 80% comprehension threshold on the first draft, and some needed 2–3 revisions — [thaidj SMNJ 8006](https://thaidj.org/index.php/smnj/article/view/8006)
- A Nakhon Ratchasima study surveyed 1,000 outpatients on auxiliary labels for 10 commonly prescribed drugs and found positive attitudes. The authors recommend auxiliary labels for all drugs — [thaidj SMNJ 9681](https://thaidj.org/index.php/SMNJ/article/view/9681)
- The RDU Hospital framework "PLEASE" (6 keys) includes a labeling and information component. The Thai FDA NDI page links the RDU Hospital manual (PLEASE) on Google Drive — [NDI drug_use/67](https://ndi.fda.moph.go.th/drug_use/detail/67); [MOPH RDU slides PDF](https://mrd.hss.moph.go.th/mrd1_hss/wp-content/uploads/2020/10/%e0%b9%81%e0%b8%99%e0%b8%a7%e0%b8%97%e0%b8%b2%e0%b8%87-RDU-%e0%b8%9c%e0%b9%88%e0%b8%b2%e0%b8%99%e0%b8%84%e0%b8%a7%e0%b8%b2%e0%b8%a1%e0%b9%80%e0%b8%ab%e0%b9%87%e0%b8%99%e0%b8%8a%e0%b8%ad%e0%b8%9a-%e0%b8%84%e0%b8%81%e0%b8%81-%e0%b8%aa%e0%b8%9e-11-63-10%e0%b8%81%e0%b8%a263.pdf)

### Inferences
- A template grammar for the generator can follow the MOPH sample. Fields are in braces, with options separated by "/":
  - `[รพ.] โทร. [phone]`
  - `[ชื่อ] HN [n/yy] [dd/mm/yyyy พ.ศ.]`
  - `[TRADE] ([GENERIC]) [strength] [UNIT]` + `[ลักษณะยา] [qty]`
  - `รับประทานครั้งละ {n} {เม็ด/แคปซูล/ช้อนชา/ช้อนโต๊ะ/ซอง}`
  - `วันละ {k} ครั้ง {ก่อน/หลัง/พร้อม}อาหาร {เช้า/กลางวัน/เย็น/ก่อนนอน}`, or `ห่างกันทุก {h} ชั่วโมง เมื่อมีอาการ`
  - `ใช้ {indication}` + `วันหมดอายุ`
  - `ชื่อสามัญ {Thai generic} {strength in Thai units}`
  - an optional warning line
  - Patient names and HNs must be fake, which also satisfies the project's PDPA rule.
- Envelopes are often pre-printed with tick boxes (เช้า/กลางวัน/เย็น/ก่อนนอน, ก่อน/หลังอาหาร) and handwritten or stamped quantities. This is an **UNVERIFIED** general observation, not from a cited source. Support two generator modes: fully printed sticker labels and pre-printed tick-box envelopes.
- Auxiliary-warning wording such as "ยานี้อาจทำให้ง่วงซึม" or "รับประทานยานี้ติดต่อกันจนหมด" is widely used, but I found no official source listing these exact strings. Build the warning lexicon from the MOPH mandatory-warning announcements plus hospital examples, and label it as team-authored.

### Gaps
- I found no Pharmacy Council (สภาเภสัชกรรม) document that defines ซองยา layout or a standard phrase list.
- I found no official, downloadable RDU auxiliary-label phrase list. The RDU manual is on Google Drive and was not opened.
- I did not read the MOPH mandatory-warning announcements (No. 56, No. 68 and others) in full.

## 3. Freely licensed Thai fonts

### Takeaway
Use OFL fonts from Google Fonts (Sarabun, Noto Sans/Serif Thai, plus others) for a committed, redistributable generator. TH Sarabun New/PSK from SIPA is what real Thai government and hospital documents use most, but its license is ambiguous across versions, so verify the bundled license file before redistributing it.

### Cited Findings
- **Noto Sans Thai** is under the SIL Open Font License 1.1, "Copyright 2022 The Noto Project Authors" — [notofonts/thai OFL.txt](https://raw.githubusercontent.com/notofonts/thai/main/OFL.txt) (fetched locally)
- **Sarabun** (Google Fonts) is under SIL OFL 1.1, "Copyright 2018 The Sarabun Project Authors (cadsondemak/Sarabun)" — [google/fonts sarabun OFL.txt](https://raw.githubusercontent.com/google/fonts/main/ofl/sarabun/OFL.txt) (fetched locally). Google Fonts says it is free for commercial and non-commercial use — [rightfontapp: Sarabun](https://rightfontapp.com/family/sarabun)
- Older SIPA-era TH Sarabun files (2010–2011, designer Suppakit Chalermlarp) carry GPL v2-or-later notices in TLWG packaging. Some third-party sites call it "free for commercial use" while showing the GPL text — [CTAN fonts-tlwg COPYING](https://tug.ctan.org/fonts/thai/fonts-tlwg/COPYING); [cufonfonts](https://www.cufonfonts.com/font/th-sarabun-new-4)
- The 13 SIPA "national fonts" were announced by Cabinet resolution on 7 September 2010 — [Wikipedia: National Fonts](https://en.wikipedia.org/wiki/National_Fonts)
- Font frequency from 8,000 public Thai PDF pages (693 families observed). The ten most common: Cordia New, Angsana New, TH Sarabun PSK, TH Sarabun New, Browallia New, TH Sarabun IT๙, DB ThaiText X, Cordia UPC, Tahoma, DB FongNam X — [arXiv 2609.03595 (HTML)](https://arxiv.org/html/2609.03595v1)
- The MOPH sample label PDF itself embeds TH SarabunIT๙ (from the PDF metadata via WebFetch) — [MOPH label standard PDF](https://mrd.hss.moph.go.th/mrd1_hss/wp-content/uploads/2019/07/%e0%b8%a1%e0%b8%b2%e0%b8%95%e0%b8%a3%e0%b8%90%e0%b8%b2%e0%b8%99%e0%b8%89%e0%b8%a5%e0%b8%b2%e0%b8%81%e0%b8%a2%e0%b8%b2%e0%b8%aa%e0%b8%b3%e0%b8%ab%e0%b8%a3%e0%b8%b1%e0%b8%9a%e0%b8%aa%e0%b8%96%e0%b8%b2%e0%b8%99%e0%b8%9e%e0%b8%a2%e0%b8%b2%e0%b8%9a%e0%b8%b2%e0%b8%a5%e0%b9%80%e0%b8%ad%e0%b8%81%e0%b8%8a%e0%b8%99.pdf)

### Inferences
- Cordia New, Angsana New and Browallia New are Microsoft fonts bundled with Windows and Office. They are common on real labels but not redistributable. Generate with them locally if installed, but do not commit the font files.
- Kanit, Prompt, Mitr, Chakra Petch and IBM Plex Sans Thai are also on Google Fonts and usually OFL (**UNVERIFIED** in this session; check each OFL.txt). Many hospital label printers use thermal printers with monospace or bitmap Thai fonts, so add a low-resolution or bitmap-looking font to cover that case (**UNVERIFIED**).

### Gaps
- The exact license of the current TH Sarabun New download from SIPA/DEPA was not confirmed.
- I found no data on which fonts Thai hospital label printers actually use (for example HOSxP-style systems).

## 4. Synthetic text-image tools that support Thai, and Thai rendering pitfalls

### Takeaway
No off-the-shelf Thai medicine-label generator exists. The practical path is (a) render full labels from HTML/CSS or a Pillow+raqm template, which gives correct HarfBuzz shaping for stacked vowels and tone marks, with ground-truth JSON written from the same template variables, then (b) degrade the images with **Augraphy** and/or albumentations. SynthTIGER requires libraqm and suits line-crop recognition data. trdg has no documented Thai support. The newest Thai-specific synthetic OCR research (Sept 2026) used HarfBuzz shaping and found that typeface diversity matters most.

### Cited Findings
- **SynthTIGER** (NAVER Clova) is a synthetic text-image generator for OCR training. It needs Python ≥3.6 and **libraqm**, installs from PyPI, and its CLI takes a template script plus a config file and outputs images with text labels — [PyPI synthtiger](https://pypi.org/project/synthtiger); [SynthTIGER paper arXiv 2107.09313](https://arxiv.org/pdf/2107.09313). Its experiments were on Latin and Japanese text; I found no Thai template or dataset — same sources
- **trdg (TextRecognitionDataGenerator)** says "Now supporting non-latin text". You add a language by creating a `fonts/<iso639-1>` folder and registering it in `load_fonts()`. Thai is not named, and there is an open issue about blank or "?" output for Arabic, which suggests a shaping problem (cause not confirmed) — [PyPI trdg](https://pypi.org/project/trdg); [trdg docs tutorial](https://textrecognitiondatagenerator.readthedocs.io/en/latest/tutorial.html); [trdg issues](https://fr.github.com/Belval/TextRecognitionDataGenerator/issues)
- **Augraphy** is a Python library that simulates print, fax, scan and photocopy degradation:
  - It uses ink, paper and post-processing layers.
  - Effects include BleedThrough, LowInkLines, BadPhotoCopy, BookBinding and folds.
  - The paper says 26 augmentations; later project pages say more than 50.
  - Install with `pip install augraphy`; the entry point is `default_augraphy_pipeline()`.
  - Sources: [Augraphy arXiv 2208.14558](https://arxiv.org/pdf/2208.14558); [augraphy docs](https://augraphy.readthedocs.io/); [PyPI augraphy](https://pypi.org/project/augraphy/)
- **"How Far Can Synthetic Data Take Thai OCR?"** (Kunat Pipatanakul, arXiv 2609.03595, 3 Sep 2026, CC BY 4.0):
  - Method: rebuilds 45,723 synthetic pages by shaping Thai with **HarfBuzz** and shrinking the type until it fits the original regions.
  - Findings: typeface diversity, 2-D structure and real handwriting glyphs improve transfer; non-text context has little consistent effect.
  - The adapted model, Wayu-Paxa-OCR-Zero (on PaddleOCR-VL-1.6, 0.9B), beats Typhoon OCR v1 7B on all 5 evaluation sets.
  - Printed-page median CER drops from 6.64% to 1.24%. Page-level in-domain synthetic training is close to real data (1.82% vs 1.31% CER).
  - It names no augmentation library and links no code or data.
  - It does not use trdg or SynthTIGER.
  - Sources: [arXiv abs](https://arxiv.org/abs/2609.03595); [arXiv HTML](https://arxiv.org/html/2609.03595v1)
- **SynthOCR-Gen** (arXiv 2601.16113) is a synthetic OCR dataset generator aimed at low-resource languages. Its Thai coverage was not checked — [arXiv 2601.16113](https://arxiv.org/html/2601.16113v1)
- **ThaiOCRBench** (SCB 10X, arXiv 2511.04479, Dec 2025) has 2,808 human-annotated samples in 13 task types, including key information extraction and fine-grained text recognition. The dataset and evaluation code are stated to be public. It lists earlier Thai OCR corpora: NECTEC Thai OCR corpus, BEST2019 and Burapha-TH — [arXiv 2511.04479](https://arxiv.org/abs/2511.04479) (PDF text extracted locally)

### Inferences
- **Recommended pipeline** (team-authored, not from a source):
  1. A Python sampler draws one `LabelSpec` (drug from TMT, dose, unit, times, meal timing, PRN flag, warnings, fake hospital and patient) and writes `NNNN.json`.
  2. It renders HTML/CSS with Thai fonts through a headless browser, or Pillow with `layout_engine=ImageFont.Layout.RAQM` (requires libraqm). This avoids floating or overlapping tone marks (ไม้เอก/โท over สระอิ/อี, for example "ที่", "น้ำ").
  3. It also renders the clean image, then applies Augraphy and albumentations variants (perspective, blur, JPEG, shadow, lighting gradient, wrinkles).
  4. Ground truth stays exact, because the image comes from the JSON.
- Also generate "hard" variants: mixed Thai/English on one line, ALL-CAPS trade names, mg vs มิลลิกรัม, Thai digits (๑๒๓), Buddhist-era dates, stamps, and handwritten ticks.
- Keep a fixed random seed and save the spec with each image, so a failing case can be reproduced.

### Gaps
- I did not confirm whether trdg renders Thai correctly with raqm installed. There is no Thai-specific issue in the results.
- Pillow's raqm requirement for Thai is general knowledge (**UNVERIFIED** in this session).
- I found no Typhoon OCR synthetic-data recipe or PaddleOCR Thai synthetic recipe, beyond the Typhoon OCR baselines in arXiv 2609.03595.

## 5. Evaluation methodology and batch-running Apple Vision on the Mac

### Takeaway
Score at two levels:
- **OCR level:** CER on NFC-normalized text.
- **Field level:** exact-match precision, recall and F1 per field, as in SROIE/CORD. Optionally add TED accuracy for the nested medicine list.

Vision OCR runs fine from a macOS command-line Swift script. Both `VNRecognizeTextRequest` (macOS 10.15+/iOS 13+) and `RecognizeTextRequest` (macOS 15+/iOS 18+) are older than iOS 26, so they are safe for the team's Xcode 26 rule. **Thai is available only at `.accurate` level, not `.fast`** (verified locally).

### Cited Findings
- CORD: 1,000 receipts (800/100/100), 30 labels in 4 categories. SROIE: 626 train / 347 test receipts. KIE is scored with field-level (entity-level) F1, where a field counts as failed if even one character is wrong, and with Tree-Edit-Distance (TED) accuracy following Kim et al. 2022 (Donut). HED/UHED variants handle unordered line items — [OmniParser arXiv 2403.19128](https://arxiv.org/pdf/2403.19128); [OmniParser V2 arXiv 2502.16161](https://arxiv.org/pdf/2502.16161); [DocParser arXiv 2304.12484](https://arxiv.org/pdf/2304.12484)
- A 2026 Thai OCR paper reports median page CER and character-weighted mean CER. Before scoring it strips HTML, Markdown and LaTeX, removes **all whitespace**, and applies **Unicode NFC**. It uses rapidfuzz indel alignment for "projected CER" — [arXiv 2609.03595 HTML, App. C](https://arxiv.org/html/2609.03595v1)
- A commercial blog argues CER can mislead for document-parsing VLMs. It is a vendor source, so treat it as opinion — [imagetotable.ai](https://imagetotable.ai/references/why-cer-misleads-document-parsing)
- Swift shebang scripts that run `VNImageRequestHandler` + `VNRecognizeTextRequest` on images and print JSON exist, and need the Xcode command-line tools — [alexwlchan get_live_text.swift](https://alexwlchan.net/projects/get_live_text/files/get_live_text.swift). Another author batch-processed comic images with a Swift Vision script (accurate mode, language correction, one JSON per image) — [fsck.com blog](https://blog.fsck.com/agent-blog/2026/02/12/comic-ocr/). Ready-made CLIs: [privatenumber/mac-ocr](https://github.com/privatenumber/mac-ocr), and macos-vision-ocr (single and batch modes) — [sourcepulse](https://www.sourcepulse.org/projects/25871471)
- **Verified locally** (M-chip Mac, macOS 27.0.1, Xcode 27.0, `swift langs.swift`):
  - `VNRecognizeTextRequest.supportedRecognitionLanguages()` at `.accurate` includes `"th-TH"`. At `.fast` it returns only en, fr, it, de, es and pt-BR, so **no Thai**.
  - The new `RecognizeTextRequest().supportedRecognitionLanguages` includes `th-Thai-TH`.
  - The iPhoneOS 27.0 SDK's Vision swiftinterface declares `@available(macOS 15.0, iOS 18.0, tvOS 18.0, visionOS 2.0, *) public struct RecognizeTextRequest`.
- **Verified locally**: a plain `swift script.swift` run (the interpreter, no Xcode project) can import Vision and PDFKit on macOS. I used it to extract the PDFs above.

### Inferences
- Harness layout (team-authored):
  - `TestData/synthetic/NNNN.png` + `NNNN.json` (expected `PillInfo`-shaped fields)
  - A macOS CLI with two parts: (1) run Vision with `recognitionLevel = .accurate`, `recognitionLanguages = ["th-TH","en-US"]` and the same `usesLanguageCorrection`/`customWords` settings as the app; (2) feed the text into the **same `LabelParser` Swift source** (shared file or a small local Swift package target, so `project.pbxproj` is not touched)
  - Output: a CSV of per-field match plus CER
  - Report: per-field accuracy (drug name, strength, dose amount, unit, each time slot, meal timing, PRN), whole-envelope exact-match rate, and CER on the raw OCR text
- Normalize before comparing: NFC, collapse whitespace, Thai digits to Arabic digits, "mg"/"MG"/"มก."/"มิลลิกรัม" to a single unit form. Strength should be compared numerically (5 mg == 5.0 mg).
- Vision on macOS 27 may differ from iOS 26 on the iPad, because model versions are tied to the OS. Run a small subset on the iPad (an XCTest that loads bundled images) to confirm Mac results match device results.
- An XCTest unit-test target running in the iOS 26 Simulator is another way to run Vision. Whether Thai `.accurate` OCR works in the Intel Macs' Simulator was not verified.

### Gaps
- I did not verify Thai availability on macOS **26** or iOS **26** specifically (only macOS 27 was checked). It is likely, because the API predates both, but run `supportedRecognitionLanguages()` on an Intel Mac or the iPad to confirm.
- Apple's documentation page is JavaScript-rendered and could not be fetched. Availability was taken from the local SDK interface instead.
- I found no published Thai-specific KIE scoring convention beyond ThaiOCRBench's KIE task (its metric details were not read).

## 6. Print-and-capture testing (printing synthetic labels and photographing them)

### Takeaway
No Thai or medical print-and-capture protocol was found. Two document-OCR benchmarks give a template to copy: B-MOD (many phones, many people, many conditions) and Real5-OmniDocBench (the same pages re-captured under 5 controlled conditions: scan, warp, screen photo, illumination, skew).

### Cited Findings
- **Brno Mobile OCR Dataset (B-MOD)**: 2,113 unique pages photographed by multiple people with 23 phones, giving 19,728 photos with about 500k annotated text lines. It targets uneven lighting, blur, noise and compression, and has an evaluation server with a hidden test set — [B-MOD paper PDF](https://fit.vut.cz/research/publication-file/c162131/280333/Brno%20Mobile%20OCR%20Dataset.pdf); [arXiv 1907.01307](https://arxiv.org/abs/1907.01307)
- **Real5-OmniDocBench**: 5 capture scenarios (scanning, warping, screen photography, illumination, skew), each with 1,355 images matched one-to-one to the OmniDocBench pages, so conditions can be compared under control. Non-scan images were taken by hand on mobile devices. The listing says it was accepted to ECCV 2026 — [Hugging Face Real5-OmniDocBench](https://huggingface.co/datasets/JiangWenxiang/Real5-OmniDocBench)
- **OCR-Rotation-Bench**: rotation robustness built from upright documents (RVL-CDIP, FUNSD, DocVQA) — [arXiv 2511.04161](https://arxiv.org/pdf/2511.04161v2)
- Augraphy can simulate print and scan effects digitally, so it is the cheap substitute for physical printing — [Augraphy arXiv 2208.14558](https://arxiv.org/pdf/2208.14558)
- THIS publishes a TMT *photo specification* manual for drug-product images. It may be a useful reference for consistent capture setup — [TMT release note](https://opendata.hsri.or.th/dataset/e85ad683-f5c5-4831-983a-1e6d077efe16/resource/5d91d542-1796-4c72-bd4f-ea6afa0d3309/download/releasenote_tmtrf20250804.pdf) → `https://www.this.or.th/manual/tmt-image-specification/` (page itself not opened)

### Inferences
- A small, team-authored protocol modeled on Real5-OmniDocBench:
  1. Print about 50–100 synthetic labels, on sticker paper or plain paper folded into envelopes, at the real size (around 8×5 cm).
  2. Photograph each one with the iPad under a fixed set of conditions: flat with good light; dim warm indoor light; a phone-flash glare spot; about 30° tilt; crumpled then flattened; curved around a bottle; partly covered by a thumb.
  3. Use the same file IDs so every photo maps to the original JSON ground truth.
- This "real-capture" subset tests the camera, Vision and parser path on real hardware. The large digital set tests the parser across many drugs and phrasings.
- All content stays synthetic (fake patient names and HNs), so it complies with the team's PDPA rule even though it is photographed.

### Gaps
- I did not find a published capture protocol for medicine labels or pharmacy envelopes, in Thai or English.
- I did not verify the B-MOD or Real5 capture details beyond their summaries (light levels, exact angle ranges).
