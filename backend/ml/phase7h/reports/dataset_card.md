# Phase 7H — Dataset Card: SymbiPredict (SDPD)

## 1. Dataset identity
SymbiPredict / **Symptom-Disease Prediction Dataset (SDPD)** — candidate training dataset for the exploratory disease-prediction prototype (Phase 7I).

## 2. Source
Mendeley Data, "SymbiPredict", published 2024-04-02, version 1, contributor JayTucker.

## 3. DOI
`10.17632/dv5z3v2xyd.1` (record: https://data.mendeley.com/datasets/dv5z3v2xyd/1)

## 4. License
**CC BY 4.0** (clear, re-usable with attribution).

## 5. Intended use
- Educational demonstration
- Exploratory ML research / prototype classification
- NOT a medical device; NOT for clinical diagnosis or real-world patient performance claims.

## 6. Limitations
- Community-curated symptom→disease associations (medical literature, clinical observations, expert consensus) — **NOT real patient records** and **NOT clinically validated**.
- No patient-level medical outcome data; no prevalence/severity information.
- Repeated rows are formatting/association repeats, not independent patients.
- 304 unique association vectors total is a small sample; evaluation uncertainty expected.

## 7. Feature vocabulary
- 132 binary symptom features (0/1), normalized to API-safe identifiers (`lowercase`, spaces/hyphens/punctuation→`_`, collapse, strip). Current-vocab mapping: **20 EXACT**, **3 HIGH_CONFIDENCE_SYNONYM**, **8 POSSIBLE_SYNONYM**, **101 NO_MATCH** (new vocabulary).
- Duplicate-header artifact: `fluid_overload` (all-zero constant) vs `fluid_overload_1` (real signal) — kept distinct; Phase 7I may drop `fluid_overload` with a documented (zero-variance) reason.
- 1 constant feature observed (`fluid_overload`); 101 features with prevalence < 5%; **no feature removed in Phase 7H**.

## 8. Target labels
- `prognosis`: **41 disease classes**, normalized (trim/collapse whitespace only). 0 collisions; none ambiguous at formatting level. Synonym-merging (e.g., Hepatitis sub-types) is NOT done — source docs do not justify it; clinician manual review would be needed.

## 9. Original row count
**4,961** rows × 133 columns (132 symptom + `prognosis`).

## 10. Unique vector count
**304** unique symptom vectors (6.13% of rows).

## 11. Duplicate statistics
- Exact duplicate full rows: **4,657 (93.9%)**.
- Duplicate vectors with SAME prognosis: 304; with DIFFERENT prognosis: **0**.
- Multiplicity distribution (#vectors × multiplicity): {216×6, 45×12, 2×18, 6×67, 19×73, 12×79, 2×85, 2×91} (sum = 304; Σ(rows) = 4,961).
- Per-disease: each class has 121 rows = 5–10 unique vectors with 111–116 repeat rows.

## 12. Contradictory vector statistics
**0 contradictory vectors** — every unique symptom vector maps to exactly one disease. 0 affected rows/diseases. (`analysis/contradictory_patterns.json`)

## 13. Class distribution
- 41 classes × 121 rows in the raw file (imbalance **1.0:1**, 0 classes < 100).
- Deduplicated association representation: 5–10 unique vectors per class (min=5, e.g., AIDS/Acne/Allergy…; max=10, e.g., Chickenpox/Dengue/Hepatitis D/Migraine), class imbalance **2.0:1** (5 vs 10) on association counts.

## 14. Feature quality
- All binary; 0 missing/NaN/inf/invalid values.
- Mean mutual information (raw, 4,961 rows): **0.17769**; **131/132** features MI > 0.01.
- 1 constant feature (`fluid_overload`); 101 near-zero-variance (prevalence < 5%).
- Per-feature detail: `validation/feature_analysis.json`.

## 15. Separability
- Raw (4,961): avg cosine **0.10668**, median 0.07873, min 0.0, max 0.82961.
- Dedup (304): avg cosine **0.10575** — deduplication does NOT materially change separability.
- Most similar: Hepatitis D ↔ Hepatitis E (0.830); least similar: Fungal Infection ↔ several (0.0).
- These are structural profile similarities, NOT clinical validity.

## 16. Leakage risks
- 100% of unique vectors appear multiple times; a naive random row split puts identical vectors in train and test (99.9% of rows are repeats).
- Mitigation: **grouped split by unique symptom vector** on the deduplicated 304-row representation; repeated grouped CV; report per-class support. (`analysis/leakage_analysis.json`, `reports/train_test_strategy.md`)

## 17. Cleaning transformations
- Column-name normalization (0 collisions), label whitespace normalization (0 collisions), no value changes, no synonym auto-application, no rows deleted in the "cleaned" file.
- `cleaned/symbipredict_cleaned.csv` = identical information to raw with normalized names.
- `cleaned/symbipredict_deduplicated.csv` = 304 unique vector+disease association rows.

## 18. Deduplication decision
**Representation C adopted** (`unique vector+disease association rows`, 304 rows). Rows in the raw file are legitimate association-format repetition, NOT independent patient examples, so the 304-row association table is the honest information-bearing representation for Phase 7I. (`analysis/representations.json`)

## 19. Recommended Phase 7I representation
`backend/ml/phase7h/cleaned/symbipredict_deduplicated.csv` (304 rows, 132 features, `prognosis` target, 41 classes).

## 20. Recommended train/test strategy
- Grouped split by unique symptom vector (each vector in exactly one fold).
- Repeated 5-fold grouped CV (×10) with macro-averaged metrics + per-class support.
- No random row-level splitting of the 4,961-row file.

## 21. Known unresolved issues
1. Provenance characterization sign-off (community-curated vs patient data) pending manual review.
2. 3 HIGH_CONFIDENCE synonyms need clinician blessing for product-facing labels (`stomach_pain`, `belly_pain` → `abdominal_pain`; `breathlessness` → `shortness_of_breath`).
3. 8 POSSIBLE synonyms require confirmation.
4. `fluid_overload` constant column — Phase 7I removal decision (documented reason: zero variance).
5. Small association-sample size (304) — expects high evaluation variance.
6. No clinical validity source evidence — diagnostic claims are not supported.

---
**Phase 7H status:** structurally valid candidate, recommended representation = association rows (304), recommendation to **Phase 7I = PROCEED with representation C + grouped split**, conditional on manual review of unresolved items 1–2.