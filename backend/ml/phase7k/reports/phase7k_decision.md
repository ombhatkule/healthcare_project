# Phase 7K — Decision

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Outcome: C — INSUFFICIENT_EXTERNAL_DATA

## Decision logic (Phase 7K §15)
Chosen exactly one: **C — INSUFFICIENT_EXTERNAL_DATA**

Applicable criteria (all satisfied):
- **No suitable independent dataset found** — the only independent, clinically-sourced candidate (Columbia KB) is
  license-pending (Phase 7G decision) and association-count format.
- **Coverage too low** — feature mapping 6.05% of unique symptoms (≤57% per-disease evidence, most ≤30%; one disease 0%);
  label coverage 19.5% automatic; 15.3% of the 131-feature space representable.
- **Class overlap too small** — 8 EXACT / 8 HIGH / 3 POSSIBLE / 22 NO_MATCH of 41.
- **Feature mapping inadequate** — 373/397 symptoms unmapped; no clinician review available for HIGH/POSSIBLE mappings.
- Real-patient candidates (Brazil SINAN, HCMC dengue) are single-disease; large disease-symptom sets mirror the
  SymbiPredict family (leakage risk) or are synthetic/generated.

Not chosen (explicit reasons):
- **A — EXTERNAL_GENERALIZATION_SUPPORTED:** impossible — no valid external evaluation ran.
- **B — EXTERNAL_GENERALIZATION_NOT_SUPPORTED:** also requires a *valid* evaluation; coverage collapse would confound
  any such result. Not claimed.
- **D — EXTERNAL_VALIDATION_BLOCKED:** partially applicable (Columbia license pending) but the dominant reason is the
  absence of any obtainable, adequately-covered independent dataset (a §15 "insufficient data" condition); the phase
  did not discover leakage or malformed data. C is the correct classification.

## Mandatory interpretation (§16)
Phase 7I ≈ 1.0 Macro F1 (grouped CV on canonical, noiseless associations). Phase 7K produced NO external metric;
therefore nothing is called a failure. The correct statement is:

**The Phase 7I ceiling performance did not demonstrate — and could not be tested for — external generalization,
because no credible, adequately-covered independent dataset was obtainable.**

## Untested-gap transparency
Whether the Phase 7I model generalizes to real patient observations (symptom noise, missingness, overlapping clusters)
remains **untested**. Phase 7K does not support, refute, or estimate that question. Recommend (as future work) a
credentialed, adequately-covered real clinical cohort (e.g., MIMIC-derived symptom matrix or a multi-disease
outpatient cohort) once licensing allows.

## Clinical/medical status
- Clinical validation status: **NOT VALIDATED** (no clinician-defined gold standard, no real patient cohort).
- Models: **experimental only**; Phase 7I best representative artifact is NOT PRODUCTION.

## Production safety
PASS — all production hashes match baseline (see `evidence/production_final_hashes.txt`).

## Phase 7J
**NOT READY** — external generalization remains unverified and no production integration is approved.