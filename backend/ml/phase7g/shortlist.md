# Phase 7G — Candidate Shortlist

**Phase:** 7G — Dataset Search & Acquisition
**Baseline reference:** `phase7g_baseline.md` (from Phase 7E/7F failure analysis)

11 candidates investigated → 3 shortlisted for active evaluation → 3 acquired.

---

## Shortlist (ranked)

### 1. SymbiPredict / Symptom-Disease Prediction Dataset (SDPD) — **PRIMARY RECOMMENDATION**
- **Acquired:** ✅ `backend/ml/phase7g/acquired/symbipredict_2022.csv`
- **Status:** **B — CONDITIONALLY APPROVED — MANUAL REVIEW REQUIRED** (decision memo: `candidate_decision.md`)
- **Score rationale:** Documented via Mendeley DOI (2024) and cited in a peer-reviewed MDPI Electronics paper; **explicit CC BY 4.0 license**; readily downloadable; directly-usable binary matrix (132 symptom columns + prognosis); **41 classes × 121 instances each** (imbalance 1.0:1); 0 classes < 100; mean mutual information **0.178** (≈10.8× the current 0.016); avg pairwise cosine separability **0.107** (vs current 0.694); 131/132 features with MI > 0.01.
- **Acquisition score:** 86/100 (weighted across class support, balance, discriminative features, separability, provenance, licensing, reproducibility).
- **Manual-review items (before Phase 7H completes validation):**
  1. Characterize as **community-curated symptom→disease associations** (medical literature + clinical observation + expert consensus), not real patient records; confirm fit for intended exploratory/educational purpose (Phase 7F OPTION 4 stands — no validated medical tool).
  2. **Symptom synonyms** to confirm: `stomach_pain/belly_pain → abdominal_pain`, `breathlessness → shortness_of_breath` (3 high-confidence; automated pass found up to 11 loose candidates).
  3. **Duplicate rows** (94%; 4657/4961): Phase 7H decides representation vs deduplication and effect on train/test/eval.
  4. **Model approval cannot be granted on data-quality metrics alone** — Phase 7H must benchmark separability/train-test behavior on a cleaned candidate.

### 2. Columbia University Disease-Symptom Knowledge Database — **ALTERNATIVE (license pending)**
- **Acquired:** ✅ `backend/ml/phase7g/acquired/columbia_disease_symptom_kb.csv`
- **Status:** CONDITIONALLY APPROVED — **manual license review required** (`friedman@dbmi.columbia.edu`); no explicit license found.
- **Score rationale:** Strongest provenance (real clinical extraction from 25,074 NYP 2004 discharge summaries via MedLEE NLP, UMLS-coded, AMIA 2008 PMC2656103, ~90% recall/~92% precision); 134 diseases, 401 symptoms, 1,858 associations; does NOT resolve license/shape verification yet.
- **Acquisition score:** 80/100.

### 3. Kaushil268 - Disease Prediction using Machine Learning — **REJECTED as primary / kept as cross-check**
- **Acquired:** ✅ `backend/ml/phase7g/acquired/kaushil268_disease_prediction.csv`
- **Status:** REJECTED as materially-better candidate — same 41-class/131-symptom family as SymbiPredict but **undocumented** (no indexed citation), and 93.8% duplicate rows / 304 unique vector patterns (synthetic-expression concern). The documented, peer-reviewed, CC BY 4.0 SymbiPredict version supersedes it.
- **Acquisition score:** 68/100 (used only as cross-check that the family's structure was confirmed independently).

---

## Not acquired / excluded (for completeness)
- **Al Shafi et al. (Mendeley rjgjh8hgrt/6)** — reference-only (85 rows, 1 per disease).
- **Mendeley synthetic 2cxccsxydc/1** — explicitly synthetic.
- **DDXPlus** — well-documented but explicitly synthetic patient generation.
- **MIMIC-SR-ICD11** — requires PhysioNet credentialed access (not bypassed per governance).
- **Milton / Yuan / rjanice / PedroAcacia / dianap8 / sublimation / Macgyver / Bedmutha / marslinoedward (Kaggle)** — undocumented mirrors/derivations of the same community family.
- **Zenodo 12,090-class infectious dataset** — domain mismatch (infectious diseases excluded by scope).
- **uom190346a** — small community table (24 diseases).

## Recommendation
> **Approved candidate: SymbiPredict (decision B, manual review pending).**
> **Next phase: PHASE 7H — DATASET PREPROCESSING & VALIDATION** on `backend/ml/phase7h/` (cleaned candidate only; production untouched) — resolve duplicate representation, confirm synonyms, benchmark class separability and train/test behavior; include Columbia KB as an alternative if its license is confirmed.