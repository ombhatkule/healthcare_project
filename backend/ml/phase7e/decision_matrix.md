# Phase 7E Decision Matrix

**Date:** 2026-09-08

## Comparison: CURRENT DATASET vs TOP CANDIDATE(S)

### Current Dataset (`disease_dataset_cleaned_v2.csv`)
- **Class support:** 7 classes < 5 samples; 9 classes < 10 samples (19.6% of classes)
- **Class balance:** 21,295:1 imbalance; top-5 classes = 55.4% of data
- **Feature discrimination:** 116/174 features MI > 0.01; mean MI 0.017 (weak)
- **Disease separability:** avg pairwise cosine similarity 0.694 (weak)
- **Provenance:** Unknown
- **Documentation:** None found
- **Integration complexity:** Already integrated (fits current model/API)
- **Expected ML suitability:** Weak-to-unsuitable (best macro F1 ~0.19)

### Best Candidate: UCI 'Early Stage Diabetes Risk Prediction' (ID 529)
- **Class support:** ~520 rows, 2 classes, balanced-ish, doctor-approved questionnaires
- **Class balance:** ~2:1 (good)
- **Feature discrimination:** 16 interpretable binary symptom features; good variation
- **Disease separability:** 2-class problem is far more separable
- **Provenance:** Strong (Sylhet Diabetes Hospital, doctor-approved, published paper)
- **Documentation:** UCI variable table, paper reference
- **Integration complexity:** Low for diabetes-only, but NOT a general disease-symptom dataset
- **Expected ML suitability:** High for diabetes but only covers 2 classes

### Other Candidates
- Kaushil268 (42 diseases / 132 symptoms): matches disease-symptom format but only ~5000 rows, unverified
- IEEE (391 diseases / 1325 symptoms): broad but per-class support likely tiny
- Symptom2Disease: text-based, 24 diseases, requires NLP
- Community Healthcare: 174/46 â€” "simulated", likely same synthetic source as current
- CDC Diabetes: survey features, not symptoms
- 820_Cleaned: 820 classes â€” infeasible for meaningful multiclass eval

---

## Recommendation Selection

**Chosen: D â€” NO SUITABLE REPLACEMENT DATASET FOUND â€” DO NOT PROCEED WITHOUT BETTER DATA**

### Rationale

1. **Current dataset is unsuitable** â€” confirmed by Phase 7D (best macro F1 â‰ˆ 0.19) and Phase 7E
   (class imbalance 21,295:1, weak MI, low separability, unknown provenance).

2. **No web-discovered candidate clearly satisfies the Must-Have requirements:**
   - None was directly inspected (all are Kaggle/IEEE/UCI remote).
   - The only feature-matching candidate (Community Healthcare 174/46) is explicitly "simulated" â€”
     likely the same synthetic-style data already in use.
   - Kaushil268 has only ~5000 rows for 42 classes (still imbalanced, unverified provenance).
   - IEEE (391 diseases) has likely tiny per-class support and was student-assembled (MedLinePlus-referenced but not validated).
   - Symptom2Disease / CDC / Symptom-to-Disease-820 all require NLP or exceed the class count for meaningful evaluation.

3. **None of the candidates was verified** (all are remote, no direct inspection performed).

4. **Therefore: no dataset replacement should be performed now.**

### What This Means (recommendation D)

- Keep the current dataset (do not delete).
- Do NOT replace the production model.
- The next phase should focus on **restructuring the prediction problem** (recommendation B secondary)
  OR pursuing a verified candidate only after manual inspection.

---

## Recommendation Summary

- **A. KEEP CURRENT + IMPROVE MODEL/INPUT** â€” Possible but limited by fundamental data weaknesses.
- **B. KEEP CURRENT + REDUCE/RESTRUCTURE PROBLEM** â€” MOST VIABLE near-term path.
- **C. REPLACE WITH CANDIDATE (after manual review)** â€” Only if a candidate is found that clears all Must-Haves after direct inspection.
- **D. NO SUITABLE REPLACEMENT â€” DO NOT PROCEED WITHOUT BETTER DATA** â†’ **CHOSEN**

---

## Recommended Next Phase

> **Phase 7F â€” Prediction Problem Restructuring (with dynamic symptom vocabulary design)**

Because:
- No verified better replacement dataset was found (candidate search only, no direct verification).
- The current 46-class / 174-feature problem is fundamentally limited (imbalance, weak features).
- The most constructive path forward is to restructure the problem (fewer, better-supported classes,
  or a redesigned symptom vocabulary), while keeping the current dataset as-is and not replacing it.
- A prerequisite design task is **dynamic symptom vocabulary** so future data/model swaps don't break Flutter/Flask.
