# Future App Integration Plan

**Date:** 2026-09-09 (updated 2026-09-10)
**Phase:** 7G Step 13 — Conceptual compatibility only (nothing implemented)

> Candidate dataset → future preprocessing → future model → Flask → GET /api/symptoms → Flutter

---

## 1. Assumed target architecture (from Phase 7F Step 14)

- `GET /api/symptoms` returns the model's canonical symptom vocabulary (id + label), dynamically.
- `POST /api/predict` accepts a set of canonical symptom ids, returns `{disease, confidence, ...}`.
- Feature-order metadata (versioned `symptom_columns` equivalent) is loaded with the model.
- Flutter fetches symptoms dynamically instead of hard-coding 16.

---

## 2. Compatibility by candidate

### Candidate: SymbiPredict (SDPD) — **PRIMARY PATH**

| Question | Answer |
|----------|--------|
| Can symptoms be represented consistently? | Yes — **132 flat binary symptom features** (normalized column names) + prognosis target. |
| Dynamic vocabulary? | Yes — appropriate (132 symptoms; Flutter needs grouped/searchable selector). |
| `/api/predict` compat? | Yes — **unchanged supervised classifier contract**: input 132-dim binary vector, output `{disease, confidence}`. Same shape as today's model; only feature vocabulary + model weights change. |
| New schema? | No. |
| Flutter support? | Yes — 132 symptoms loadable via dynamic `/api/symptoms`; needs grouped selector (e.g., by body system) for usability. |
| Training data notes | 4961 rows, 41 classes × 121 — clean binary matrix, no missing, perfect balance; new `symptom_columns` reference needed (current 174-vocab `symptom_columns.joblib` NOT reusable). |

### Candidate: Columbia KB (association knowledge base) — ALTERNATIVE PATH

| Question | Answer |
|----------|--------|
| Can symptoms be represented consistently? | Yes — 401 UMLS-coded concepts map to a stable id+label vocabulary. |
| Does dynamic symptom vocabulary remain appropriate? | Yes — required. 401 symptoms is too many to hard-code. |
| Can `/api/predict` response remain compatible? | Functionally yes, but the prediction formulation changes: from supervised multi-class classifier to **association-weighted diagnostic scoring** (disease← documented symptom weights). Output can still be `{disease, confidence}`. |
| Would a new API schema be needed? | No new endpoint; internal payload unchanged (ids in, top disease + confidence out). Model layer changes only. |
| Could Flutter eventually support the vocabulary? | Yes — with dynamic symptom loading and grouped/categorized selector (401 concepts need search + group filters). |

Design note: an association-weighted model can be re-expressed as a software decision function; the artifact could still ship as a versioned model/joblib to keep the Flask interface stable.

### Kaushil268 (long-format mirror) — NOT ADOPTED

Same 41-class family as SymbiPredict but undocumented + 93.8% duplicates; superseded by the documented SymbiPredict. No integration path.

---

## 3. Recommendation for the target pipeline

1. **Adopt the dynamic symptom vocabulary design** from `phase7f/dynamic_symptom_vocabulary_design.md` regardless of candidate. Flutter must stop hard-coding symptoms.
2. **Keep the response contract stable:** `{disease, top_conditions[], confidence, disclaimer}`.
3. **SymbiPredict path (primary — approved B):** Phase 7H builds a cleaned candidate (normalize column names, resolve representation/dedup, confirm 3 synonyms) → supervised classifier (41 classes × 132 binary features) → ship new `symptom_columns` + model behind the same Flask endpoints; add grouped symptom selector in Flutter.
4. **Columbia KB path (if licensed):** association-weighted scoring with UMLS id vocabulary; include a symptom-category grouping in `/api/symptoms` for a 401-item list; keep model swapped behind the same Flask endpoint.
5. **Non-goals this phase:** no Flask/Flutter/API changes were made.

## 4. Risks / Open items

- **Licensing:** Columbia KB has no explicit license — confirm with `friedman@dbmi.columbia.edu` before any production use. SymbiPredict is CC BY 4.0 (cleared).
- **SymbiPredict representation:** 94% duplicate rows — Phase 7H must decide dedup vs association representation and its effect on train/test/eval; no model approval from metrics alone.
- **Scope:** 401-symptom alternative is a different UX; requires search + grouping in Flutter (132-symptom primary also benefits from grouping).
- **Patient-row gap (Columbia only):** the KB is not patient-level; prevalence-weighted scoring would need documented priors.