# Phase 7I — Model Training, Benchmarking & Validation

**Non-clinical research/educational evaluation; not clinically validated.**

## Scope
Isolated research experiment on the Phase 7H.1-approved **SymbiPredict Representation C** dataset. Trains and benchmarks **experimental** models only. **Nothing created here is production** and nothing was integrated or deployed.

## Inputs
- `backend/ml/phase7h/cleaned/symbipredict_deduplicated.csv` — Representation C (304 unique associations, 132 features, 41 classes)
- Vocabulary after approved `fluid_overload` removal: `data/symptom_columns_131.json`

## What is here
| Path | Contents |
|---|---|
| `scripts/` | `phase7i_preprocess.py`, `phase7i_benchmark.py` (reproducible pipelines) |
| `data/` | `symptom_columns_131.json`, `symbipredict_representationC_131feat.csv` |
| `validation/` | `phase7i_preprocessing.json` |
| `benchmarks/` | `model_comparison.csv`, `confusion_matrix_<model>.csv` (×6) |
| `reports/` | 8 required reports + `per_class_metrics.csv`, `confusion_pairs.csv`, `feature_importance.csv`, `reproducibility.md` |
| `outputs/` | `model_comparison.json`, `cross_validation_results.json`, `phase7i_validation.json`, `phase7i_decision.json` |
| `models/` | `experimental_best_model.joblib` **(NOT PRODUCTION)**, `experimental_model_metadata.json` |
| `predictions/` | `heldout_predictions.csv` (304 group-safe held-out predictions) |
| `evidence/` | `production_baseline_hashes.txt`, `production_final_hashes.txt` |

## Method
- Preprocessing: drop constant `fluid_overload`; deterministic 131-feature vocabulary; no synonym merging (11 candidates PENDING_CLINICIAN_REVIEW); strict binary/no-missing checks.
- Evaluation: **Repeated Stratified Group K-Fold (5 × 10)** grouped by unique symptom vector; same vector never split across train/test.
- Models: majority baseline, LogisticRegression (cw None/balanced), LinearSVC (cw None/balanced), RandomForest 200/sqrt (cw None/balanced) + one leakage-safe fold-internal ablation (SelectKBest chi2 k=70).

## Headline result
- All experimental configs reach essentially perfect grouped CV (5/6 tie at macro F1 = 1.0 ± 0.0) vs majority baseline 0.033 acc / 0.024 balacc.
- **Phase decision: NO_CLEAR_WINNER** — multiple models are statistically identical; evidence does not justify selecting one.
- Because results are at the ceiling on canonical, noiseless, non-patient associations, they must **not** be read as clinical readiness.

## Production safety
- Production model/dataset/metadata hash-verified unchanged before and after (`evidence/`). No Flask/Flutter/API modifications. No integration, no deployment, no start of Phase 7J.
- Decision record: `outputs/phase7i_decision.json` (`clinical_validation: false`, `production_model_replaced: false`).