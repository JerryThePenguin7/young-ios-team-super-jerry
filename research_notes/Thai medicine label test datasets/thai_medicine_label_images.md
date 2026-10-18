# Public image datasets of Thai medicine envelopes, drug labels, and prescriptions (as of 18 Oct 2026)

Bottom line up front: I found **no public, downloadable image dataset of Thai medicine envelopes (ซองยา), hospital or pharmacy drug stickers (ฉลากยา), or Thai prescription slips** on Hugging Face, Kaggle, Roboflow Universe, GitHub, or Thai government and academic portals. The closest real Thai sets are (a) a 100-image Thai prescription-label set used in two 2025 MDPI papers, which was **not released**; (b) the "Medical" slice of **ThaiOCRBench** (Hugging Face, CC BY-SA 4.0), which has some Thai medicine packaging and hospital text with ground truth; and (c) general Thai OCR benchmarks. For mass-testing the parser, the realistic path is **synthetic envelopes**: the team renders labels itself, which also satisfies the "synthetic health data only" rule.

## Are there Roboflow Universe / Kaggle / Hugging Face datasets for Thai medicine labels, envelopes, or prescriptions?

### Takeaway
No. Searching all three platforms for "thai medicine", "thai drug", "thai prescription", "thai pharmacy", "thai pill", "medicine envelope", "ฉลากยา", and "ซองยา" found no Thai medicine-label image dataset. Every medicine-label dataset found is English, Indian, Chinese, or Taiwanese. The only Thai-language image sets with ground truth are general OCR benchmarks, and one of them (ThaiOCRBench) has a small "Medical" category.

