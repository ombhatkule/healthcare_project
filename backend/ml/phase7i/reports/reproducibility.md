# Phase 7I — Reproducibility

**Non-clinical research/educational evaluation; not clinically validated.**

## Environment
| Component | Version |
|---|---|
| Python | 3.11.9 |
| scikit-learn | 1.8.0 |
| pandas | 3.0.5 |
| numpy | 2.4.6 |
| OS | Windows (win32) |

## Randomness & seeds
- Global random seed: `42`
- CV repeats: `Repeated Stratified Group K-Fold` implemented via `StratifiedGroupKFold(n_splits=5, shuffle=True, random_state=seed)` for seeds `[42, 43, 44, 45, 46, 47, 48, 49, 50, 51]` (10 repeats × 5 folds = 50 folds).
- All estimators use `random_state=42`:
  - LogisticRegression: `solver=lbfgs, max_iter=5000`
  - LinearSVC: `max_iter=10000`
  - RandomForestClassifier: `n_estimators=200, max_features='sqrt', min_samples_split=2, min_samples_leaf=1, n_jobs=-1`
- Ablation: same seeds/folds; `Pipeline(SelectKBest(chi2, k=70), LogisticRegression(balanced, lbfgs, max_iter=5000))` — selection fit on training portion only.

## Inputs & hashes
| Artifact | SHA-256 |
|---|---|
| Phase 7H Representation C input (`symbipredict_deduplicated.csv`) | `8396a664…` |
| Processed 131-feature dataset (`symbipredict_representationC_131feat.csv`) | `0f60f981…` |
| Feature vocabulary (`symptom_columns_131.json`) | `88da8689…` |
| Production `disease_model.joblib` | `f772b3b8…` (unchanged) |
| Production `symptom_columns.joblib` | `9fea903c…` (unchanged) |
| Production `disease_dataset_cleaned_v2.csv` | `5912fa31…` (unchanged) |

Full hashes: `evidence/production_baseline_hashes.txt` and `evidence/production_final_hashes.txt`.

## Evaluation configuration
- Grouped by unique symptom vector; identical vectors never split across train/test.
- Metrics per fold: accuracy, balanced accuracy, macro/weighted precision-recall-F1; aggregated mean ± std over 50 folds.
- Per-class metrics and confusion matrices derived from summed aggregate confusion matrices over all 50 folds.

## Scripts
- `scripts/phase7i_preprocess.py` → `data/`, `validation/phase7i_preprocessing.json`
- `scripts/phase7i_benchmark.py` → all CV results, comparison, confusion, per-class, predictions, best-model artifact, metadata.

## Expected rerun result
- LR / LinearSVC / RF (cw=None): accuracy = balanced acc = macro F1 = 1.0 (std 0.0) for all 6-family configs except RF class_weight=balanced ≈ 0.9989 ± 0.0048.
- Ablation ≈ 0.669 / 0.606 / 0.583 (acc / balacc / macroF1).