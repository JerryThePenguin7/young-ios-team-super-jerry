# Thai OCR, Thai receipt, and Thai document datasets for testing Apple Vision on printed medicine labels

Research date: 2026-10-18. "Verified" means the dataset page was fetched in this session. "Snippet only" means the detail came from a search-result summary, not a fetched page. Items from background knowledge that were not re-checked are marked "UNVERIFIED".

## Thai receipt datasets (Hugging Face, Kaggle, Roboflow, 7-Eleven, e-tax invoices)

### Takeaway
No open dataset of real photographed Thai receipts with ground truth was found. The only open Thai receipt set is synthetic: DuckerMaster/Thai-Synth-Receipts (MIT, 10K-100K rows, field labels plus OCR boxes). The only real-photo Thai receipt set found is Appen's commercial one (about 1,219 images). Nothing was found for 7-Eleven receipts or Thai e-tax invoices.

### Cited Findings
- **DuckerMaster/Thai-Synth-Receipts** (verified). URL: https://huggingface.co/datasets/DuckerMaster/Thai-Synth-Receipts. Host: Hugging Face. Tagged "Synthetic", MIT license, size bucket 10K<n<100K, with train, validation and test splits (exact count not shown).
  - Labels: key-value fields (merchant, customer, dates, line items with name, qty, unit price and total, subtotal, VAT, total, invoice number) plus `ocr_boxes` (bbox, text, label per element). Both Gregorian and Buddhist-era dates appear (2023-2025).
  - Problems: the HF viewer throws a column-mismatch CastError, so files use inconsistent schemas (some have a `ground_truth` field). No date or generation method is documented. It does not say whether augmentation (crumpling, thermal fade) is used.
  - The preview shows merchant names, tax IDs, phones and addresses. The card does not say whether these are fabricated. — [HF page](https://huggingface.co/datasets/DuckerMaster/Thai-Synth-Receipts)
- **Appen "Thai printed text OCR" off-the-shelf dataset** (snippet only; the product page now returns 404). About 1,219 camera-captured images, "including shopping receipts / tickets / invoices / taxi slips". Commercial licence, not free. — [Appen (search snippet)](https://datasets.appen.com/product/img_ocr_tha_cn)
- **Flitto Data Marketplace** (snippet only). Lists Thai printed-text OCR, Thai handwritten, Thai curved-text, and Thai table/formula/graph image datasets for sale. No size or licence details were captured. — [Flitto marketplace](https://cs.flitto.com/portal/data-marketplace?page=30)
- **Receipts inside other Thai sets:**
  - The Typhoon OCR paper lists "bills/invoices" as 8.7% of its V1 training mix, and receipts, bills and tickets in the V1.5 "Others" evaluation category. The paper does not release these eval sets. — [Typhoon OCR arXiv 2601.14722](https://arxiv.org/html/2601.14722v1)
  - ThaiOCRBench includes Retail-domain and Key Information Extraction tasks. — [ThaiOCRBench HF](https://huggingface.co/datasets/scb10x/ThaiOCRBench)
- **mekpro/ocr_th**, subset `table` (verified). 1,000 synthetic Thai table images (invoices, budgets, schedules) with full-text transcripts, Apache-2.0. — [HF](https://huggingface.co/datasets/mekpro/ocr_th)
- **Generic receipt sets that are not confirmed Thai:**
  - amaye15/Receipt: about 26.9k rows, language not stated. — [HF](https://huggingface.co/datasets/amaye15/Receipt)
  - docjay131/receipts-ocr-dataset: 230 images with Gemini-generated JSON labels, language not stated. — [HF](https://huggingface.co/datasets/docjay131/receipts-ocr-dataset)
- **Commercial Thai receipt OCR services (APIs, not datasets):** iApp Thai Receipt OCR — [iApp docs](https://www.iapp.co.th/docs/ocr/receipt). Asprise — [Asprise](https://asprise.com/receipt-ocr/blog-TH-thai-receipt-ocr-%E0%B9%83%E0%B8%9A%E0%B9%80%E0%B8%AA%E0%B8%A3%E0%B9%87%E0%B8%88)
- **Roboflow:** no Roboflow Universe project was confirmed to hold Thai-script text transcriptions.
  - "THA_OCR" by Mechanika (CC BY 4.0) exists, but its contents were not checked. — [Roboflow](https://universe.roboflow.com/mechanika/tha_ocr)
  - The OCRPlatethai account has Thai licence-plate detection projects (e.g. "LPR plate", about 9.84k images). These look like box detection, not transcripts. — [Roboflow OCRPlatethai](https://universe.roboflow.com/ocrplatethai)

### Inferences
- For receipts, the realistic options are:
  1. Thai-Synth-Receipts. It is clean and rendered, so it probably overestimates accuracy on real thermal prints.
  2. The real-photo subsets of ThaiOCRBench.
  3. A small in-house set the team photographs and labels themselves, for example 30-50 synthetic or self-made medicine envelopes, or their own non-sensitive receipts with personal data blacked out.
- Thermal-printer fade and crumpled paper are not represented in any verified open Thai set. The team would have to add these effects themselves, for example by photographing printed test labels after crumpling them.

### Gaps
- No Kaggle Thai receipt or Thai OCR dataset was found. Kaggle was not searched directly; the search engine did not return any.
- No 7-Eleven or Thai e-tax invoice dataset was found.
- Exact row count and generation method of Thai-Synth-Receipts are unknown.
- The Appen dataset's current availability and price are unknown (page 404).

## Thai OCR benchmark datasets (NECTEC/BEST, Typhoon, OpenThaiGPT, PyThaiNLP, iApp, scene text, ID cards, handwriting)

### Takeaway
- **Best evaluation set:** ThaiOCRBench (SCB 10X / Typhoon, CC-BY-SA-4.0, 2,808 mostly real images). It has a Medical domain, product packaging, and line-level "Text Recognition" and "Fine-grained Text Recognition" tasks.
- **Best real-photo mixed Thai+English line-crop set:** TEMS (Mendeley, CC BY 4.0, 5,000 crops from phone photos, July 2026).
- **Quick smoke test:** openthaigpt/thai-ocr-evaluation (104 crops).
- NECTEC's printed corpus and the Typhoon OCR eval sets were not found as public downloads.

### Cited Findings
**ThaiOCRBench** (verified)
- URL: https://huggingface.co/datasets/scb10x/ThaiOCRBench. Host: Hugging Face (typhoon-ai / scb10x).
- Size: 2,808 rows, about 1.9 GB, test split only.
- 13 tasks:
  - Text Recognition (333)
  - Fine-grained Text Recognition (206)
  - Full-page OCR (197)
  - Handwritten Content Extraction (209)
  - Key Information Extraction (201)
  - Key Information Mapping (209)
  - Table Parsing (193)
  - Document Parsing (211)
  - Chart Parsing (200)
  - Document Classification (215)
  - Diagram VQA (204)
  - Infographics VQA (213)
  - Cognition VQA (217)
- Format: image, Thai question, plain-text answer, and a domain tag (including Medical, Retail, Food & Beverage, Transportation). Some questions ask the model to read text at normalized coordinates.
- Licence: CC-BY-SA-4.0. No gating seen. — [HF](https://huggingface.co/datasets/scb10x/ThaiOCRBench)
- Paper: arXiv 2511.04479 (Nov 2025), accepted to IJCNLP-AACL 2025. — [arXiv](https://arxiv.org/abs/2511.04479)
- How it was built: mostly real images (photos taken in public spaces, public materials, licensed commercial datasets). ID cards and legal certificates are programmatically generated synthetic documents. PII (faces, names, ID numbers) was manually removed or obscured. QA pairs were drafted by GPT-4o, Gemini 2.5 Pro and Azure, then heavily human-revised. — [arXiv HTML v3](https://arxiv.org/html/2511.04479v3)
- Metrics:
  - ANLS: Text Recognition and the VQA tasks.
  - BMFL (the average of BLEU, METEOR, F1 and normalized Levenshtein similarity): fine-grained recognition, full-page OCR and handwriting.
  - TED (Tree Edit Distance): tables, charts and document parsing.
  - F1: key information extraction and mapping. — [arXiv HTML v3](https://arxiv.org/html/2511.04479v3)
- Reported results: Gemini 2.5 Pro averages 77.7%, against 61.5% for the best open model (Qwen2.5-VL 72B). — [alphaXiv / search snippet](https://alphaxiv.org/benchmarks/scb-10x/thaiocrbench)

**TEMS, Thai-English Multiscript Text Image dataset** (verified)
- URL: https://data.mendeley.com/datasets/ntdmgksh9w. DOI 10.17632/ntdmgksh9w.5. Host: Mendeley Data.
- Size: 5,000 cropped text images from 1,625 smartphone photos of natural scenes (billboards, storefronts, road signs, menus, packaging, publication covers). 161 character classes covering Thai, English, mixed Thai-English, digits and symbols. Crops range from 45-1,512 px wide and 18-275 px tall.
- Ground truth: the transcript is embedded in each filename. There is no separate label file.
- Licence and date: CC BY 4.0, version 5 published 13 July 2026. Authors: Jarutan & Surinta, Mahasarakham University. — [Mendeley](https://data.mendeley.com/datasets/ntdmgksh9w)
- Companion paper in MDPI *Data* 2026, 11(7), 178. — [MDPI](https://www.mdpi.com/2306-5729/11/7/178)

**openthaigpt/thai-ocr-evaluation** (verified)
- URL: https://huggingface.co/datasets/openthaigpt/thai-ocr-evaluation
- Size: 104 test crops (84-856 px wide).
- Categories: `handwritten`, `document`, `real_document`, `scene_text` (logos, signs, product labels), and `document_enth` (appears to be mixed English-Thai).
- Ground truth: a `text` string of 3-31 characters. CC-BY-SA-4.0, ungated, no date given. — [HF](https://huggingface.co/datasets/openthaigpt/thai-ocr-evaluation)
- **suchut/thaitrocr-eval-dataset-beta** appears to be the same 104-row set (same 5 categories and size, CC-BY-SA-4.0, "derived from various open-source websites"). — [HF](https://huggingface.co/datasets/suchut/thaitrocr-eval-dataset-beta)

**mekpro/ocr_th** (verified)
- URL: https://huggingface.co/datasets/mekpro/ocr_th
- Size: 4,000 synthetic samples, about 355 MB of Parquet, in 3 subsets:
  - `text`: 1,000
  - `table`: 1,000
  - `official`: 2,000 (contracts, legal texts, police reports, official letters)
- Ground truth: a full-page `text` field of 4 to about 1,470 characters. Apache-2.0, no date given. — [HF](https://huggingface.co/datasets/mekpro/ocr_th)

**pepder/thai-ocr-text-images** (verified)
- Only 13 cropped word images from Thai PDFs, with `file_name,text,category` in `metadata.csv`. CC-BY-4.0. Too small to be useful. — [HF](https://huggingface.co/datasets/pepder/thai-ocr-text-images)

**iapp/thai_handwriting_dataset** (verified)
- About 13.6k rows, 9.12 GB Parquet. Combines the BEST 2019 Thai handwriting training set with Wang's "Thai Handwritten Free Dataset" (4,920 sentences from 2,026 writers).
- Fields: `text` (transcript) and `label_file`. Apache-2.0. — [HF](https://huggingface.co/datasets/iapp/thai_handwriting_dataset)
- Handwriting only, so it is not relevant to printed labels except as a hard negative.

**NECTEC / BEST**
- ThaiOCRBench's related work cites a "NECTEC Thai OCR corpus" of printed Thai text images for character-level OCR, and BEST2019 (NECTEC) handwritten Thai lines, accessible via the AI For Thai platform. No size or open download was given. — [arXiv HTML v3](https://arxiv.org/html/2511.04479v3)
- An older NECTEC printed-Thai OCR system was evaluated on more than 0.6 million printed tokens (thesis citation; the dataset is not public). — [Southampton thesis](https://eprints.soton.ac.uk/206079)

**Burapha-TH** (Onuean et al., 2022, *Applied Sciences*, DOI 10.3390/app12084083)
- Handwritten isolated characters and syllables. Not printed, so not relevant here. — [arXiv HTML v3](https://arxiv.org/html/2511.04479v3)

**Suwanwiwat et al. 2021 multi-script Thai scene text**
- 600 images with manual detection boxes (Thai, English, Chinese, Arabic). Published in *Multimedia Tools and Applications* 80:11843-11863. Available on email request only. Detection boxes only, with no transcripts found. — [JCU repository](https://researchonline.jcu.edu.au/65702/)

**Typhoon OCR** (SCB 10X, arXiv 2601.14722, Jan 2026)
- Training data:
  - V1: 77,029 samples, including Thai SET financial reports, Thai books, iApp handwriting, bills/invoices and government forms.
  - V1.5: 155,403 samples, of which 37.6% are synthetic and 6.4% are DocLayNet.
- Evaluation categories: Thai Books, Government Forms, Financial Reports, Infographics, Handwritten Forms, and Others (receipts, bills, tickets).
- Metrics: BLEU, ROUGE-L, Levenshtein.
- The paper does not name or release the eval sets publicly. Models and code are released (github.com/scb-10x/typhoon-ocr; HF scb10x/typhoon-ocr-7b, typhoon-ocr1.5-2b). — [arXiv HTML](https://arxiv.org/html/2601.14722v1); [HF model](https://huggingface.co/scb10x/typhoon-ocr1.5-2b)

**"How Far Can Synthetic Data Take Thai OCR?"** (Pipatanakul, arXiv 2609.03595, 3 Sep 2026)
- Uses 45,723 synthetic reconstructed pages and five printed and handwritten eval sets. The abstract page does not name, link or license any released datasets.
- Reports median CER:
  - Printed pages: 6.64% to 1.24% after adaptation of PaddleOCR-VL-1.6 ("Wayu-Paxa-OCR-Zero").
  - Handwriting: 74.87% to 20.55%.
  - Page-level training: real printed supervision 1.31% vs in-domain synthetic 1.82%. — [arXiv](https://arxiv.org/abs/2609.03595)

**Thai ID card OCR**
- No public dataset was found.
- iApp's benchmark whitepapers use a proprietary corpus of 1,000 real Thai national ID cards. It is unpublished because it contains real names, addresses and ID numbers. — [iApp whitepaper](https://iapp.co.th/whitepapers/thai-national-id-card-ocr-benchmark-2026.pdf)
- GreatSoravit/PAN_OCR is code only (Darknet field detection plus Tesseract). — [GitHub](https://github.com/GreatSoravit/PAN_OCR)

### Inferences
**Best fit for medicine labels**
1. The ThaiOCRBench subsets Text Recognition, Fine-grained Text Recognition and Full-page OCR, filtered to the Medical, Retail and Food & Beverage domains. Its real photos of packaging are closest to medicine envelopes.
2. The TEMS crops. They are real phone photos of mixed Thai+English text and mimic "Metformin 500 mg" next to Thai text.
3. mekpro/ocr_th `official` and `text` for clean printed full-page Thai.

**Ease of CER/WER scoring**
- Easy:
  - TEMS: filename = transcript, one line per crop. This is the cleanest for line-level CER with Apple Vision.
  - openthaigpt/thai-ocr-evaluation: `text` field.
  - mekpro/ocr_th: full-page text, so line order or reading-order differences will inflate CER.
  - iapp handwriting: `text` field.
- Moderate:
  - ThaiOCRBench. Answers are QA-style. Only the Text Recognition, Fine-grained and Full-page OCR tasks give transcription-like targets, and some prompts reference coordinates, which Vision does not take.
  - Thai-Synth-Receipts. Per-box text in `ocr_boxes` allows box-level CER, but the schema is inconsistent.
- Thai CER should be computed on Unicode code points after NFC normalization. Thai has no spaces between words, so WER needs a tokenizer such as PyThaiNLP. This is a methodological inference, not taken from a source.

**Licences**
- Commercial-OK: TEMS (CC BY), mekpro (Apache), Thai-Synth-Receipts (MIT), iapp (Apache).
- ShareAlike: ThaiOCRBench and openthaigpt are CC-BY-SA, which is fine for internal testing. Redistributing modified copies triggers ShareAlike.

### Gaps
- No public download, size or licence was confirmed for the NECTEC printed Thai OCR corpus or for BEST2019 (AI For Thai). The thailang.nectec.or.th/best pages were not fetched.
- The Typhoon OCR and arXiv 2609.03595 eval sets (including any "Real Thai (Print)" set) were not confirmed as publicly released.
- No PyThaiNLP or VISTEC Thai OCR image dataset was found. PyThaiNLP appears only as a vocabulary source for Typhoon's synthetic data.
- No public "ThaiDocVQA" dataset was found under that name.
- No dedicated Thai scene-text recognition set beyond TEMS and the small openthaigpt set was found. "ThaiSceneText" and "Thai street signs" did not surface.

## Multilingual OCR benchmarks that include Thai (MLT, XFUND, PaddleOCR, Surya, SEA benchmarks)

### Takeaway
MTVQA (ByteDance, ACL 2025 Findings) is the main verified multilingual benchmark that contains Thai real-world text images. It is QA-style and licensed CC BY-NC 4.0, so it is not a pure transcription set. The well-known document and scene benchmarks (ICDAR MLT, XFUND) do not include Thai, based on background knowledge that was not re-checked.

### Cited Findings
- **MTVQA** (verified repo). Data: https://huggingface.co/datasets/ByteDance/MTVQA (plus a Google Drive mirror). Licence: CC BY-NC 4.0 (non-commercial).
  - Covers 9 languages: AR, KO, JA, TH, VI, RU, FR, DE, IT.
  - Test split: 6,778 QA pairs over 2,116 images. Train split: 21,829 QA pairs over 6,678 images. Annotated by native-speaking experts.
  - Per-language Thai counts are not stated on the repo page. Ground truth is QA answers, not full transcripts. — [GitHub](https://github.com/bytedance/MTVQA); [arXiv](https://arxiv.org/html/2405.11985v2)
- ThaiOCRBench's paper notes that MTVQA and PM4Bench include Thai, but calls them multilingual rather than Thai-focused. — [arXiv HTML v3](https://arxiv.org/html/2511.04479v3)
- An NUS WING project, "Benchmarking and Improving OCR Systems for Southeast Asian Languages", compares EasyOCR, Tesseract and GOT on English, Indonesian, Vietnamese and Thai (snippet only; the site failed DNS lookup when fetched). Dataset availability is unknown. — [NUS WING (snippet)](https://wing.comp.nus.edu.sg/project/benchmarking-and-improving-ocr-on-sea-languages)
- ThaiOCRBench reports that the traditional OCR baselines EasyOCR and Tesseract score far below VLMs on full-page Thai OCR (snippet). — [arXiv PDF](https://arxiv.org/pdf/2511.04479)
- No Surya-specific Thai benchmark or olmOCR Thai language list was found in search. — [search result summary; no primary source]

### Inferences
- UNVERIFIED (background knowledge, not re-checked this session):
  - ICDAR 2017 and 2019 MLT cover Arabic, Bangla, Chinese, Hindi, English, French, German, Italian, Japanese and Korean, and do not include Thai.
  - XFUND covers zh, ja, es, fr, it, de and pt, and does not include Thai.
  - Treat these as "probably no Thai" unless verified.
- MTVQA's Thai subset is useful as a "real-world Thai photo" sanity check. Its non-commercial licence and QA-only labels make it weaker than TEMS or ThaiOCRBench for CER scoring.
- For a hackathon, the practical benchmark stack is:
  - TEMS: line-level CER on phone photos with mixed Thai and English.
  - ThaiOCRBench Text Recognition and Full-page OCR, plus the Medical domain filter: real-world documents and packaging.
  - mekpro/ocr_th: clean printed pages.
  - A team-made set of 20-50 synthetic medicine envelopes photographed under bad conditions (curved, crumpled, low light, thermal-printed). This is the only way to cover the actual target domain.
- All of the medicine-envelope test images the team makes themselves should use fake patient names and hospital numbers (PDPA, matching the project's synthetic-data rule).

### Gaps
- The Thai subset size in MTVQA is not known.
- PM4Bench's Thai content, size and licence were not checked.
- PaddleOCR's Thai recognition model, its training data and any public Thai eval set were not researched within the tool budget.
- No public Thai medicine-label or pharmacy-envelope OCR dataset was found in any source.
