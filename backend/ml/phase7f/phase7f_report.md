# Phase 7F — Prediction Problem Restructuring & Model Design Report

**Date:** 2026-09-08
**Status:** COMPLETE (experimental analysis & design only — no production changes)

---

## 1. Executive Summary

Phase 7F investigated whether restructuring the 46-class disease prediction problem improves
learnability, and designed a future model/symptom architecture. Key result: **removing
extremely rare classes improves measured macro metrics** (Macro F1 0.21 → 0.36, Balanced
Accuracy 0.27 → 0.41) BUT the remaining data is still weakly separable (avg similarity rises
to 0.82) and the dataset is synthetic-style with unknown provenance. Therefore
**restructuring helps numerically but does not make the data reliable for disease prediction.**

**Final strategy: OPTION 4 — Stop disease classification development until a better dataset is obtained.**

---

## 2. Current 46-Class Problem Assessment

- Input: 174 binary symptoms; Output: 46 disease classes.
- Extreme imbalance (21,295:1), 9 classes < 10 samples.
- Weak/overlapping features (mean MI ~0.017); sparse inputs => default-class (Migraine).
- **Not reliable for 46-class disease prediction.** See step2 problem definition.

---

## 3. Class Support Analysis (Step 3)

| Tier | Classes | Samples | % of data |
|------|---------|---------|-----------|
| A (>=500) | 19 | 98,338 | 98.3% |
| B (100-499) | 4 | 1,153 | 1.2% |
| C (50-99) | 4 | 276 | 0.3% |
| D (20-49) | 3 | 99 | 0.1% |
| E (10-19) | 7 | 104 | 0.1% |
| F (<10) | 9 | 30 | 0.0% |

Threshold effect on retained classes:
- >=10: 37 classes, imbalance 1774.6:1
- >=50: 27 classes, imbalance 425.9:1
- >=100: 23 classes, 99.5% data, imbalance 136.5:1
- >=500: 19 classes, 98.3% data, imbalance 23.1:1

---

## 4. Reduced-Class Experiments (Step 10)

| Formulation | Classes | Macro F1 | Balanced Acc | Weighted F1 |
|-------------|---------|----------|--------------|-------------|
| Full 46 | 46 | 0.2063 | 0.2681 | 0.3322 |
| >=10 | 37 | 0.2271 | 0.3042 | 0.3303 |
| >=20 | 30 | 0.268 | 0.3507 | 0.3416 |
| >=50 | 27 | 0.3035 | 0.3722 | 0.3636 |
| >=100 | 23 | 0.3484 | 0.4141 | 0.3822 |
| >=500 | 19 | 0.3605 | 0.4122 | 0.4036 |

Class reduction clearly improves macro learnability.

---

## 5. Separability Analysis (Step 5)

| Formulation | Avg cosine similarity |
|-------------|----------------------|
| Full 46 | 0.694207 |
| >=10 | 0.766532 |
| >=20 | 0.797853 |
| >=50 | 0.806544 |
| >=100 | 0.807674 |
| >=500 | 0.824329 |

**Separability does NOT improve with filtering** — it worsens (0.69 → 0.82), because removing
rare classes leaves a set of common, overlapping diseases.

---

## 6. Low-Information Input Analysis (Step 8)

| # Symptoms | Avg max score | Top1-top2 gap | Migraine % |
|-----------|---------------|---------------|------------|
| 1 | 0.102534 | 0.019966 | 87.5% |
| 3 | 0.14497 | 0.067099 | 58.0% |
| 5 | 0.157365 | 0.079966 | 39.0% |
| 10 | 0.177527 | 0.095924 | 14.0% |
| 15 | 0.156953 | 0.073054 | 5.0% |
| 30 | 0.125344 | 0.047572 | 1.5% |

---

## 7. Migraine Bias Findings

- Sparse inputs (1 symptom) predict Migraine **87.5%** of the time
  even though Migraine is only ~0.47% of the dataset (over-represented ~8.6x).
- Migraine frequency falls as symptoms increase: 87.5% → 39.0% → 14.0% → 1.5%.
- This is a **balanced-class-weight default-class artifact** on near-zero-information inputs, NOT a medical signal.

---

## 8. Minimum Information Recommendation (Step 9)

- **Recommend minimum 5 symptoms** for a prediction attempt; **warn below 10**.
- Evidence: at < 5 symptoms the model outputs Migraine 39-87% with near-noise scores;
  at >= 10 it shows best discrimination (max score 0.178, gap 0.096).
- This is a statistical heuristic, NOT a medical rule. Not implemented in this phase.

---

## 9. Hierarchical / One-vs-Rest Feasibility (Steps 6, 7)

- **Hierarchical:** NOT justifiable — no medical grouping documentation exists; deriving groups
  from symptom similarity is circular. Conclusion: *"No evidence-supported hierarchical grouping
  can be constructed from the current dataset."*
- **One-vs-rest:** 27 diseases have >= 50 positive
  samples (statistically feasible binary). Full table in `one_vs_rest_feasibility.csv`. This is a
  feasibility result only; not deployed.

---

## 10. Future Model Architecture (Step 13)

Design only (see `phase7f_step13_model_architecture.md`): backend-driven binary symptom
vocabulary, feature-order alignment, RandomForest (balanced) on a well-supported class subset,
top1 + top-5 output, raw scores as statistical similarity (not diagnosis), low-information
handling, and an explicit statistical-output ≠ medical-diagnosis disclaimer.

---

## 11. Dynamic Symptom Vocabulary Design (Step 14)

Design only (see `dynamic_symptom_vocabulary_design.md`): GET /api/symptoms returns id+label;
POST /api/predict accepts canonical ids; deduplicate; invalid/unknown handling; versioned
feature order. Replaces hard-coded `MockSymptoms.all`.

---

## 12. Future Dataset Requirements (Step 16)

See `future_dataset_requirements.md`: MUST (documented provenance, adequate class support,
meaningful feature-label relationships, interpretable features, clear targets, reproducible,
usable license); SHOULD (balanced, representative patterns not 100% unique, sufficient samples,
documented preprocessing); REJECT if unknown provenance / unverifiable labels / tiny classes /
no discrimination / unusable / fabricated.

---

## 13. Final Model Strategy (Step 17)

**OPTION 4 — Stop disease classification development until a better dataset is obtained.**

Rationale: data quality (synthetic-style, unknown provenance, weak separability even after
reduction) is the binding constraint. Restructuring improves metrics but not reliability.

(If development must proceed before better data, OPTION 2 — a limited-support exploratory
model — is the only acceptable conditional fallback, never as a production medical tool.)

---

## 14. Production Safety Verification (Step 18)

- `disease_model.joblib` — **UNCHANGED** (same SHA256 as Phase 7E).
- `symptom_columns.joblib` — **UNCHANGED**.
- `disease_dataset_cleaned_v2.csv` — **UNCHANGED**.
- Flutter — **UNCHANGED**.
- Flask — **UNCHANGED**.
- API — **UNCHANGED**.
- No production model deployed; no dataset replaced; Phase 8 not started.

---

## 15. Recommended Next Phase (do NOT execute)

> **Phase 7G — Approved Dataset Acquisition & Integration.** Obtain and manually inspect a
> verified, documented, well-supported disease-symptom dataset; then integrate the dynamic
> symptom vocabulary and a limited-support model. Prerequisite: manual dataset inspection
> against the Step 16 requirements.
