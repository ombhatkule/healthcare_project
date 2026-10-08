# Phase 7K — Dataset Candidates

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

| ID | Dataset | Source | License | Observations | Patient/case-level? | Independent of SymbiPredict? | 41-class overlap | Usable for 7K? |
|----|---------|--------|---------|--------------|--------------------|------------------------------|------------------|----------------|
| COL-001 | Columbia University Disease-Symptom Knowledge Database | Columbia DBMI; MedLEE NLP on 25,074 NYP 2004 discharge summaries (AMIA 2008, PMC2656103) | UNKNOWN (pending manual review) | 1,858 disease→symptom associations, 134 diseases, 397 symptoms | Aggregated clinical associations (real discharge-note origin), NOT case-level rows | YES (different source & content) | 8 EXACT / 8 HIGH / 3 POSSIBLE / 22 NO_MATCH | NO — license pending + association format + low coverage (analyzed only) |
| KAU-001 | Kaushil268 Disease Prediction (Kaggle) | Kaggle kaushil268 via GitHub raw mirror | Apache-2.0 | 4,920 rows, 41 diseases, 17 symptom cols | No — canonical HB rows | NO (same family, 304 unique signatures) | all 41 (mirror) | NO — mirror of same canonical family (leakage risk) |
| SYM-001 | SymbiPredict / SDPD (Mendeley) | Mendeley DOI 10.17632/dv5z3v2xyd.1 | CC BY 4.0 | 4,961 rows → 304 unique (Phase 7I input) | No — community-curated | NO — this is the training source | 41/41 | NO — in-sample (Phase 7I source) |
| KAG-800 | Disease & Symptoms (~800 diseases / 600 symptoms) | Kaggle (choongqianzheng and variants) | Other/unspecified | ~5,000 rows, 800+ diseases | No | NO — same canonical KB family | high | NO — same family, undocumented provenance |
| KAG-773 | Disease-Symptom (773 diseases / 377 symptoms; Mendeley "2023" 246k rows) | Kaggle dhivyeshrk; Mendeley DOI 10.17632/2cxccsxydc.1 | CC BY 4.0 (Mendeley) | ~246,000 rows | No — **artificially generated** | NO | high | NO — synthetic/generated canonical rows |
| DDX-001 | DDXPlus (1.3M patients, 49 pathologies, 110 symptoms) | Tchango et al., NeurIPS 2022; figshare | figshare/research | ~1.3M synthetic patients | Synthetic cohort | Contaminated (Synthea + proprietary KB) | ~5 | NO — synthetic, not real observations; categorical features/negative framing incompatible with lean binary 0/1 |
| BR-DENGUE | Brazil SINAN dengue/chikungunya/SARI notifications | PMC12819417 (2025), SINAN | CC BY | case-level records, binary symptom cols | YES (real case notifications) | YES | 1/41 (Dengue) | NO — single disease; class coverage ~2.4% |
| HCMC-DENGUE | OUCRU Ho Chi Minh City dengue cohort | PMC9992802, 1999–2021 | access-restricted | >12,000 real patients | YES (real cohort) | YES | 1/41 (Dengue) | NO — single disease + credentialed access |
| MIMIC-III | MIMIC-III clinical database | PhysioNet (credentialed DUA) | by-application | ~40k ICU admissions | YES | YES | n/a | NO — lacks symptom-presence matrix (per DDXPlus paper) |
| S2D-001 | symptoms2Disease (24 diseases / 1200 NLP texts) | Kaggle niyarrbarman / GitHub bimarshak7 | unspecified | 1,200 rows | No — paraphrased canonical KB text | NO (derivative of same family) | 24 | NO — paraphrase-derivative + free-text tokens → mapping inadequate |

## Verdict
- The **only genuinely independent, clinically-sourced candidate** (Columbia KB, COL-001) was analyzed in depth but is
  **license-pending (Phase 7G decision), aggregated association-count format, and has inadequate label/feature coverage**.
- All large public "disease-symptom" datasets are **the same canonical family** as SymbiPredict (mirror/leakage) or are
  **artificially generated**.
- Real patient datasets are **single-disease** (dengue) → class coverage far too small.
- **No suitable independent external dataset is obtainable** → outcome C (INSUFFICIENT_EXTERNAL_DATA).

## Note
No new downloads were performed in Phase 7K. Web-search findings were documented from their public metadata; the three
previously-acquired Phase 7G files were re-used for analysis only.