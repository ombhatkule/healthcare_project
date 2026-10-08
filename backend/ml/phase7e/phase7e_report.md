# Phase 7E â€” Dataset Validation & Replacement Strategy Report

**Date:** 2026-09-08
**Status:** COMPLETE (analysis & decision only â€” no production changes)

---

## 1. Executive Summary

Phase 7E investigated whether the current dataset (`disease_dataset_cleaned_v2.csv`,
46 diseases, 174 symptoms, 100,000 rows) is fundamentally unsuitable for reliable
multiclass disease prediction, and whether a better replacement exists.

**Findings:**
- The current dataset is **fundamentally unsuitable** for reliable 46-class prediction
  (structural analysis below).
- A web search identified 8 candidate datasets, but **none was directly verified**.
- No candidate clearly satisfies the Must-Have requirements.
- **Recommendation: D â€” No suitable replacement dataset found. Do not proceed without better data.**

---

## 2. Current Dataset Assessment

**Assessment: FUNDAMENTALLY UNSUITABLE for the intended 46-class prediction task.**

Evidence:
- Best macro F1 across all experimental models = ~0.19 (Logistic Regression).
- Phase 7D showed no model achieves strong performance.
- Deep analysis in Phase 7E confirms structural deficiencies (below).

---

## 3. Main Dataset Problems

### 3.1 Class Imbalance
- Imbalance ratio: **21,295:1** (largest vs smallest class).
- Top 5 classes hold **55.41%** of all 100,000 rows.
- Models tend to collapse predictions toward majority classes.

### 3.2 Extremely Rare Classes
- **7 classes** have fewer than 5 total samples (critically insufficient).
- **2 classes** have 5â€“9 samples (extremely insufficient).
- Combined: **9 classes (19.6%)** cannot be reliably trained OR evaluated.
- 42 classes appear in the test set; several have 0â€“3 test samples.

### 3.3 Feature Discriminative Strength (WEAK)
- Mean mutual information across 174 features: **0.017**.
- Only 116/174 features exceed MI > 0.01; top feature MI â‰ˆ 0.054.
- Assessment: **only a few symptoms provide useful discrimination** (weak/overlapping signals).

### 3.4 Disease Separability (WEAK)
- Average pairwise cosine similarity between disease symptom profiles: **0.694**.
- Most similar pair: Generalized_Anxiety_Disorder â†” Pneumonia = **0.960**.
- Many disease profiles heavily overlap; difficult to distinguish.

### 3.5 Sparse-Input Behavior (UNRELIABLE)
- Empty vector predicts **Migraine** with only ~9.5% confidence.
- Single-symptom input also predicts Migraine (~11% confidence).
- Migraine is over-represented 8.6x vs its true prevalence (RF balanced).
- Real user inputs (typical 1â€“5 symptoms) produce low-confidence, unstable predictions.

---

## 4. Dataset Suitability Scorecard

| Category | Rating |
|----------|--------|
| Class Support Adequacy | **Critical problem** |
| Class Balance | **Critical problem** |
| Feature Discriminative Strength | **Weak** |
| Disease Separability | **Weak** |
| Rare-Class Evaluability | **Critical problem** |
| Consistency of Symptom Patterns | **Weak** |
| Suitability for Sparse User Inputs | **Weak** |
| Suitability for 46-Class Classification | **Critical problem** |
| Reproducibility/Documentation | **Unknown** |
| Medical/Clinical Provenance | **Unknown** |

Summary: 0 Strong, 0 Acceptable, 5 Weak, 4 Critical, 2 Unknown.
**Overall: Fundamentally unsuitable for reliable 46-class prediction.**
See `current_dataset_scorecard.{json,md}` for full evidence.

---

## 5. Candidate Dataset Search

Sources investigated (all via web documentation â€” **NONE downloaded or directly verified**):

