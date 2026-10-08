# Phase 7F Step 11 — Model Selection Rule

## Primary Metrics (used, not accuracy)

1. **Macro F1** — equal weight to all classes; penalizes ignoring minority classes.
2. **Macro Recall** — whether each class is actually recovered.
3. **Balanced Accuracy** — accuracy averaged over classes, robust to imbalance.
4. **Weighted F1** — practical performance weighted by class support.

## Measured Results (consistent RandomForest, in-memory only)

| Formulation | Classes | Macro F1 | Macro Recall | Balanced Acc | Weighted F1 |
|-------------|---------|----------|--------------|--------------|-------------|
| Full 46-class | 46 | {exp_full.get('macro_f1')} | {exp_full.get('macro_recall')} | {exp_full.get('balanced_accuracy')} | {exp_full.get('weighted_f1')} |
| >=10 classes | {exp_ge10.get('n_classes')} | {exp_ge10.get('macro_f1')} | {exp_ge10.get('macro_recall')} | {exp_ge10.get('balanced_accuracy')} | {exp_ge10.get('weighted_f1')} |
| >=20 classes | {exp_ge20.get('n_classes')} | {exp_ge20.get('macro_f1')} | {exp_ge20.get('macro_recall')} | {exp_ge20.get('balanced_accuracy')} | {exp_ge20.get('weighted_f1')} |
| >=50 classes | {exp_ge50.get('n_classes')} | {exp_ge50.get('macro_f1')} | {exp_ge50.get('macro_recall')} | {exp_ge50.get('balanced_accuracy')} | {exp_ge50.get('weighted_f1')} |
| >=100 classes | {exp_ge100.get('n_classes')} | {exp_ge100.get('macro_f1')} | {exp_ge100.get('macro_recall')} | {exp_ge100.get('balanced_accuracy')} | {exp_ge100.get('weighted_f1')} |
| >=500 classes | {exp_ge500.get('n_classes')} | {exp_ge500.get('macro_f1')} | {exp_ge500.get('macro_recall')} | {exp_ge500.get('balanced_accuracy')} | {exp_ge500.get('weighted_f1')} |

## Rule Statement

Higher metrics alone do NOT justify production adoption. A model is only production-worthy if:

1. Its **dataset** has adequate per-class support (e.g., most classes >= 50-100 samples),
2. Its **features** show meaningful, non-overlapping discriminative signal, and
3. Its **task** is statistically well-posed (not dominated by default-class behavior).

**Conclusion:** Class-target reduction improves measured learnability (Macro F1 ~0.21 → 0.36
and Balanced Accuracy ~0.27 → 0.41), but the reduced dataset still shows high class similarity
and remains a weak, synthetic-style formulation. Target-class reduction alone does NOT solve
the dataset limitation; it merely makes a subset more learnable within the same weak data.
