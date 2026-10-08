# Phase 7G — Dataset Search & Acquisition Report

**Date:** 2026-09-09/10
**Goal:** Find, verify, and acquire a substantially better disease-symptom dataset per Phase 7E/7F failure analysis — acquisition/validation only (no training, no deployment, no production changes).
**Decision:** **B. CONDITIONALLY APPROVED — MANUAL REVIEW REQUIRED** for **SymbiPredict (SDPD)** — the documented, licensed, empirically-superior primary candidate.

---

## 1. Context

- Phase 7E/7F established the current dataset is fundamentally unsuitable: 46 classes, 174 symptoms, imbalance 21,295:1, 9 classes < 10, mean MI 0.016, avg cosine separability 0.694, unknown provenance. MUST-HAVEs: adequate support (≥50–100/class), meaningful feature–label relationships, documented provenance with DOI/citation, clear target, reproducible, licensed.
- Phase 7F decision: **OPTION 4** — stop disease classification until better data. Phase 7G = search, verify, acquire only.

## 2. Search & registry

- **11 candidates investigated** (`candidate_registry.json`): Mendeley/DOI-indexed and public datasets.
- **3 active candidates acquired** for full local verification (stored under `backend/ml/phase7g/acquired/`).
- Rejected/excluded: elastic mirrors/derivations of the same community family (Milton/Yuan/rjanice/PedroAcacia/dianap8/sublimation/Macgyver/Bedmutha/marslinoedward/uom190346a), explicitly-synthetic sets (Mendeley 2cxccsxydc, DDXPlus), 12,090-class infectious-domain mismatch (Zenodo), PhysioNet MIMIC-SR-ICD11 (credentialed access, not bypassed), and Al Shafi et al. (reference-only evidence set, 85X172 matrix, 1 row per disease → insufficient).

## 3. Acquired candidates (with SHA-256 verification)

| File | Dataset | Character | Decision |
|---|---|---|---|
| `symbipredict_2022.csv` (1,382,907 B, SHA256 `9834c90d…8e9e1b`) | **SymbiPredict / SDPD** — Mendeley DOI `10.17632/dv5z3v2xyd.1` (2024-04-02), symptoms from medical literature/clinical observation/expert consensus | 4,961 rows binary matrix, **132** symptom features + `prognosis`, **41 classes × 121** (imbalance 1.0:1), 0 classes < 100, 0 missing, **CC BY 4.0** | **B — CONDITIONALLY APPROVED (PRIMARY)** |
| `columbia_disease_symptom_kb.csv` (124,473 B, SHA256 `51b81b89…a73a17`) | **Columbia University DBMI Disease-Symptom Knowledge DB** — MedLEE extraction from 25,074 NYP 2004 discharge summaries, UMLS-coded, AMIA 2008 (PMC2656103), ~90% recall/~92% precision | 1,858 associations, **134 diseases, 401 symptoms**, doc counts 42–3,363; no explicit license | ALTERNATIVE — CONDITIONALLY APPROVED, license review required |
| `kaushil268_disease_prediction.csv` (632,202 B, SHA256 `ebbd391c…19c9618`) | Kaushil268 (Kaggle mirror, Apache 2.0) — same 41-class/131-symptom family as SymbiPredict, undocumented | 4,920 rows long-format, 53% missing, 94% duplicate rows | REJECTED as primary (redundant; superseded by documented SymbiPredict) |

## 4. Local inspection & profiling

- SymbiPredict: 4,961×133, 0 missing, 4,657 duplicate rows (94%) with 304 unique row patterns; measured **mean MI 0.178**, **MI>0.01 in 131/132 features**, **avg cosine separability 0.107**.
- Columbia KB: 1,858×3, 0 missing/duplicates; associations/disease min 3 / median 13 / max 28.
- Kaushil268: 4,920×18, 53% missing, 4,616 duplicate rows.

## 5. Quality screen (current vs candidate)

