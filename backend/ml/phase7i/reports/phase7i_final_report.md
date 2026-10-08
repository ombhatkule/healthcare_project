# Phase 7I — Final Report

**Non-clinical research/educational evaluation; not clinically validated.**
**This model must not be used as a medical diagnosis system.**

## Summary
Phase 7I trained and evaluated experimental models on the Phase 7H-approved **SymbiPredict Representation C** dataset under a **leakage-safe grouped evaluation protocol**.

| Item | Value |
|---|---|
| Dataset | SymbiPredict Representation C (`symbipredict_deduplicated.csv`) |
| Unique associations | 304 |
| Disease classes | 41 |
| Features (after preprocessing) | 131 (`fluid_overload` removed) |
| Synonym mappings applied | No (all 11 pending clinician review) |
| Evaluation | Repeated Stratified Group K-Fold, 5 folds × 10 repeats, grouped by unique symptom vector |
| Majority baseline | accuracy 0.033 / balanced acc 0.024 / macro F1 0.0 |
| Best config (tie-break) | Logistic Regression, class_weight=None |
| Best config metrics | accuracy 1.0 ± 0.0, balanced acc 1.0 ± 0.0, macro F1 1.0 ± 0.0 |
| Overall phase decision | **NO_CLEAR_WINNER** |

## Headline results (grouped CV)
- All 6 model configurations reach **≥0.999** accuracy / balanced accuracy / macro F1; 5 of 6 tie exactly at **1.0 ± 0.0**.
- Ablation with fold-internal `SelectKBest(chi2, k=70)` drops macro F1 to 0.583 → full 131-feature vocabulary justified.
- Only observed error (non-best model): Chronic Cholestasis → Hepatitis D (3/3040, RF balanced).

## Decision — NO_CLEAR_WINNER
Rationale (from `outputs/phase7i_decision.json`):
1. Leakage-safe grouped CV succeeds and is fully reproducible.
2. All models far exceed the majority baseline.
3. **Five of six configs are identical at the ceiling (macro F1 1.0 ± 0.0)** — the evidence cannot justify selecting a single experimental model.
4. Ceiling performance is partly an artifact of canonical, noiseless, non-patient signatures.
5. No "better than production" claim is made (protocol mismatch with Phase 7C metrics).

## Artifacts (all inside `backend/ml/phase7i/`)
- `data/` — `symptom_columns_131.json` (vocab, SHA-256 `88da8689…`), processed CSV (SHA-256 `0f60f981…`)
- `validation/phase7i_preprocessing.json`, `outputs/cross_validation_results.json`, `outputs/model_comparison.json`, `outputs/phase7i_validation.json`, `outputs/phase7i_decision.json`
- `benchmarks/` — `model_comparison.csv`, `confusion_matrix_<model>.csv` (×6)
- `reports/` — `preprocessing_report.md`, `cross_validation_report.md`, `model_comparison.md`, `per_class_analysis.md`, `error_analysis.md`, `feature_analysis.md`, `dataset_limitations.md`, `reproducibility.md`, plus `per_class_metrics.csv`, `confusion_pairs.csv`, `feature_importance.csv`
- `models/` — `experimental_best_model.joblib` (**NOT PRODUCTION**) + `experimental_model_metadata.json`
- `predictions/heldout_predictions.csv` (304 group-safe held-out predictions)
- `evidence/` — production safety baseline + final hash checks

## Production safety
Production files were hash-verified before and after Phase 7I; **all unchanged and unmodified**. No Flask, Flutter, or API code was touched. Training state: **completed for benchmarking only**; no integration, no deployment.

## Next steps (do not auto-proceed)
- Phase 7J (backend integration validation) is **NOT STARTED** and requires explicit approval.
- Before any integration, Phase 7J must validate feature-order/inference compatibility and the exact vector-matching semantics, and must re-validate production behavior.