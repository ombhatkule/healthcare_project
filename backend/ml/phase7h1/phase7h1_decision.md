# PHASE 7H.1 FINAL DECISION

**Date:** 2026-09-10

## Dataset
SymbiPredict / SDPD (DOI `10.17632/dv5z3v2xyd.1`, CC BY 4.0)

## Provenance
Status: **CONDITIONAL**
Evidence: documented Mendeley record + DOI + license; community-curated symptom-disease association dataset; **not established as a clinical patient cohort**; verification limited to documented source and metadata. Not suitable for clinical use.

## Synonym Review
Status: **PENDING_CLINICIAN_REVIEW (all 11 flagged mappings — 3 high-confidence + 8 possible)**
No synonyms were applied to cleaned data. No clinician sign-off verified in project evidence.

## Constant Feature
`fluid_overload` — **REMOVE_CONSTANT_FEATURE** (documented for Phase 7I: all-zero constant, duplicate-header naming artifact; twin `fluid_overload_1` carries the signal). Cleaned datasets unmodified in this phase.

## Recommended Dataset
Representation C:
`backend/ml/phase7h/cleaned/symbipredict_deduplicated.csv` (304 rows, 132 features, 41 classes)

## Evaluation Strategy
Grouped split by unique symptom vector (each vector in one fold); repeated grouped CV; macro metrics + per-class support; no naive row-splitting of the 4,961-row file.

## Major Limitation
**304 unique associations are NOT 4,961 independent patient samples.** 5–10 canonical vectors per class; high evaluation uncertainty; benchmark metrics do not imply clinical validity.

## Clinical Validation
**Clinical validation has NOT been established.** Any Phase 7I experiment is a non-clinical research/educational evaluation.

## Production Safety
All production files verified **unchanged**:
- `disease_model.joblib` — MATCH (`f772b3b8…d16a6`)
- `symptom_columns.joblib` — MATCH (`9fea903c…9932e`)
- `disease_dataset_cleaned_v2.csv` — MATCH (`5912fa31…2c2e50`)
Flask, Flutter, API — unmodified. No training, no deployment.

## Phase 7I Gate
**CONDITIONAL_GO_TO_7I**

Conditions carried into Phase 7I:
1. Label experiment **"Non-clinical research/educational evaluation; not clinically validated."**
2. Use Representation C + grouped-by-vector split.
3. Apply `fluid_overload` removal with documented zero-variance reason (131-feature vocabulary regenerated deterministically).
4. Keep all 11 synonym mappings PENDING_CLINICIAN_REVIEW; do not merge without approval.
5. Report per-class support and treat metrics as exploratory.

---
STOP — Phase 7H.1 complete. Do not enter Phase 7I.