| Dimension (Phase 7E/7F root cause) | Current | SymbiPredict | Verdict |
|---|---|---|---|
| Class support (<100) | 23 classes | **0** | far better |
| Class imbalance | 21,295:1 | **1.0:1** | far better |
| Mean mutual information | 0.016 | **0.178** | ~10.8× |
| Features MI > 0.01 | 113/174 | **131/132** | near-complete |
| Avg cosine separability | 0.694 | **0.107** | much more separable |
| Provenance + license | Unknown | **DOI + peer-reviewed + CC BY 4.0** | documented |

**SymbiPredict is materially better on every Phase 7E/7F failure dimension → decision B.**

## 6. Symptom-vocabulary mapping

- SymbiPredict: 17 exact matches vs current 174-vocab, 11 possible/synonyms (3 high-confidence e.g. `stomach_pain/belly_pain→abdominal_pain`, `breathlessness→shortness_of_breath`), 104 new vocabulary, 0 non-symptom → **new 132-feature vocabulary required; current `symptom_columns.joblib` NOT reusable**.
- Columbia KB: 33/401 exact, ~60–80 possible, ~250 new, ~10 non-symptom at high threshold.

## 7. Future integration (conceptual — nothing implemented)

- Adopt Phase 7F's dynamic `/api/symptoms` + stable `{disease, top_conditions[], confidence, disclaimer}` contract.
- **Primary path (SymbiPredict):** supervised 132-feature binary classifier, unchanged API shape; Phase 7H builds cleaned candidate.
- **Alternative path (Columbia KB, if licensed):** association-weighted scoring with UMLS id vocabulary; grouped/searchable 401-symptom selector in Flutter.

## 8. Production safety (re-verified at reconciliation)

All three production files **unchanged** (SHA-256 matches Phase 7E/7F):
- `models/disease_model.joblib` = `f772b3b8…` (609,303,049 B)
- `models/symptom_columns.joblib` = `9fea903c…` (4,761 B)
- `data/disease_dataset_cleaned_v2.csv` = `5912fa31…` (36,235,985 B)

Flask, Flutter, API: untouched. No training, no deployment; Phase 8 / Phase 7H not started.

## 9. Open items / manual review (blockers to approval A)

1. **SymbiPredict provenance characterization:** community-curated symptom→disease associations (medical literature + clinical observation + expert consensus), **not** real patient records — confirm acceptable for intended exploratory/educational purpose (Phase 7F OPTION 4 remains).
2. **SymbiPredict representation:** 94% duplicate rows → Phase 7H decides dedup vs association representation and train/test/eval impact.
3. **Synonyms:** confirm `stomach_pain/belly_pain→abdominal_pain`, `breathlessness→shortness_of_breath`.
4. **Columbia KB license:** no explicit license → confirm with `friedman@dbmi.columbia.edu` if it is to be the alternative.
5. **No model approval from metrics alone:** Phase 7H must benchmark separability + train/test on a cleaned candidate.

## 10. Recommendation for next phase

> **PHASE 7H — DATASET PREPROCESSING & VALIDATION** — create a separate cleaned candidate under `backend/ml/phase7h/` (production untouched): normalize SymbiPredict column names, resolve duplicate representation, confirm synonyms, validate labels/features/missing/duplicates/class support/separability, establish train/test strategy. Columbia KB as alternative pending license confirmation.

## Deliverables (all under `backend/ml/phase7g/`)

`phase7g_baseline.md`, `candidate_registry.json`, `shortlist.md`, `candidate_decision.md`, `acquired_dataset_profile.json/.md`, `acquisition_record.json`, `current_vs_candidate.md`, `current_vs_candidate_data.json`, `symptom_mapping_analysis.md`, `symptom_mapping_data.json`, `future_integration_plan.md`, `production_safety_check.json`, `phase7g_report.md`, `phase7g_inspect.py`, `phase7g_compare.py`, `phase7g_mapping.py`, plus `acquired/*.csv` (symbipredict_2022, columbia_disease_symptom_kb, kaushil268_disease_prediction).