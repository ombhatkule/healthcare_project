# Phase 7H.1 Manual Review Record

**Date:** 2026-09-10
**Phase:** 7H.1 — Manual Review, Provenance Gate & Feature/Synonym Sign-off
**Binding rule honored:** no training, no deployment, no production modification, no invented clinician approval.

## 1. Purpose
Complete the manual-review/sign-off gate required by the Phase 7H decision B (conditional approval): provenance documentation review, synonym review, constant-feature review for `fluid_overload`, small-sample limitation documentation, and a formal GO/CONDITIONAL/BLOCKED gate for Phase 7I.

## 2. Dataset Under Review
SymbiPredict / Symptom-Disease Prediction Dataset (SDPD)
- DOI `10.17632/dv5z3v2xyd.1`, license CC BY 4.0
- 4,961 rows; 132 binary symptom features; 41 disease classes; 0 missing/invalid; 4,657 duplicate rows; 304 unique symptom vectors; 0 contradictory vectors
- Recommended representation: **C — 304 unique vector+association rows**
  `backend/ml/phase7h/cleaned/symbipredict_deduplicated.csv`

## 3. Provenance Review
Status: **CONDITIONAL**
Evidence: documented Mendeley record + DOI + CC BY 4.0; description states symptoms sourced from medical literature, clinical observations, expert consensus. No patient-cohort documentation, clinical validation, consent, or institutional endorsement found.
Conclusion: *community-curated symptom-disease association dataset; not established as a clinical patient cohort; provenance verification limited to documented source and metadata.*

## 4. Synonym Review

### High-confidence candidates
| Source | Canonical | Status | Reason |
|---|---|---|---|
| `stomach_pain` | `abdominal_pain` | PENDING_CLINICIAN_REVIEW | High-confidence lexical candidate; no clinician sign-off available |
| `belly_pain` | `abdominal_pain` | PENDING_CLINICIAN_REVIEW | Lay synonym; needs clinician blessing |
| `breathlessness` | `shortness_of_breath` | PENDING_CLINICIAN_REVIEW | Direct synonym; needs clinician blessing |

### Possible candidates
| Source | Canonical | Status | Reason |
|---|---|---|---|
| `weight_loss` | `unintentional_weight_loss` | PENDING_CLINICIAN_REVIEW | Intent ambiguity |
| `high_fever` | `fever` | PENDING_CLINICIAN_REVIEW | Loss of severity specifier |
| `mild_fever` | `fever` | PENDING_CLINICIAN_REVIEW | Loss of severity specifier |
| `back_pain` | `low_back_pain` | PENDING_CLINICIAN_REVIEW | Region mismatch possible |
| `congestion` | `nasal_congestion` | PENDING_CLINICIAN_REVIEW | Location ambiguous |
| `cramps` | `muscle_cramps_symptom` | PENDING_CLINICIAN_REVIEW | Type ambiguous |
| `bruising` | `easy_bruising` | PENDING_CLINICIAN_REVIEW | Manner mismatch |
| `drying_and_tingling_lips` | `tingling` | PENDING_CLINICIAN_REVIEW | Compound ≠ single symptom |

No synonyms applied to `backend/ml/phase7h/cleaned/*`.

## 5. Constant Feature Review
Feature: `fluid_overload`
Decision: **REMOVE_CONSTANT_FEATURE (documented for Phase 7I)**
Evidence: all-zero constant column; duplicate-header naming (`fluid_overload` / `fluid_overload.1`); twin `fluid_overload_1` carries the signal (115 positives, Alcoholic Hepatitis). Removal deferred to Phase 7I preprocessing with this documented reason; cleaned files untouched in this phase.

## 6. Dataset Representation
Recommended: **Representation C** — 304 unique symptom-vector/disease associations.
Reason: rows in the raw file are legitimate association-format repetition, not independent patients; 304 association rows are the honest information-bearing unit.

## 7. Leakage Control
Required: **grouped split by unique symptom vector** (each vector in exactly one fold); repeated grouped CV; macro metrics + per-class support. Naive random row-split of the 4,961-row file is prohibited (identical vectors leak across folds).

## 8. Small-Sample Limitation
Representation C is only **304 associations across 41 diseases (5–10 unique vectors per class)**. This is NOT 4,961 independent patients. Class balance improves and leakage is controllable, but independent sample size is small, evaluation uncertainty is high, and strong benchmark metrics would NOT establish clinical validity.

## 9. Human/Clinical Review Requirements
**No verified clinician sign-off is present in the available project evidence.** All synonym mappings remain PENDING_CLINICIAN_REVIEW. This phase does not fabricate clinician approval.

## 10. Final Gate
**CONDITIONAL_GO_TO_7I**
Rationale: dataset is acceptable for a **non-clinical research/educational evaluation**; provenance is documented (conditional), feature decision documented, synonym handling documented, grouped split preserved, Representation C reproducible. Remaining limitations (provenance characterization, 3 high-confidence + 8 possible synonym confirmations, small-sample uncertainty) are explicitly carried forward into Phase 7I, and any Phase 7I experiment must be labeled:
**"Non-clinical research/educational evaluation; not clinically validated."**