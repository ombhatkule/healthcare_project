# Phase 7J — Production Safety Report

**Date:** 2026-09-10  
**Status:** PASS

## Production Baseline Hashes (Pre-Integration)

| File | SHA-256 |
|------|---------|
| `backend/ml/model/disease_model.joblib` | F772B3B8A48E5E07196EE153E593A0E096E0F19875349DDB9DCFAF83895D16A6 |
| `backend/ml/model/symptom_columns.joblib` | 9FEA903CFCBDF2D02E1A37082D88D4CBCDD495A264BF59BF81EAFD947D99332E |
| `backend/data/disease_dataset_cleaned_v2.csv` | 5912FA31E8A2B22DBD65AD8D584482DC531154452F5B8881E9BB5D12CD2C2E50 |

## Production Baseline Hashes (Post-Integration)

| File | SHA-256 | Match |
|------|---------|-------|
| `backend/ml/model/disease_model.joblib` | F772B3B8A48E5E07196EE153E593A0E096E0F19875349DDB9DCFAF83895D16A6 | YES |
| `backend/ml/model/symptom_columns.joblib` | 9FEA903CFCBDF2D02E1A37082D88D4CBCDD495A264BF59BF81EAFD947D99332E | YES |
| `backend/data/disease_dataset_cleaned_v2.csv` | 5912FA31E8A2B22DBD65AD8D584482DC531154452F5B8881E9BB5D12CD2C2E50 | YES |

**PRODUCTION BASELINE = PASS**

## Safeguards

- Original production model (`disease_model.joblib`) preserved and hash-verified.
- Original symptom columns (`symptom_columns.joblib`) preserved and hash-verified.
- Original dataset (`disease_dataset_cleaned_v2.csv`) preserved and hash-verified.
- No dataset modifications.
- No model retraining or tuning.
- Phase 7I artifacts used exactly as produced (no modification).
- No synthetic data, no SMOTE, no augmentation.
- No unrelated backend or Flutter changes.

## Backup Location

`backend/ml/phase7j/backup/` contains copies of:
- `disease_model.joblib`
- `symptom_columns.joblib`
- `disease_dataset_cleaned_v2.csv`

## Rollback Readiness

The old Phase 7C model (`disease_model.joblib`, 174 features, 46 classes) remains in place and can be reactivated by changing the model path configuration in `prediction_service.py`.
