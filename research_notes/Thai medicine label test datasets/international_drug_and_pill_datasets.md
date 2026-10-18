# International (non-Thai) drug-label, prescription, and pill image datasets for stress-testing a medicine-label OCR + parser app

Scope note: researched 2026-10-18. About 25 search/fetch calls. Two key pages could not be opened: smarthealth.vinuni.edu.vn returned HTTP 403, and the Roboflow "prescription-ocr" page returned HTTP 403. The VAIPE PDF was too large to fetch. Facts from those sources come only from search snippets and are marked. Relevance scores are for the SuperJerry/Jenny app: 5 = directly tests drug name/strength/dose/frequency extraction from label photos; 1 = only loosely useful.

## Q1. Prescription-label, pharmacy-label, medicine-box, and prescription OCR datasets (international and Asian)

### Takeaway
No public dataset I could verify matches the app's task: a phone photo of a pharmacy-dispensed label with ground-truth fields such as drug name, strength, dose, times per day, and meal timing. The closest real-photo sets are the Egyptian-authored Mendeley "Mobile-Captured Drug Packs" sets. They are CC BY 4.0 and show real blur, glare, and angles, but have no text annotations, so you would label them yourself. The handwritten prescription sets are from Bangladesh (word crops, medicine-name labels) and India (MIRAGE, 100 simulated records). They test drug-name recognition, but handwriting is not the app's target. I found no verified public Chinese, Japanese, or Korean medicine-box OCR dataset.

### Cited Findings

