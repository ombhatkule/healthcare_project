# Phase 7I — Model Comparison

**Non-clinical research/educational evaluation; not clinically validated.**

## Ranking
Ranking key is **Macro F1 → Balanced Accuracy → Macro Recall** (not accuracy).

| Rank | Model | Macro F1 (mean±std) | Balanced Acc (mean±std) | Accuracy (mean±std) | Weighted F1 (mean±std) |
|---|---|---|---|---|---|
| 1 | LR class_weight=None | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| 1 (tie) | LR class_weight=balanced | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| 1 (tie) | LinearSVC class_weight=None | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| 1 (tie) | LinearSVC class_weight=balanced | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| 1 (tie) | RF class_weight=None | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 | 1.0 ± 0.0 |
| 6 | RF class_weight=balanced | 0.9989 ± 0.0048 | 0.9990 ± 0.0041 | 0.9990 ± 0.0039 | 0.9988 ± 0.0046 |
| — | Ablation: LR balanced + SelectKBest(chi2, k=70) | 0.5832 ± 0.0412 | 0.6061 ± 0.0394 | 0.6691 ± 0.0326 | 0.6535 ± 0.0354 |
| — | Majority baseline | 0.0 | 0.0244 | 0.0329 | 0.0329 |

Full table: `benchmarks/model_comparison.csv`; machine-readable: `outputs/model_comparison.json`.

## Model selection rule applied
- Evaluation leakage-safe: yes (grouped CV), reproducible: yes (macro F1 std = 0.0 for the five top configs), substantially above baseline: yes.
- **However, five of six configs are statistically identical (all 1.0 ± 0.0).** Differences are exactly zero, so by the rule "if differences are small relative to standard deviation ⇒ NO CLEAR WINNER," no single configuration can be chosen.
- The saved artifact (`models/experimental_best_model.joblib`) is LR class_weight=None only as a deterministic tie-break representative; it is **NOT** claimed to be superior.

## Controlled ablation
- **A:** LR balanced, full 131 features — macro F1 1.0 ± 0.0.
- **B:** LR balanced + `SelectKBest(chi2, k=70)` applied **inside each training fold** (Pipeline; leakage-safe) — macro F1 0.5832 ± 0.0412, balanced acc 0.6061 ± 0.0394.
- Both use the exact same grouped folds. Feature reduction to 70 clearly destroys the discriminative structure (many of the 131 features carry information; Phase 7H reported 130/131 features with MI > 0.01). Conclusion: **keep the full 131-feature vocabulary**; do not pre-select features globally.

## Conclusion
- Multiple models reach the grouped-CV ceiling; **NO_CLEAR_WINNER** among model configurations.
- The decisive factor here is dataset structure, not model family — a strong inverse indicator of model differentiation, and a caveat that real-patient variability is untested.