# Phase 7I — Feature Analysis

**Non-clinical research/educational evaluation; not clinically validated.**

## Model-associated feature importance
Saved: `reports/feature_importance.csv`.

The best representative model is a **linear** model (Logistic Regression), so importance is reported as **mean absolute coefficient** across the 41 one-vs-rest decision boundaries — a **model-associated importance**, not a statement of medical importance.

### Top 20 model-associated features (by |mean coef|)
| # | feature | abs_mean_coef |
|---|---|---|
| 1 | vomiting | 0.4282 |
| 2 | fatigue | 0.4102 |
| 3 | high_fever | 0.3627 |
| 4 | headache | 0.3175 |
| 5 | nausea | 0.3129 |
| 6 | loss_of_appetite | 0.2961 |
| 7 | abdominal_pain | 0.2835 |
| 8 | itching | 0.2712 |
| 9 | skin_rash | 0.2651 |
| 10 | yellowish_skin | 0.2460 |
| 11 | joint_pain | 0.2390 |
| 12 | yellowing_of_eyes | 0.2355 |
| 13 | chest_pain | 0.2268 |
| 14 | chills | 0.2206 |
| 15 | sweating | 0.2167 |
| 16 | diarrhoea | 0.2104 |
| 17 | dark_urine | 0.1839 |
| 18 | muscle_pain | 0.1750 |
| 19 | malaise | 0.1740 |
| 20 | cough | 0.1664 |

These are widespread symptoms (fever, pain, GI symptoms) shared across many diseases — consistent with them driving the 41-class decision boundaries rather than being disease-specific discriminators.

### Constant-feature handling recap
- Removed in preprocessing: `fluid_overload` (all-zero constant; approved in Phase 7H.1). Twin `fluid_overload_1` (with real signal for Alcoholic Hepatitis) is **retained** (|mean coef| ≈ 0.0514, mid-range).
- No other constant feature exists after removal.

### Ablation evidence (feature-selection sensitivity)
- Keeping all 131 features (LR balanced): macro F1 = **1.0 ± 0.0**.
- `SelectKBest(chi2, k=70)` inside folds (LR balanced): macro F1 = **0.583 ± 0.041**.
- ⇒ The full 131-feature vocabulary should be kept; global feature pruning is not justified.

## Interpretation rules
- These magnitudes are **model-associated feature importance** on a research dataset — do not interpret as "medical importance" of a symptom, and do not infer that a symptom is clinically causal for a disease.
- The near-perfect separation means many features contribute discriminative signal (Phase 7H: 130/131 features with mutual information > 0.01).