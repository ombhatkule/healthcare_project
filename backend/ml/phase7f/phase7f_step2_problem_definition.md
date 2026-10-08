# Phase 7F Step 2 — Formal Problem Definition

## Current Problem Specification

- **Input:** 174 binary symptom features (0/1 present/absent)
- **Output:** 46 disease classes (single-label)
- **Task:** Supervised multiclass classification

## Structural Constraints (measured in Phase 7E)

| Constraint | Value |
|------------|-------|
| Total rows | 100,000 |
| Classes | 46 |
| Imbalance ratio | 21,295:1 |
| Classes < 10 samples | 9 (19.6%) |
| Classes < 5 samples | 7 |
| Top-5 classes share | 55.41% of data |
| Mean mutual information | ~0.017 (weak) |
| Avg pairwise cosine similarity | ~0.694 (weak) |

## Current Observed Behavior

- Sparse generic inputs (1-2 symptoms) frequently predict **Migraine** (87.5% at 1 symptom,
  measured in Phase 7F Step 8) even with near-noise scores (~0.10).
- This is a **default-class behavior**: when evidence is weak, the model falls back to the
  minority class that the balanced class-weighting amplifies.

## Why Model Complexity Cannot Fix Insufficient Information

1. **Information limit:** If the input features (symptoms) carry only ~0.017 mean mutual
   information with the disease label, no algorithm can extract signal that does not exist.
   A more complex model would simply overfit to noise or the majority classes.

2. **Unlearnable classes:** 9 classes have < 10 samples. Even a perfect classifier cannot
   learn a decision boundary from 1-9 examples per class; there is literally no training
   evidence.

3. **Ambiguous evidence:** 46 classes with average pairwise similarity 0.694 and some pairs
   at 0.960 means many diseases are statistically near-indistinguishable from their symptoms
   alone. No model expresses signal that the features do not contain.

4. **Sparse-input non-identifiability:** With 1-2 symptoms, the feature space is dominated
   by ambiguous, low-information vectors that map to a default class. More model capacity
   cannot resolve inherent feature ambiguity.

> This is a **data/information** limitation, not a **model capacity** limitation.
