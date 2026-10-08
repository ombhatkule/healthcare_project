# Phase 7F Baseline (from Phase 7E findings)

**Date:** 2026-09-08

## Phase 7E Conclusions that Affect Model Design

1. **Full 46-class problem is fundamentally unsuitable** for reliable prediction.
   - Best observed Macro F1 ~= 0.19 (Logistic Regression).
   - Mean mutual information ~= 0.017 (weak feature discrimination).
   - Average pairwise cosine similarity ~= 0.694 (weak disease separability).

2. **Extreme class imbalance:**
   - Largest class (Asthma) = 21,295 samples.
   - Smallest class (Metabolic_Syndrome) = 1 sample.
   - Imbalance ratio = 21,295:1.
   - Top-5 classes hold ~55.41% of the dataset.

3. **Rare-class support is the core constraint:**
   - 9/46 classes have < 10 samples (cannot be trained or evaluated reliably).
   - 7/46 classes have < 5 samples.

4. **All 100,000 symptom vectors are unique** (no repeated patterns); the data is
   'weakly structured' and 'statistically consistent with synthetic-style generation'.

5. **Low-information inputs are unreliable:** Empty/near-empty vectors predict
   Migraine with ~9-11% confidence; Migraine is over-represented ~8.6x vs prevalence.

## Implication for Model Design

Increasing model complexity alone CANNOT fix insufficient information in the input
features. The Phase 7F experiments focus on whether RESTRUCTURING the target (fewer,
better-supported classes) improves learnability — not on blindly training a 46-class model.