**Mobile-Captured Drug Packs (Mendeley Data). Relevance 4/5 for OCR robustness, 2/5 for automated scoring**
- URL: https://data.mendeley.com/datasets/bsmy5jjysy (DOI 10.17632/bsmy5jjysy.3). Authors are Esraa Abdelmaksoud, Ahmed Gadallah, and Ahmed Asad. Version 3 was published 5 Jan 2022. License is CC BY 4.0, which allows commercial use with attribution. — [Mendeley](https://data.mendeley.com/datasets/bsmy5jjysy)
- It has 2,000 phone photos of 166 drug packages, taken on 7 devices. There are 140 flash and 1,860 non-flash images, at varied angles and lighting, on paper, cloth, or plastic backgrounds. Some images have handwriting on the pack, shadows, or flash burns. Some were resized or compressed. Forms include tablets, capsules, syrups, creams, ampoules, gels, drops, and ointments. — [Mendeley](https://data.mendeley.com/datasets/bsmy5jjysy)
- The stated purpose is drug data extraction for patients in "countries with no electronic medical records". The page does not state the country or language, and it describes no OCR or field annotations. — [Mendeley](https://data.mendeley.com/datasets/bsmy5jjysy)

**Mobile-Captured Pharmaceutical Medication Packages (Mendeley Data). Relevance 4/5 for robustness, 2/5 for scoring**
- URL: https://data.mendeley.com/datasets/bjy2svvmn8 (DOI 10.17632/bjy2svvmn8.1). Same authors, version 1, published 21 Mar 2022, CC BY 4.0. — [Mendeley](https://data.mendeley.com/datasets/bjy2svvmn8)
- It has 3,900 photos of 150 packages, 26 per pack, plus two types of medical tape. Conditions include varied angles and lighting, handwriting, shadows, flash glare, damage, and slight blur. The page mentions no annotations and no country or language. — [Mendeley](https://data.mendeley.com/datasets/bjy2svvmn8)

**Doctor's Handwritten Prescription BD dataset (Bangladesh; Mendeley, Kaggle, and a Hugging Face mirror). Relevance 2/5**
- Primary URL: https://data.mendeley.com/datasets/zjjtptvn6f. Kaggle copy: "mamun1113/doctors-handwritten-prescription-bd-dataset", seen through a mirror listing. The images were collected from hospitals and clinics in Bangladesh with permission, and patient-identifiable information was anonymized. Terms: "free to use for educational and research purposes only". — [Mendeley](https://data.mendeley.com/datasets/zjjtptvn6f); [Baselight Kaggle mirror](https://baselight.app/u/kaggle/dataset/mamun1113_doctors_handwritten_prescription_bd_dataset)
- It has 4,680 cropped PNG images of handwritten medicine names, split 3,120 train, 780 val, and 780 test. Labels are medicine name and generic name only, with no dosage or frequency. A Kaggle description says 78 classes, which are medicine names. — [LanceDB handwriting-ocr docs](https://docs.lancedb.com/datasets/handwriting-ocr); [Baselight](https://baselight.app/u/kaggle/dataset/mamun1113_doctors_handwritten_prescription_bd_dataset)
- The associated paper is Mia et al., 2024, at iCACCESS. Sources give the DOI inconsistently. — [Mendeley](https://data.mendeley.com/datasets/zjjtptvn6f)
- One paper using the set describes the files as handwritten lines with CSV annotations. Others describe word crops, so the granularity is reported inconsistently. — search summary of [MALCOM journal article](https://journal.irpi.or.id/index.php/malcom/article/view/1934)

**MIRAGE: Indian handwritten prescriptions (arXiv 2410.09729). Relevance 2/5**
- The full corpus has 743,118 simulated handwritten medical records from 1,133 doctors in 52 specialties in India, from Medyug Technology. It is not stated to be public. — [arXiv 2410.09729](https://arxiv.org/html/2410.09729v1)
- A public subset of 100 labeled prescriptions is linked from the paper as the Hugging Face dataset "100-handwritten-medical-records". Fields cover patient details (simulated), vitals, medication names with schedules and dosage, lab tests, and diagnoses. The records are simulated, not real patient data. No dataset license is stated; the CC BY 4.0 shown applies to the paper. — [arXiv 2410.09729](https://arxiv.org/html/2410.09729v1)

**Roboflow Universe: "Prescription-OCR" (object-detection-v1cyq). Relevance 2/5, unverified details**
- URL: https://universe.roboflow.com/object-detection-v1cyq/prescription-ocr. Per a search snippet, its classes include Age, Dosage, Dr_name, Medicine, and P_Name, and it is CC BY 4.0. The page returned 403 to my fetch, so I could not confirm image count, country, or whether the images contain real patient data. — [Roboflow (search snippet)](https://universe.roboflow.com/object-detection-v1cyq/prescription-ocr)

**Roboflow Universe: pill-bottle and medicine-package detection sets. Relevance 1/5 (no text ground truth)**
- "PIll-bottles" (mandam), CC BY 4.0, updated Aug 2025: https://universe.roboflow.com/mandam/pill-bottles-gtnpm. "pill bottle detection" (lauder-object), CC BY 4.0, May 2025: https://universe.roboflow.com/lauder-object/pill-bottle-detection-1isnp. Neither page has a description. Both are bottle detection, not label-text datasets. — [Roboflow search results](https://universe.roboflow.com/mandam/pill-bottles-gtnpm)
- "Medicine Package" (ocean-phktt) has about 3,446 images of Indonesian over-the-counter brand packages (Antangin, Bodrex, Decolgen, Diatabs, Enervon-C) as detection classes. It is CC BY 4.0. — [Roboflow (search snippet)](https://universe.roboflow.com/ocean-phktt/medicine-package)

**VAIPE prescription images (Vietnam). Relevance would be 4/5 if obtainable; access unverified**
- A VinUni Smart Health Center page, seen only through a search snippet because the fetch returned 403, lists a VAIPE prescription dataset of more than 50,000 images from multiple Vietnamese hospitals. — [VinUni Smart Health resources (snippet)](https://smarthealth.vinuni.edu.vn/resources/)
- VAIPE is a VinUni-Illinois Smart Health Center and BKAI (HUST) project funded by the Vingroup Innovation Fund. Its project page listed two planned open datasets, one of prescription images and one of pill images. — search summaries of [VinUni CHS](https://chs.vinuni.edu.vn/the-initial-achievements-of-vaipe-an-ai-and-iot-based-vietnamese-smart-healthcare-application-after-6-months/) and [VinUni CECS](https://cecs.vinuni.edu.vn/?p=48732)

**Chinese, Japanese, and Korean**
- No Chinese medicine-box or Japanese drug-package OCR dataset turned up in searches. The closest Chinese resource is the general FudanVI Chinese Text Recognition benchmark (scene, web, document, and handwriting), which is not packaging-specific. — [arXiv 2112.15093](https://export.arxiv.org/abs/2112.15093)
- A NAIST group presented work at IEVC 2026 on web image collection and LLM-based labeling for visual inspection of drug packaging. No public release was found. — [NAIST UBI blog](https://ubi-blog.naist.jp/index.html%3Fp=4483.html)
- Format template, not drug-related: the Mendeley "Food Packaging OCR Dataset" has detection and recognition splits plus fields such as product name, brand, ingredients, and expiry date. — [Mendeley 3cpx2fmn3r](https://data.mendeley.com/datasets/3cpx2fmn3r/2)

**Commercial, not a dataset**
- Veryfi sells a prescription medication label OCR API that extracts medication name, dosage, NDC, and similar fields. It is paid and has no public data. — [Veryfi](https://www.veryfi.com/prescription-medication-label-ocr-api)

### Inferences
- For Jenny, the most useful international set to download is the Mendeley drug-pack data: 5,900 images in total, CC BY 4.0, with real phone-capture problems such as glare, flash burn, and blur. The team would need to hand-label a small subset of 50 to 100 images with drug name and strength before computing accuracy. This is feasible in a hackathon if limited to the English drug-name and strength line.
- Box packaging, as in the Mendeley sets, differs from Thai pharmacy envelopes. Boxes rarely carry patient-specific dose, frequency, or meal timing. So these sets can test drug-name and strength extraction and OCR robustness only, not the dosing-instruction parser.
- The handwritten sets (Bangladesh and MIRAGE) are mostly off-target because Thai envelopes are printed or stamped. They would matter only if the team adds handwritten prescription reading.
- Because Thai envelopes vary so much and no matching public set exists, a small self-made synthetic set with field ground truth is probably still needed. These international sets complement it rather than replace it.

### Gaps
- VAIPE prescription and pill data: I could not confirm a download URL, license, or whether access requires a request form or agreement. The VinUni page returned 403 and the arXiv abstract page lists no data link. Image counts conflict: the arXiv paper reports 9,426 images with 96 pill labels, while the VinUni page says more than 50,000.
- Roboflow "Prescription-OCR": image count, origin, and privacy status are unverified.
- I could not find or verify a dataset named "RxLabel", nor a Korean drug-package dataset.
- The Mendeley sets' country and language are not stated. The authors' affiliation suggests Egypt, but that is inferred, not stated.

## Q2. Pill image datasets: NLM C3PI/Pillbox, the NLM Pill Image Recognition Challenge, ePillID, CURE, VAIPE, and others, with current availability

### Takeaway
NLM's C3PI/RxIMAGE images remain downloadable from data.lhncbc.nlm.nih.gov. That is about 133k consumer-grade photos and about 4k reference images, with NDC and drug-name metadata, under ODbL, and the data.gov record was last modified July 2025. Pillbox the website and API was retired in 2021, and NLM says neither collection should be used for real pill identification. ePillID (built from NIH data, research only) and CURE (8,973 images) are the standard benchmarks. MEDISEG (2025/2026, CC BY 4.0) is a newer, openly licensed alternative. All of this matters only if pill recognition is added later.

### Cited Findings

**NLM C3PI / RxIMAGE (includes the Pill Image Recognition Challenge data). Relevance 2/5 now, 4/5 if pill recognition is added**
- data.gov record: https://catalog.data.gov/dataset/computational-photography-project-for-pill-identification-c3pi. It lists about 133,000 consumer-grade training images and 4,000 controlled-light reference images. License is ODC Open Database License (ODbL). The record was first published 6 Aug 2020 and last modified 16 Jul 2025. It says "No new images will be added to the collection" and that the images and metadata are for research and development. — [data.gov](https://catalog.data.gov/dataset/computational-photography-project-for-pill-identification-c3pi)
- Downloads: index at https://data.lhncbc.nlm.nih.gov/public/Pills/index.html. Reference set: https://data.lhncbc.nlm.nih.gov/public/Pills/rximage.zip, listed as 6.8 GB on data.gov and about 7.3 GB in the directory listing. Sample: https://data.lhncbc.nlm.nih.gov/public/Pills/sampleData.zip, about 493 to 517 MB. Most files are timestamped 2024-08-28. — [data.gov](https://catalog.data.gov/dataset/computational-photography-project-for-pill-identification-c3pi); [NLM directory](https://data.lhncbc.nlm.nih.gov/public/Pills/index.html)
- Structure from the README: consumer images are in PillProjectDisc1 through PillProjectDisc110/images/, about 2.6 TB in total. Per-folder XML metadata is in ALLXML/. directory_consumer_grade_images.txt is pipe-delimited with fields: 11-digit NDC, part number, file location, image type (C3PI_Reference / C3PI_Test), and name, for example "STRATTERA 10MG". A search for "Lipitor" returns 148 images. The project was discontinued in 2018. — [NLM AAREADME](https://data.lhncbc.nlm.nih.gov/public/Pills/AAREADME)
- Pillbox's website, dataset, image library, and APIs were retired in 2021, with users pointed to MedlinePlus. Reasons given were low usage and overlap with DailyMed. NLM said the remaining Pillbox data and pill images should not be used for pill identification. — [GCN](https://www.gcn.com/data-analytics/2021/05/nlm-pillbox-put-out-to-pasture/316051/); [Route Fifty](https://route-fifty.com/digital-government/2021/05/nlm-pillbox-put-out-to-pasture/316051)
- The MEDISEG paper gives Pillbox as 4,392 reference plus 133,774 consumer images, with the program discontinued 29 Jan 2021. — [arXiv 2603.10825](https://arxiv.org/html/2603.10825)
- The 2016 Pill Image Recognition Challenge was C3PI's last milestone. — search summary of [Federal Register notice via vLex](https://regulations.vlex.com/vid/end-of-the-call-727127833); [NLM initial challenge report](https://lhncbc.nlm.nih.gov/LHC-publications/pubs/ThenationallibraryofmedicinepillimagerecognitionchallengeAninitialreport.html)
- A third-party "Pillbox master data" listing on John Snow Labs requires an end-user license agreement and is labeled Research Non-Commercial, Share-Alike, Attribution. — search summary of [John Snow Labs](https://johnsnowlabs.com/marketplace/pillbox-master-data-lookup)

**ePillID (Microsoft/UW, CVPR Workshops 2020). Relevance 2/5**
- Repo: https://github.com/usuyama/ePillID-benchmark, with data on its Releases page. It has about 13k images and 9,804 appearance classes, which are two sides of 4,902 pill types. Most classes have only one reference image (low-shot). It is built from NIH challenge consumer photos and Pillbox reference images. The code is MIT-licensed, but the dataset and software are "released for research purposes only." — [GitHub](https://github.com/usuyama/ePillID-benchmark); [arXiv 2005.14288](https://arxiv.org/abs/2005.14288v1)
- The CVPRW version reports 8,184 classes versus 9,804 in arXiv v1. — [CVF open access](https://openaccess.thecvf.com/content_CVPRW_2020/papers/w54/Usuyama_ePillID_Dataset_A_Low-Shot_Fine-Grained_Benchmark_for_Pill_Identification_CVPRW_2020_paper.pdf)
- My fetch showed the Releases section as empty, so I could not verify that the download is live. — [GitHub](https://github.com/usuyama/ePillID-benchmark)

**CURE (Ling et al., "Few-Shot Pill Recognition", CVPR 2020). Relevance 2/5**
- CURE has more varied imaging conditions and more instances per class than NIH. — [CVPR 2020 via mlanthology](https://mlanthology.org/cvpr/2020/ling2020cvpr-fewshot/)
- It has 8,973 images with partial instance-segmentation labels, includes synthetic images, and is public. A 2026 paper says only Pillbox and CURE are publicly available among prior sets. — [arXiv 2603.10825](https://arxiv.org/html/2603.10825)

**MEDISEG (City St George's, University of London). Relevance 2/5; the most permissive license**
- It has 8,262 images of 32 pill types photographed in a 4x7 dosette box, cropped to 640x640. Pills overlap and are occluded, under varied lighting with specular highlights. Annotations are COCO instance masks plus boxes, and metadata.csv adds drug registration details. License is CC BY 4.0. Download: https://doi.org/10.25383/city.28574786.v1. The preprint is dated 11 Mar 2026. — [arXiv 2603.10825](https://arxiv.org/html/2603.10825)

**VAIPE pill images (Vietnam). Relevance 2/5; access unverified**
- The arXiv paper reports 9,426 smartphone images with 96 pill labels from real intake. They were labeled using the matching prescriptions, which ties pills to prescriptions. — search summary of [arXiv 2303.09782](https://arxiv.org/pdf/2303.09782)
- The VinUni page claims more than 50,000 annotated VAIPE-Pill images. — [VinUni (snippet)](https://smarthealth.vinuni.edu.vn/resources/)
- The paper was submitted 17 Mar 2023 and was under review at PLOS ONE. The arXiv abstract page has no data URL. — [arXiv abs](https://arxiv.org/abs/2303.09782)
- A VAIPE pill-recognition challenge drew 163 teams, and VAIPE won the AI4VN 2022 AI Awards. — search summary of [VinUni CECS](https://cecs.vinuni.edu.vn/?p=48732)

**Ultralytics "medical-pills". Relevance 1/5**
- It has 115 images (92 train, 23 val) with a single "pill" class, licensed AGPL-3.0. It auto-downloads with medical-pills.yaml. — [Ultralytics docs](https://docs.ultralytics.com/datasets/detect/medical-pills/)

**Not public, per the MEDISEG comparison:** Lee et al. (15,031 images), Wong et al. (5,284), and Tan et al. (5,131). — [arXiv 2603.10825](https://arxiv.org/html/2603.10825)

### Inferences
- Pill images are US-market products for NIH, ePillID, and CURE, and UK products for MEDISEG. Thai generic pills will mostly differ, so these sets are good for method development but cannot provide a Thai pill classifier.
- For a hackathon, C3PI's sampleData.zip (about 0.5 GB) is the practical entry point. The full consumer set is about 2.6 TB.
- ODbL (C3PI) and CC BY 4.0 (MEDISEG) are friendlier than ePillID's research-only terms, but the NLM pages still frame the data as for research and development.

### Gaps
- Exact CURE download URL and license: not found in this session.
- Whether the ePillID release files are still downloadable in 2026: unverified.
- VAIPE pill data access route and license: unverified.

## Q3. Drug-label text sources: DailyMed SPL images, openFDA, and package inserts

### Takeaway
DailyMed provides bulk zip downloads and per-label media through REST web services. That gives US label text and any packaging or label images the manufacturers submitted, with exact drug name and strength as ground truth. It is a good source of true drug-name and strength strings, such as a dictionary for fuzzy-matching OCR output, and of clean label artwork. It is not a source of dispensed-label photos.

### Cited Findings
- DailyMed offers full and periodic (daily, weekly, monthly) bulk downloads of all labels as zip files. One subset needs at least 16.38 GB. — search summary of [DailyMed SPL resources](https://dailymed.nlm.nih.gov/dailymed/spl-resources.cfm)
- SPL documents are XML. — [Brown BCBI DailyMed SPL dataset docs](https://docs.bcbi.brown.edu/codiac-for-health/ursa-ri/datasets/dailymed-spl-dataset)
- SPLIMAGE covers image files of oral solid dosage forms submitted to the FDA with SPL documents. — [Wikipedia: Structured Product Labeling](https://en.wikipedia.org/wiki/Structured_Product_Labeling)
- The DailyMed web services are at https://dailymed.nlm.nih.gov/dailymed/app-support-web-services.cfm. A Julia wrapper retrieves a label's media files by set ID. — [data.gov DailyMed](https://catalog.data.gov/dataset/dailymed); [JuliaHub DailyMed.jl](https://docs.juliahub.com/General/DailyMed/stable/)
- NLM cited duplication with DailyMed as one reason for retiring Pillbox. — [Route Fifty](https://route-fifty.com/digital-government/2021/05/nlm-pillbox-put-out-to-pasture/316051)

### Inferences
- The app's parser could be tested against a drug-name and strength lexicon from DailyMed or RxNorm. For example, check whether "Amlodipine 5 mg" OCR output with typos fuzzy-matches the correct entry. This tests the parser rather than the OCR.
- DailyMed images are mostly manufacturer carton and container artwork, which is flat and clean, not photographed. They would need synthetic augmentation (blur, perspective, curvature) to stress-test OCR.

### Gaps
- openFDA drug-label API (https://open.fda.gov/apis/drug/label/): not fetched this session, so endpoint details, license, and whether it includes images are unverified. My background knowledge is that it is text-only JSON derived from SPL, but this needs confirming.
- The exact folder layout of label and packaging images inside DailyMed zips: unverified.
- I did not research Asian package-insert corpora such as the Japanese PMDA or the Chinese NMPA.

## Q4. Receipt OCR and key-field extraction benchmarks (SROIE, CORD, WildReceipt) as a scoring template, and which datasets allow automated accuracy scoring

### Takeaway
SROIE, CORD, and WildReceipt are the standard templates for scoring key-field extraction. Each image comes with (a) word or line boxes plus transcripts for OCR scoring and (b) a separate key-field file for field-level exact-match or F1 scoring. CORD v2 is the easiest to adopt: CC BY 4.0, on Hugging Face, with a JSON schema of nested field classes such as menu.nm, menu.price, and total.total_price. Jenny could mirror that by labeling each test image with a JSON of {drug_name, strength, dose_amount, times_per_day, meal_timing, warnings}. Among the medicine datasets above, only MEDISEG, C3PI, ePillID, CURE, and VAIPE (pill identity) and the BD and MIRAGE handwriting sets (medicine-name text) have ground truth usable for automated scoring. None of the medicine-label sets has field-level dose or frequency ground truth from photos.

### Cited Findings

**CORD (NAVER Clova, Indonesian receipts). Template relevance 4/5**
- Repo: https://github.com/clovaai/cord. Versions v0 through v2 each have 1,000 receipts (800 train, 100 dev, 100 test). The repo's text also mentions more than 11,000 receipts in total, which conflicts with the 1,000 released. — [GitHub clovaai/cord](https://github.com/clovaai/cord)
- Annotations: valid_line words with 4-point quads, text, row_id, and is_key. Each item has a category and group_id across 30 categories and 42 subclasses, for example menu.nm, menu.price, and total.total_price. There are also roi and repeating_symbol fields. — [GitHub clovaai/cord](https://github.com/clovaai/cord)
- License is CC BY 4.0. v1 and v2 are on Hugging Face (naver-clova-ix/cord-v1, naver-clova-ix/cord-v2), released 20 Jul 2022. v0 came out 26 Dec 2019. — [GitHub clovaai/cord](https://github.com/clovaai/cord)

**SROIE (ICDAR 2019, mostly Malaysian receipts). Template relevance 4/5**
- It has 1,000 scanned receipts and three tasks: text localization, OCR, and key information extraction. The key fields are company, address, date, and total. — [arXiv 2103.10213](https://arxiv.org/abs/2103.10213v1); [Voxel51 HF card](https://huggingface.co/datasets/Voxel51/scanned_receipts)
- Each image has a box file with 4 clockwise vertices and a transcript per text region, plus a separate key-field file. A community repo corrected errors in the original release. — [Voxel51 docs](https://docs.voxel51.com/dataset_zoo/datasets_hf/scanned_receipts.html); [GitHub zzzDavid/ICDAR-2019-SROIE](https://github.com/zzzDavid/ICDAR-2019-SROIE)
- Split sizes conflict between sources: 600/400, 712/347 (or 361), and 626. — [GitHub zzzDavid](https://github.com/zzzDavid/ICDAR-2019-SROIE); [Voxel51](https://docs.voxel51.com/dataset_zoo/datasets_hf/scanned_receipts.html)

**WildReceipt (OpenMMLab, SDMG-R paper). Template relevance 3/5**
- It has about 1,740 receipt photos taken in the wild, 68,975 text boxes, and 25 key-information categories, aimed at unseen templates. It is distributed as wildreceipt.tar through MMOCR. — [arXiv 2103.14470](https://arxiv.org/pdf/2103.14470); [MMOCR KIE docs](https://mmocr.readthedocs.io/en/0.x/datasets/kie.html)
- Papers with Code gives about 1,765 photos and 50,000 boxes and says the dataset is "pending release", which conflicts with the paper and is likely outdated. — [Papers with Code](https://paperswithcode.com/dataset/wildreceipt)

**Related prescription-text annotation schema**
- There is a published annotation and modeling schema for prescription regimens (drug, dose, frequency, and similar). It may help define Jenny's field schema. — [PMC6544933](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6544933/)
- A Philippine typewritten-prescription study used Tesseract plus NER with labels such as dosage, drug, frequency, and route, but released no public dataset. — [DLSU 2022 proceedings](https://www.dlsu.edu.ph/wp-content/uploads/pdf/conferences/research-congress-proceedings/2022/HCT-09.pdf)

### Scoring-readiness summary (derived from the cited findings above)

| Dataset | Ground truth suitable for automated scoring? | What it can score for Jenny | License |
|---|---|---|---|
| Mendeley Drug Packs (2,000) / Medication Packages (3,900) | No text ground truth; must hand-label | OCR robustness and drug-name/strength after labeling | CC BY 4.0 |
| BD Handwritten Prescription (4,680 crops) | Yes: medicine-name label per crop | Drug-name recognition (handwritten) | Education and research only |
| MIRAGE public subset (100) | Yes: labeled fields incl. medication, dosage, schedule | Name/dose/schedule parsing (handwritten, simulated) | Not stated |
| Roboflow Prescription-OCR | Boxes per field class (Medicine, Dosage, ...) | Field localization; text ground truth unverified | CC BY 4.0 (snippet) |
| VAIPE prescriptions | Unknown | Potentially high (Asian printed prescriptions) | Unverified |
| C3PI / RxIMAGE | Yes: NDC and drug name+strength per image | Pill identity; name strings | ODbL, R&D framing |
| ePillID / CURE / MEDISEG | Yes: pill class (and masks for MEDISEG) | Pill recognition only | Research-only / ? / CC BY 4.0 |
| CORD / SROIE / WildReceipt | Yes: OCR boxes, text, and key fields | Scoring-method template only | CORD CC BY 4.0; others unverified |

### Inferences
- Recommended scoring method for Jenny, modeled on SROIE and CORD: per-field exact match after normalization (lowercase, unify "mg" spacing), plus character error rate on the raw OCR text, reported per condition (blur, glare, curved bottle).
- MIRAGE's 100 simulated records and the CORD JSON format together make a reasonable model for a self-built Thai envelope test set. Simulated data also sidesteps PDPA, consistent with the team's synthetic-only rule.

### Gaps
- SROIE and WildReceipt licenses: not confirmed. I did not reach the official RRC (rrc.cvc.uab.es) page or MMOCR license text.
- Privacy: the BD dataset states anonymization. MIRAGE is simulated. The Mendeley drug packs show product packaging, though some packs carry handwriting whose content is unknown. VAIPE prescriptions come from real hospitals, so their privacy handling is unverified, and real-patient prescription images should be avoided under the team's PDPA and synthetic-only rule unless they are verified as de-identified.
