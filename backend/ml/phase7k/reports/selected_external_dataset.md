# Phase 7K — Selected External Dataset

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Selection
No dataset was **selected for external evaluation**. No external evaluation was performed.

The **primary conditional candidate** (analyzed only, in depth) is:

**Columbia University Disease-Symptom Knowledge Database**

- Local file: `backend/ml/phase7g/acquired/columbia_disease_symptom_kb.csv`
- SHA-256: `51B81B8999B072768BB0692376BE1983F15B59A77A8EB5C95AF276FCBFA73A17`
- Source: Columbia University DBMI (Prof. Carol Friedman), MedLEE NLP extraction from 25,074 New York-Presbyterian 2004 discharge summaries; UMLS-coded; AMIA 2008 (PMC2656103).
- Size: 1,858 rows (disease → symptom associations with occurrence counts), 134 diseases, 397 unique symptoms.
- License: **UNKNOWN / pending manual review** (Phase 7G decision: conditional candidate; contact friedman@dbmi.columbia.edu).

## Why it could not be used for evaluation
1. **License unclear** — cannot be treated as licensed validation data without explicit permission.
2. **Not case-level** — observations are aggregated disease→symptom association counts, not patient records; the Phase 7K objective prefers patient/case-level rows.
3. **Label coverage insufficient** — only 8 of 41 Phase 7I labels are EXACT matches; 22/41 have NO_MATCH. Under Phase 7K rules, only EXACT mappings may be used automatically; HIGH_CONFIDENCE (8) and POSSIBLE (3) require clinician review that is unavailable.
4. **Feature coverage insufficient** — 373/397 Columbia symptoms (93.9%) have NO_MATCH against the 131-feature Phase 7I vocabulary (14 EXACT, +10 high-confidence). Even the 8 EXACT-label diseases would retain only 0–57% of their symptom signal; 4 of 8 retain ≤30%, 1 retains 0%.
5. **Evaluation would be an artifact** — any constructed test vector would drop most of the external evidence; resulting metrics would measure mapping loss, not generalization. Per the Phase 7K "do not manufacture evidence" rule, no such evaluation was run.

## Rejected alternatives (summary)
- SymbiPredict / kaushil268 / other large disease→symptom sets — same canonical KB family (leakage, not independent).
- "Disease & Symptoms 2023" (246k rows) — artificially generated.
- DDXPlus — synthetic cohort (Synthea + KB), categorical features may encode "not present"; representation incompatible.
- Brazil SINAN / HCMC dengue — real patient data, but single disease (Dengue); class coverage ≈ 1/41.
- MIMIC-III — lacks a symptom-presence matrix; credentialed access.

## Decision
- Selected external dataset: **NONE (usable)**.
- Outcome: **C — INSUFFICIENT_EXTERNAL_DATA**.