### Cited Findings
**Hugging Face (checked with the public API `huggingface.co/api/datasets?search=...` on 2026-10-18):**
- Searches for "thai medicine", "thai drug", "thai prescription", "thai pharmacy", "thai pill", "medicine envelope", "ฉลากยา", and "ซองยา" each returned **0 datasets**. "thai medical" returned only text datasets, such as Medical-o1-Reasoning-SFT-Thai and thai-medical-kb. — [HF datasets search](https://huggingface.co/datasets?search=thai)
- **typhoon-ai/ThaiOCRBench**: the closest Thai match. It has 2,808 human-annotated samples across 13 tasks (text recognition, key information extraction, full-page OCR, VQA, and others). It is licensed CC BY-SA 4.0, is not gated, was created 2025-10-30, is about 1.9 GB of parquet, and was accepted at IJCNLP-AACL 2025. Each row has `image`, `Task`, `question`, `answer`, and `category` fields. — [HF card](https://huggingface.co/datasets/typhoon-ai/ThaiOCRBench); [paper](https://arxiv.org/abs/2511.04479); [GitHub](https://github.com/scb-10x/ThaiOCRBench)
  - In the first 100 rows (all "Fine-grained text recognition"), **7 had category "Medical"**. Their ground-truth answers include drug-packaging text ("ขายเฉพาะสถานที่มีใบอนุญาต", "ยาแก้ท้องอืด ท้องเฟ้อ ยาธาตุน้ำแดง") and hospital text ("โรงพยาบาลโคกสูง", "คลินิกพิเศษอายุรกรรม", "งดใช้โทรศัพท์ขณะรับยา"). (I checked these with the HF datasets-server `first-rows` endpoint.) The task asks for the text inside given coordinates, so ground truth exists only for small regions, not as structured dose fields. — [HF dataset viewer](https://huggingface.co/datasets/typhoon-ai/ThaiOCRBench)
- **openthaigpt/thai-ocr-evaluation**: a Thai and English OCR evaluation set of under 1K images. It has `image`, ground-truth `text`, and `category` fields (handwritten, document, scene_text), with images "derived from various open-source websites". It is licensed CC BY-SA 4.0 and was created 2024-09-29. It is not medicine-specific. — [HF card](https://huggingface.co/datasets/openthaigpt/thai-ocr-evaluation)
- Other Thai OCR sets on HF are not medicine-related: pepder/thai-ocr-text-images (cropped text from Thai PDFs, CC BY 4.0, under 1K images), notewee/thai-road-ocr, iapp/thai_handwriting_dataset, and the fwgpiyawudk sets (insurance, name and address, e-GP OCR). — [pepder card](https://huggingface.co/datasets/pepder/thai-ocr-text-images); [iapp](https://huggingface.co/datasets/iapp/thai_handwriting_dataset)
- **Non-Thai alternative with a good structure to copy:** twinkle-ai/tw-drug-labels-vision has **44,663 Taiwanese TFDA drug leaflet and carton records** (about 67,947 rendered pages, WebP). Each record has 17 structured JSON fields: drug name, dosage form, strength, ingredients, usage and dosage, warnings, and more. It is CC BY 4.0, created 2026-05-02, in Traditional Chinese, and covers manufacturer leaflets and boxes, not pharmacy envelopes. — [HF card](https://huggingface.co/datasets/twinkle-ai/tw-drug-labels-vision)

**Kaggle (web search; Kaggle pages not opened individually):**
- No Thai medicine-label dataset was found. The closest are non-Thai: "The Drug Name Detection Dataset" (1,823 images of bottles, blisters, and vials with drug-name boxes), "Medicine tablet pack image dataset" (about 437 mostly Indian packs), "Mobile Captured Pharmaceutical Medication Packages", OGYEIv2 (4,480 pill images, 112 classes), and "Pills detection dataset" (YOLO, merged from NIH and VAIPE). — [Drug Name Detection](https://www.kaggle.com/datasets/pkdarabi/the-drug-name-detection-dataset); [Tablet pack](https://www.kaggle.com/datasets/nitesh31mishra/medicine-tablet-pack-image-dataset); [Mobile captured packages](https://www.kaggle.com/datasets/aryashah2k/mobile-captured-pharmaceutical-medication-packages); [OGYEIv2](https://www.kaggle.com/datasets/richardradli/ogyeiv2); [Pills detection](https://www.kaggle.com/datasets/alexanderyyy/pills-detection-dataset)

**Roboflow Universe (search engine results only; the Universe search page returned HTTP 403 to my fetch tool, so I could not browse it directly):**
- No Thai medicine-label project was found. Results were generic: "Prescription labeling" (FAST-NUCES, CC BY 4.0), "Medicine label detection" (about 50 images, medicine-name class), "Medicine crimp" (97 images, ibuprofen and paracetamol labels), a "doctor prescription" model, and several pill-detection sets. — [Prescription labeling](https://universe.roboflow.com/fast-nuces-xcmbn/prescription-labeling); [class:medicine search](https://universe.roboflow.com/search?q=class%3Amedicine); [class:prescription search](https://universe.roboflow.com/search?q=class:prescription); [doctor prescription](https://universe.roboflow.com/university-of-engineering-and-management/doctor-prescription)

### Inferences
- ThaiOCRBench's "Medical" rows are the only **public, licensed, ground-truthed real Thai images** that contain medicine-box and hospital text. They suit a quick Thai-OCR sanity check (does Vision with "th-TH" read printed Thai medicine text?), not dose-field parsing. The full count of Medical rows across all 2,808 samples was not computed. The 7-in-100 sample suggests roughly 150-200, but that is an extrapolation.
- CC BY-SA 4.0 means a test harness can use the images with attribution. Redistributing modified images requires the same license.
- The Taiwanese set shows the kind of structured ground truth (name, usage, dosage, warnings) the team should create for its own synthetic Thai set.

### Gaps
- I could not browse Roboflow Universe directly (403), so a small, poorly indexed Thai project there may exist unseen. The team can search universe.roboflow.com for "thai", "ยา", and "ฉลาก" in a normal browser.
- I did not log in to Kaggle, so private or poorly titled Thai uploads cannot be ruled out.
- ThaiOCRBench's full Medical-category count, and whether it has any actual pharmacy envelope or sticker images, are unverified. I also did not check whether any images show patient names. The sampled answers were packaging and signage text only.

## Did Thai academic papers on reading Thai medicine labels (elderly / visually impaired) release datasets?

### Takeaway
Several Thai papers built label-reading systems, but none I found released its images. The most relevant, the Thetbanthad et al. 100-label Thai prescription-label set (MDPI, 2025), states "Data are contained within the article." That means no image download. The papers are still useful as accuracy benchmarks and as a model for building a test set.

### Cited Findings
- **Thetbanthad et al., "Application of Generative AI Models for Accurate Prescription Label Identification and Information Retrieval for the Elderly in Northern East of Thailand", J. Imaging 11(1):11, published 6 Jan 2025.** The authors evaluated EasyOCR + Qwen2-72B (two-stage) and Qwen2-VL-72B (VQA) on **100 prescription-label images from "various public healthcare facilities" in Thailand**. The photos were taken under varying lighting, angles, and resolutions on different phones. Labels cover pain, cold, vitamins, BP, cholesterol, diabetes, antibiotics, GI, mental health, hormones, iron, and miscellaneous drugs, with Thai dosing instructions. Ground truth is a correct/incorrect drug-name check. The Data Availability Statement is "Data are contained within the article." There is no image repository or GitHub link. The authors say "all personal identifiers were anonymized" and cite the PDPA. IRB is "Not applicable." The article is CC BY 4.0, but no dataset license is given. — [PMC full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC11765698/); [DOI](https://dx.doi.org/10.3390/jimaging11010011)
- **Thetbanthad et al., "Automated Redaction of PII on Drug Labels Using OCR and LLMs for Compliance with Thailand's PDPA", Applied Sciences 15(9):4923, 2025.** This paper uses a test set of **100 drug-label images, predominantly in Thai**. The authors note that its size and limited diversity "may not fully capture" real-world variability. I could not open the full text (MDPI returned 403), so the data-availability statement is unverified. The topic itself confirms that **real Thai drug labels carry patient PII** (names, HN). — [DOI](https://doi.org/10.3390/app15094923)
- **Nuankaew et al. (University of Phayao, Rajabhat Maha Sarakham), "AI for Medical Informatics: The Application of OCR Technology in the Transcription of Pharmaceutical Labels", JAIT 16(9):1338-1351, 19 Sep 2025.** This is a mobile OCR app for elderly Thai users with vision impairment. It uses Levenshtein fuzzy matching for drug names, regex for dosage, a dictionary for frequency, and NER for indications, and reports 98.67% overall accuracy. The landing page has no dataset or GitHub link. — [JAIT](https://www.jait.us/show-258-1756-1.html)
- **Burapha University full research report (2563/2020): an OCR system for drug-label and package-insert information** to reduce medication errors, reporting 96.61% image-to-text accuracy. It is a PDF report, and no dataset release was seen in search snippets (not opened). — [BUU IR PDF](https://buuir.buu.ac.th/bitstream/1234567890/3738/3/2563_231.pdf)
- **Thai Journal of Pharmacy Practice: development and evaluation of a mobile app that reads drug labels aloud for the elderly.** Seen in search snippets only. No dataset release was seen. — [TJPP article](https://he01.tci-thaijo.org/index.php/TJPP/article/download/260634/177545/1070048)
- **Nimmolrat et al., "Pharmaceutical mobile application for visually-impaired people in Thailand" (BMC Med Inform Decis Mak, 2021).** This is an app study, not an OCR dataset. — [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8283832/)
- **Mahidol "ฉลากยาพูดได้" (talking drug label with QR code), 2558/2015.** This uses QR codes instead of OCR, and no images were released. — [Mahidol project page](https://mednacea.ict.mahidol.ac.th/project/2558000193)
- **Burapha pill-identification thesis** built on Thai FDA data (color, shape, size + 2D/3D images). It is a research project, not an open data release. — [BUU IR](https://buuir.buu.ac.th/handle/1234567890/3871?mode=full)

### Inferences
- The Thetbanthad J. Imaging paper is the best public benchmark: 100 real Thai labels, phone photos, and LLM-based extraction. The team could cite it in judging ("published systems reach X% on 100 real labels") and could email the corresponding author to request the anonymized images. Any such data would likely come with PDPA and ethics restrictions.
- Because real Thai labels contain patient names and HN numbers (that is the whole premise of the PDPA-redaction paper), any real-label set would conflict with the team's "synthetic only" rule unless it is verifiably anonymized.

### Gaps
- I did not open the full PDFs of the JAIT, BUU, or TJPP papers, so their image counts and any supplementary-data links are unverified.
- I did not search JCSSE, ECTI-CON, KST, iSAI-NLP, or NCSEC proceedings individually (IEEE Xplore and ThaiJO full-text search were not run). A small conference paper with a GitHub link could exist.
- The Applied Sciences paper's Data Availability Statement is unverified (403).

## Did Thai hackathons, Super AI Engineer, AI for Thai, NECTEC, or Thai FDA publish such data?

### Takeaway
No such image data was found. NECTEC and AI for Thai offer Thai OCR services and an old character corpus. Thai FDA publishes drug-registration data as an XML web service (text, not images). None of these provide envelope or label photos.

### Cited Findings
- AI for Thai (NECTEC) is an API platform with Language, Vision (including OCR), and Conversation modules. It offers services, not a medicine-label dataset. — [NECTEC](https://www.nectec.or.th/research/research-project/aiforthai-digitaltransformation.html); [OECD.AI](https://oecd.ai/en/dashboards/policy-initiatives/ai-for-thai-thai-ai-service-platform)
- NECTEC released a Thai-English Character Image Corpus (2012) for OCR research. It contains character images, not labels. — [NECTEC timeline](https://www.nectec.or.th/timeline/2012-thai-ocr-corpus)
- Super AI Engineer (AIAT) appears in NECTEC-ACE 2023 agendas as a program. No medicine-label dataset release was found. — [NECTEC-ACE 2023](https://www.nectec.or.th/ace2023/ss13-aiforthai/)
- The Thai FDA "[Web Service] สืบค้นข้อมูลผลิตภัณฑ์ยา" on data.go.th is XML, with license "not specified", source privus.fda.moph.go.th, and last update shown as 2021. It is drug-registration text and nothing indicates images. — [data.go.th](https://gdcc.data.go.th/en/dataset/web-service-drug-reg)
- The Thai Medicines Terminology (TMT) is used in an open converter to HL7 FHIR. TMT could serve as a **drug-name dictionary** for fuzzy-matching OCR output, but it is text, not images. — [tmt-to-fhir](https://github.com/rathpanyowat/tmt-to-fhir)
- A July 2026 hackathon repo, **smzey/hackathon-anya ("Anya / อ่านยา")**, captures a Thai medicine label and reads it aloud for blind users using Gemini vision and macOS Thai TTS. It contains **a single `test.jpg`** and no dataset. It has **no license** (all rights reserved by default), was created and last pushed 2026-07-03, and is 39 KB. — [GitHub](https://github.com/smzey/hackathon-anya)

### Inferences
- The Thai FDA and TMT text sources could seed a synthetic generator with real English drug names and strengths (e.g. "Amlodipine 5 mg"), which makes synthetic envelopes more realistic.

### Gaps
- I did not browse the AI for Thai or Super AI Engineer project showcases (season 4-6 project lists) directly.
- The Thai FDA web-service resource files were not opened, so the absence of image fields is inferred from the metadata.

## Are there GitHub repos with sample Thai drug label images (even 20-200)?

### Takeaway
None found with a meaningful number of images. GitHub repo searches (via `gh search repos`, 2026-10-18) for "thai medicine label", "thai drug label", "ซองยา", "ฉลากยา", "อ่านฉลากยา", "thai prescription ocr", "thai pill", and "medicine envelope thai" returned either nothing or the single-image Anya repo. Medicine-label OCR repos that do exist are English or Indian.

### Cited Findings
- Only "thai medicine label" matched a relevant repo: smzey/hackathon-anya (1 test image, no license). Thai-script queries (ซองยา, ฉลากยา, อ่านฉลากยา) returned **0 repos**. — [GitHub](https://github.com/smzey/hackathon-anya)
- chrisk320/thaifda_drug is an empty repo (README only, size 0, 2024-06-25). — [GitHub](https://github.com/chrisk320/thaifda_drug)
- Non-Thai medicine-label OCR repos: xaxm007/Medicine-Label-OCR-NER (blister-pack labels), smiglan/OCR-NER-for-medicine-name-from-drug-labels, RuthJancy12/MediScan (EasyOCR, synthetic data), and siddhardhaanagani69-ship-it/RxScanner (a SwiftUI prescription-label scanner using OCR + on-device LLM, 2026-09). — [Medicine-Label-OCR-NER](https://github.com/xaxm007/Medicine-Label-OCR-NER); [smiglan](https://github.com/smiglan/OCR-NER-for-medicine-name-from-drug-labels); [MediScan](https://github.com/RuthJancy12/MediScan); [RxScanner](https://github.com/siddhardhaanagani69-ship-it/RxScanner)
- The lonlonago repos (medicine boxes, 1,032 images; packaging defects, 1,211; cold medicine, 959) show Chinese products, and some are "sponsor to obtain" (paywalled). — [box dataset](https://github.com/lonlonago/Object-Detection-Medicine-Packaging-Box-Dataset-1032-imagesVOC-YOLO-format)

### Inferences
- **Recommendation for the team:** build a synthetic test set. Write a small script (or a SwiftUI `ImageRenderer` view) that fills a Thai hospital or pharmacy envelope template with random but valid combinations:
  - drug name and strength from a list of common English names
  - "รับประทานครั้งละ N เม็ด/แคปซูล/ช้อนชา/ซอง"
  - "วันละ N ครั้ง"
  - เช้า/กลางวัน/เย็น/ก่อนนอน
  - ก่อน/หลังอาหาร
  - "เมื่อมีอาการ"
  - warnings
  - a **fake** patient name and HN

  Save the ground-truth JSON for each image, then add realism: rotation, blur, shadows, crumpled-paper textures, and printing or photographing a subset with the iPad. This gives unlimited images with exact key-field ground truth and zero PDPA risk.
- Use ThaiOCRBench's Medical rows as a small real-world Thai-text check, and the Thetbanthad paper as the published comparison point.

### Gaps
- `gh search repos` matches only names and descriptions. Repos with Thai label images inside a folder of an unrelated-sounding project would not appear. GitHub code and image search was not run.
- No Thai medicine-box or blister-pack image set (as opposed to envelopes) was found either. Thai retail packaging appears only incidentally in ThaiOCRBench's Retail and Medical categories.