| # | Candidate | Source |
|---|-----------|--------|
| 1 | Disease Prediction Using ML (Kaushil268) | Kaggle |
| 2 | Symptom2Disease (Niyarr Barman) | Kaggle |
| 3 | Community Healthcare MultiSymptoms-Disease | Kaggle |
| 4 | Disease Prediction Dataset (Ayush Nautiyal) | IEEE DataPort |
| 5 | Early Stage Diabetes Risk Prediction | UCI (ID 529) |
| 6 | Disease and Symptoms dataset (AZZAZY) | Kaggle |
| 7 | Symptom to Disease Descriptions (820_Cleaned) | Kaggle |
| 8 | CDC Diabetes Health Indicators | UCI (ID 891) |

**Verified candidates:** None (all remote; direct inspection deferred per instructions).
**Requiring manual verification:** Most.
**Rejected candidates:** Most (see comparison).

---

## 6. Candidate Comparison

See `candidate_dataset_comparison.{json,md}` for full scores. Top summaries:

- **UCI Early Stage Diabetes (ID 529):** Best provenance (doctor-approved questionnaires, published paper),
  good balance, but only 2 classes (diabetes only) â€” not a general disease-symptom dataset.
- **Kaushil268 (42 diseases / 132 symptoms):** Format matches, but ~5000 rows total, unverified provenance.
- **Community Healthcare (174/46):** Matches current structure **but is explicitly "simulated"** â€”
  likely the same synthetic-style data already in use; no real improvement.
- **IEEE (391 diseases):** Broad but likely tiny per-class support; student-assembled.
- **Others:** text-based (NLP) or too few classes / too many classes.

---

## 7. Best Candidate

**No single "best" candidate emerged from documentation alone.**

The strongest provenance was UCI Early Stage Diabetes (medically sourced, doctor-approved),
but it only supports a 2-class diabetes problem. The only feature-matching candidate
(Community Healthcare 174/46) is simulated and likely the same synthetic source as current
data â€” adopting it would not fix the underlying problems.

---

## 8. Compatibility Findings

- **Backend feature vocabulary** would change for every candidate except the (likely-same) Community Healthcare.
- **`/api/symptoms`** would need to expose the new vocabulary.
- **Flutter symptom selection** (currently 16 hard-coded) must become dynamic / API-driven.
- **Existing API response format** (`{disease, confidence, ...}`) is stable and would survive a model change.
- The most important future-proofing change is **dynamic symptom vocabulary loading**.

---

## 9. Final Recommendation

> **D. NO SUITABLE REPLACEMENT DATASET FOUND â€” DO NOT PROCEED WITHOUT BETTER DATA**

(Secondary viable near-term path: B. Keep current dataset but reduce/restructure the problem,
as a bridge while pursuing better data.)

---

## 10. Recommended Next Phase

> **Phase 7F â€” Prediction Problem Restructuring + Dynamic Symptom Vocabulary Design**

Rationale: No verified better dataset exists. The most constructive near-term step is to
restructure the 46-class problem into a defensible, better-supported form (e.g., fewer
high-support classes, or redesigned symptom sets) and design a dynamic symptom vocabulary
so the Flutter/Flask/model stack can absorb better data/models in the future.

(Do not execute Phase 7F in this run.)

---

## 11. Files Created (phase7e/)

- `phase7e_baseline_check.json`
- `step2_dataset_analysis.json`
- `current_dataset_scorecard.json`
- `current_dataset_scorecard.md`
- `dataset_requirements.md`
- `candidate_dataset_comparison.json`
- `candidate_dataset_comparison.md`
- `compatibility_analysis.md`
- `small_sample_inspection.json`
- `decision_matrix.md`
- `production_safety_check.json`
- `phase7e_report.md`

---

## 12. Production Safety Confirmation

- `disease_model.joblib` â€” **UNCHANGED**
- `symptom_columns.joblib` â€” **UNCHANGED**
- `disease_dataset_cleaned_v2.csv` â€” **UNCHANGED**
- Flutter â€” **UNCHANGED**
- Flask â€” **UNCHANGED**
- No new production model trained/deployed.
- No candidate dataset replaced the current dataset.
- Phase 8 NOT started.
