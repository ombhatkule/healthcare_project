# Phase 7G — Candidate Decision

**Date:** 2026-09-09
**Candidate:** SymbiPredict / Symptom-Disease Prediction Dataset (SDPD)
**Local:** `backend/ml/phase7g/acquired/symbipredict_2022.csv`

## Decision: **B — CONDITIONALLY APPROVED — MANUAL REVIEW REQUIRED**

## Evidence

The candidate is **materially better** than the current dataset on every dimension Phase 7E/7F identified as the root cause of failure:

| Dimension (Phase 7E/7F failure) | Current | SymbiPredict | Improvement |
|----------------------------------|---------|--------------|-------------|
| Class support | 23 classes < 100; min = 1 | 0 classes < 100; min = 121 | far better |
| Class imbalance | 21,295:1 | 1.0:1 (perfect) | far better |
| Feature discrimination (mean MI) | 0.016 | 0.178 | ~10.8x better |
| Features MI > 0.01 | 113/174 | 131/132 | nearly all discriminative |
| Disease separability (avg cosine) | 0.694 | 0.107 | much more separable |

This directly satisfies the MUST-HAVEs (adequate class support >= 50-100/class, meaningful feature-label relationships, documented provenance via DOI, clear target, reproducible, licensed CC BY 4.0) and SHOULD-HAVEs (balanced < 100:1, multiple symptom features, binary representation, documentation/publication).

## Why CONDITIONALLY approved (not unqualified A)

Manual review is required for the following before Phase 7H completes validation and any integration is considered:

1. **Provenance interpretation** — the dataset is documented via Mendeley DOI (2024) and cited in a peer-reviewed MDPI Electronics paper, with symptoms drawn from "medical literature, clinical observations, and expert consensus." It is, however, **community-curated symptom→disease associations, not real patient records**. Confirm this characterization is acceptable for the intended exploratory/educational purpose (Phase 7F decision OPTION 4 noted no validated medical tool; this remains true).
2. **Symptom-vocabulary mapping** — 3 possible synonym matches require manual confirmation (stomach_pain/belly_pain→abdominal_pain, breathlessness→shortness_of_breath); the other ~118 symptoms are unmapped and would form a new vocabulary.
3. **Duplicate handling** — 94% duplicate rows (structured format); Phase 7H must decide whether to keep the association-format representation or deduplicate, and how it affects train/test and evaluation.
4. **No model can be approved** based on data-quality metrics alone — Phase 7H must benchmark actual class separability and train/test behavior on the cleaned candidate.

## Recommendation for next phase

> **PHASE 7H — DATASET PREPROCESSING & VALIDATION** — create a separate cleaned candidate under `backend/ml/phase7h/` (never touching production), validate labels/features/missing/duplicates/class support/separability, establish a train/test strategy, and benchmark data quality — as the manual-review + validation step that this conditional approval requires.

---

## Not approved alternatives (for completeness)

- **MIMIC-SR-ICD11** — best real-clinical provenance but requires PhysioNet credentialed access (per rule, do not bypass). Requires manual authorization before consideration.
- **DDXPlus** — well-documented, open, but explicitly **synthetic** patient generation (does not resolve the synthetic-data concern).
- All others rejected (see `candidate_registry.json` and `shortlist.md`).
