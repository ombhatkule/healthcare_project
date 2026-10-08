# Phase 7H.1 — Symptom Synonym Review

Review gate for the symptom-synonym candidates surfaced by Phase 7H
(`analysis/symptom_mapping_review.json`, summary: 20 EXACT / 3 HIGH_CONFIDENCE / 8 POSSIBLE / 101 NO_MATCH).

**Key rule:** No mapping is auto-applied. This project does **not** yet have verified clinician sign-off, so no mapping is approved for application by this phase. New vocabulary (101 symptoms) is primary; the 132-feature vocabulary is unchanged in the Phase 7H cleaned datasets.

## High-confidence candidates

| Source symptom | Proposed canonical | Reason for proposed equivalence | Exact evidence available in Phase 7H | Confidence | Risk of semantic mismatch | Action | Approval status |
|---|---|---|---|---|---|---|---|
| `stomach_pain` | `abdominal_pain` | Common lexical synonym; `abdominal_pain` already present in dataset, `stomach_pain` is not; medical usage treats stomach pain as upper/mid abdominal pain in lay terms | Phase 7H mapping lists both candidate symptoms; `abdominal_pain` is an EXACT match to current vocab; `stomach_pain` replacement is deterministic (no data change) | High lexical/semantic candidate | Requires clinician confirmation; "stomach" ≠ all abdominal regions (e.g., lower abdomen) | Document; keep separate in cleaned data | **PENDING_CLINICIAN_REVIEW** |
| `belly_pain` | `abdominal_pain` | Lay synonym of abdominal pain | Phase 7H mapping lists `belly_pain` as HIGH_CONFIDENCE_SYNONYM → `abdominal_pain` | High lexical candidate | Colloquial term; minor regional/idiomatic variation in what "belly" covers | Document; keep separate in cleaned data | **PENDING_CLINICIAN_REVIEW** |
| `breathlessness` | `shortness_of_breath` | Direct synonym of dyspnea/shortness of breath | Phase 7H mapping lists `breathlessness` as HIGH_CONFIDENCE_SYNONYM | High lexical candidate | Minor; both describe dyspnea | Document; keep separate in cleaned data | **PENDING_CLINICIAN_REVIEW** |

## Possible candidates (8 — manual confirmation required)

| Source symptom | Proposed canonical | Reason for proposed equivalence | Exact evidence available in Phase 7H | Confidence | Risk of semantic mismatch | Action | Approval status |
|---|---|---|---|---|---|---|---|
| `weight_loss` | `unintentional_weight_loss` | Phase 7H loose match to `unintentional_weight_loss` / `weight_loss_unintentional` in current vocab | POSSIBLE_SYNONYM in Phase 7H mapping | Medium | Intent may or may not be implied | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |
| `high_fever` | `fever` | Subset/specifier of fever | POSSIBLE_SYNONYM; current vocab has `fever` | Medium | Severity specifier (high vs mild) loses information | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |
| `mild_fever` | `fever` | Subset/specifier of fever | POSSIBLE_SYNONYM; current vocab has `fever` | Medium | Severity specifier lost | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |
| `back_pain` | `low_back_pain` | Overlapping region | POSSIBLE_SYNONYM; current vocab has `low_back_pain` | Low-Medium | `back_pain` broader than `low_back_pain` (could include thoracic/cervical) | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |
| `congestion` | `nasal_congestion` | Narrowing of location | POSSIBLE_SYNONYM; current vocab has `nasal_congestion` | Medium | Congestion could be chest/sinus; ambiguous | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |
| `cramps` | `muscle_cramps_symptom` | Possible muscle cramps | POSSIBLE_SYNONYM | Low-Medium | Cramps could be abdominal/menstrual; ambiguous | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |
| `bruising` | `easy_bruising` | Overlap | POSSIBLE_SYNONYM | Low-Medium | Severity/manner not equivalent | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |
| `drying_and_tingling_lips` | `tingling` | Partial overlap | POSSIBLE_SYNONYM | Low | Compound feature vs single symptom; not equivalent | Document; keep separate | **PENDING_CLINICIAN_REVIEW** |

## Status
- **High-confidence:** all 3 **PENDING_CLINICIAN_REVIEW** (technically high-confidence lexical/semantic candidates, NOT clinical approval).
- **Possible:** all 8 **PENDING_CLINICIAN_REVIEW** (none established as identical without medical ambiguity).
- **NOT applied** to `backend/ml/phase7h/cleaned/*` (unchanged per phase rules). If an experimental normalized copy is ever built, it must live under `backend/ml/phase7h1/outputs/` labeled **EXPERIMENTAL — NOT APPROVED FOR TRAINING**.
- **Clinician sign-off verified: NO.**

---
*No mapping was merged; no clinician approval was invented.*