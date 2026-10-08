# Phase 7J — Rollback Plan

**Date:** 2026-09-10  
**Status:** DOCUMENTED (rollback NOT executed)

## Current State

| Item | Path | Hash |
|------|------|------|
| Experimental model | `backend/ml/model/experimental_disease_model.joblib` | 4CBA73935D56AE4FDB6DF74B2175E9DC89E70CF797533F62B00E1DB8A4D1E93A |
| Experimental vocabulary | `backend/ml/model/experimental_symptom_columns.joblib` | E771E636803380CD7FE550AF34784DF6F1E60FC3278339DFF60F5100F69A79BA |
| Old production model | `backend/ml/model/disease_model.joblib` | F772B3B8A48E5E07196EE153E593A0E096E0F19875349DDB9DCFAF83895D16A6 |
| Old production vocabulary | `backend/ml/model/symptom_columns.joblib` | 9FEA903CFCBDF2D02E1A37082D88D4CBCDD495A264BF59BF81EAFD947D99332E |

## Rollback Steps

If the experimental model needs to be disabled:

### Step 1: Modify backend model configuration

In `backend/services/prediction_service.py`, change:

```python
DEFAULT_MODEL_PATH = os.path.join(
    _MODEL_DIR,
    os.getenv("EXPERIMENTAL_MODEL_FILE", "experimental_disease_model.joblib"),
)
DEFAULT_SYMPTOMS_PATH = os.path.join(
    _MODEL_DIR,
    os.getenv(
        "EXPERIMENTAL_SYMPTOM_COLUMNS_FILE",
        "experimental_symptom_columns.joblib",
    ),
)
```

To:

```python
DEFAULT_MODEL_PATH = os.path.join(_MODEL_DIR, "disease_model.joblib")
DEFAULT_SYMPTOMS_PATH = os.path.join(_MODEL_DIR, "symptom_columns.joblib")
```

### Step 2: Update model version metadata

Change `MODEL_VERSION` from `"phase7i_experimental_lr_class_weight_none"` to the appropriate Phase 7C version string.

### Step 3: Restart Flask

```bash
cd backend
python app.py
```

### Step 4: Verify

```bash
curl http://localhost:5000/api/health
```

Confirm `feature_count` returns 174 (old model) instead of 131.

## Notes

- The old Phase 7C model uses 174 features (different feature set from the 131-feature experimental model).
- The Flutter app fetches symptoms from `GET /api/symptoms`, so it will automatically adapt to whichever vocabulary the backend serves.
- The old model files have NOT been modified and remain hash-identical to the original production baseline.
