# Phase 7J — Model Verification Report

**Date:** 2026-09-10  
**Status:** VERIFIED

## Model Artifact

| Property | Value |
|----------|-------|
| File | `backend/ml/model/experimental_disease_model.joblib` |
| Source | `backend/ml/phase7i/models/experimental_best_model.joblib` |
| Model Type | LogisticRegression |
| n_features_in_ | 131 |
| n_classes | 41 |
| has_predict_proba | True |
| solver | lbfgs |
| max_iter | 5000 |
| class_weight | None |
| random_state | 42 |

## Vocabulary Artifact

| Property | Value |
|----------|-------|
| File | `backend/ml/model/experimental_symptom_columns.joblib` |
| Source | `backend/ml/phase7i/data/symptom_columns_131.json` |
| Feature count | 131 |
| Columns unique | True |
| Columns are strings | True |
| fluid_overload present | False |
| fluid_overload_1 present | True |

## SHA-256 Hashes

| Artifact | SHA-256 |
|----------|---------|
| experimental_disease_model.joblib | 4CBA73935D56AE4FDB6DF74B2175E9DC89E70CF797533F62B00E1DB8A4D1E93A |
| experimental_symptom_columns.joblib | E771E636803380CD7FE550AF34784DF6F1E60FC3278339DFF60F5100F69A79BA |
| Source vocab JSON | 88DA86895DB4F73ACF80B572606FCBDBB5A798A260042581370CB7C27E12618D |

## Dimensionality Verification

- Model expects: 131 features
- Vocabulary provides: 131 features
- predict_proba output shape: (1, 41)
- Feature count match: CONFIRMED

## Load Performance

- Model load time: ~1.5–2.5 seconds (varies by system load)
- Inference time: < 5ms per prediction

## Conclusion

The Phase 7I experimental Logistic Regression model has been verified to load correctly, accept 131-dimensional binary feature vectors, and produce 41-class probability distributions. The artifact is intact and consistent with its metadata.
