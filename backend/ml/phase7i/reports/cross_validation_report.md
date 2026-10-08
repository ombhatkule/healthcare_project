# Phase 7I — Cross-Validation Report

**Non-clinical research/educational evaluation; not clinically validated.**

## Evaluation protocol
- **Grouping unit:** unique symptom vector (identical vectors are never split across train/test)
- **CV scheme:** Repeated Stratified Group K-Fold, 5 folds × 10 repeats (50 folds), seeds 42–51
- `StratifiedGroupKFold(n_splits=5)` is mathematically feasible here: every class has ≥ 5 groups, and every fold retains all 41 classes.
- `RepeatedStratifiedGroupKFold` does not exist in scikit-learn 1.8 (removed); the repeats are implemented by iterating seeds 42–51 — functionally identical.
- Random seed: `42` for all models.
- No naive random row splitting was used anywhere.

## Grouped fold feasibility
- Unique groups: 304 (one per row in Representation C)
- Per-class group counts observed: 5–10
- Fold test sizes (one repeat): ~60–62 rows, all 41 classes present per fold.

## Aggregate grouped-CV results (mean ± std over 50 folds)

| Config | Accuracy | Balanced Acc | Macro Precision | Macro Recall | Macro F1 | Weighted F1 |
|---|---|---|---|---|---|---|
| LR (cw=None) | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| LR (cw=balanced) | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| LinearSVC (cw=None) | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| LinearSVC (cw=balanced) | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| RF 200/sqrt (cw=None) | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| RF 200/sqrt (cw=balanced) | 0.9990 ± 0.0039 | 0.9990 ± 0.0041 | 0.9990 ± 0.0041 | 0.9990 ± 0.0041 | 0.9989 ± 0.0048 | 0.9988 ± 0.0046 |
| **Majority baseline** | **0.0329** | **0.0244** | **0.0** | **0.0** | **0.0** | **0.0329** |

`cw` = class_weight. Full JSON: `outputs/cross_validation_results.json`; per-model confusion matrices: `benchmarks/confusion_matrix_<model>.csv`.

## Interpretation
- All six model configurations massively outperform the majority baseline (accuracy 0.033, balanced accuracy 0.024, macro F1 0).
- Five of six configurations tie exactly at the ceiling (macro F1 = 1.0 ± 0.0), with zero variance across 50 grouped folds. This indicates the canonical symptom signatures in Representation C are essentially perfectly separable (linearly and by trees) with the leakage-safe grouped protocol.
- Because several models are indistinguishable, the cross-validation evidence **cannot select a single winner**.

## Important caveats
- Near-perfect grouped-CV is expected for clean, noiseless canonical vectors; it does **not** imply robustness to real patient variability.
- Only 304 unique associations exist (≈7.4 associations/class); per-class estimates have high uncertainty.
- The 41-class problem with per-class support 5–10 means a fold may contain only ~1–2 canonical vectors per class.