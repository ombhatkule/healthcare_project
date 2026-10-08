# Phase 7I — Error Analysis

**Non-clinical research/educational evaluation; not clinically validated.**

## Scope
We analyze errors for the best representative model (LR, `class_weight=None`) and, because it achieves zero errors, also for the only non-perfect model (Random Forest with `class_weight=balanced`) and the controlled ablation.

## Best representative model (LR class_weight=None)
- Grouped CV: **0 errors across 3,040 test instances** (304 associations × 10 repeats).
- Confusion matrix: strict diagonal (`benchmarks/confusion_matrix_LR_class_weight_None.csv`).
- Held-out prediction set (repeat 0, one prediction per vector, 304 rows): 0 mismatches; correctness 1.0 (`predictions/heldout_predictions.csv`).

## Random Forest (class_weight=balanced) — 3 errors total
| True | Predicted | Count | True support | True recall |
|---|---|---|---|---|
| Chronic Cholestasis | Hepatitis D | 3 | 80 | 0.9625 |

Only **1 confusion pair** occurred, all in one direction:
- **Chronic Cholestasis → Hepatitis D**: 3/3040 samples. Both are liver/biliary conditions sharing jaundice-related features (yellowish skin, dark urine, etc.); Phase 7H found Hepatitis D ↔ Hepatitis E the closest vector pair (cosine ≈ 0.83). This is consistent with **limited symptom information** (identical or near-identical canonical symptom sets for different bile/liver diseases) — we do not claim medical causality.

## With feature selection (ablation, LR balanced + SelectKBest k=70)
- Accuracy drops to 0.669, balanced accuracy 0.606, macro F1 0.583. Removing the 61 lowest-information features (many still with MI > 0.01 in Phase 7H) visibly degrades several classes, i.e. the 131-feature vector is genuinely informative.

## Summary
- No consistent confusion problem is observed for the top models; the dataset is canonically separable.
- The single observed pair (Chronic Cholestasis → Hepatitis D) is attributable to shared liver/biliary symptom signatures, i.e. limited feature information, and is **not** interpreted as a medical relationship.
- No manual corrections to any predictions were made.