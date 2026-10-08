# Phase 7J — Controlled Production Integration

**Status:** COMPLETE  
**Decision:** A — INTEGRATION_SUCCESSFUL_RESEARCH_MODE  
**Date:** 2026-09-10

## History

### Phase 7G — External Dataset Acquisition
- Acquired three candidate external datasets for potential generalization testing.
- SymbiPredict (Mendeley, CC BY 4.0) — primary source for Representation C.
- Columbia Disease-Symptom KB — selected for Phase 7K external evaluation attempt.
- kaushil268 — rejected (same canonical family as in-sample data).

### Phase 7H — SymbiPredict Representation C
- 304 unique symptom–disease associations.
- 41 disease classes.
- 132 original features (including `fluid_overload`).

### Phase 7H.1 — Conditional Approval
- `fluid_overload` approved for removal (redundant with `fluid_overload_1`).
- 11 synonym mappings remain PENDING_CLINICIAN_REVIEW (none approved).
- Representation C approved conditionally for Phase 7I.

### Phase 7I — Experimental Model Training
- 131 features, 41 classes.
- 6 model configurations evaluated: Logistic Regression, Linear SVM, Random Forest (each with `class_weight=None` and `class_weight=balanced`).
- Repeated Stratified Group K-Fold (5 folds × 10 repeats) grouped by unique symptom vector.
- 5 of 6 configurations reached macro F1 = 1.0 with zero variance.
- Decision: **NO_CLEAR_WINNER** — evidence does not justify selecting one single model.
- Tie-break selected: Logistic Regression, `class_weight=None` (lowest complexity).
- Artifact: `experimental_best_model.joblib`.

### Phase 7K — External Evaluation
- Investigated 9 candidate external datasets.
- Columbia KB: 8/41 labels EXACT-matched, 22/41 NO_MATCH; only 15.3% of 131 features covered.
- Coverage collapse: **0 usable end-to-end observations**.
- Decision: **C — INSUFFICIENT_EXTERNAL_DATA**.
- External validation: NOT ESTABLISHED.

## Why SymbiPredict / Representation C
- Only dataset with a complete symptom-matrix format compatible with binary feature-vector modeling.
- 304 unique associations (deduplicated) across 41 disease classes.
- CC BY 4.0 licensed.

## Why fluid_overload Was Removed
- `fluid_overload` and `fluid_overload_1` represent the same symptom.
- Phase 7H.1 approved removal of `fluid_overload` to avoid multicollinearity.

## Why Synonyms Were Not Applied
- 11 synonym mappings from Phase 7H.1 remain PENDING_CLINICIAN_REVIEW.
- No clinician review was available.
- Applying unreviewed synonyms would introduce unverified assumptions.

## Why 7I Had No Clear Winner
- 5 of 6 configurations achieved identical ceiling metrics (macro F1 = 1.0).
- The dataset's canonical noiseless symptom signatures (5–10 unique vectors per class) make near-perfect scores expected.
- Generalization to real patient variability remains unproven.

## Why 7K Could Not Establish External Validation
- No independent external dataset could map into a valid heldout set for the Phase 7I model.
- Coverage collapse across all candidate datasets.

## Why This Integration Is Non-Clinical
- External clinical validation was unavailable (Phase 7K: INSUFFICIENT_EXTERNAL_DATA).
- The model is labeled "NOT PRODUCTION" in its own metadata.
- Predictions are raw un-calibrated Logistic Regression outputs.
- The application clearly presents results as "Research/Educational Use Only."

## Model Integrated
- **Type:** LogisticRegression (scikit-learn 1.8.0)
- **Features:** 131
- **Classes:** 41
- **Source artifact:** `backend/ml/phase7i/models/experimental_best_model.joblib`
- **Installed as:** `backend/ml/model/experimental_disease_model.joblib`
- **Vocabulary:** `backend/ml/model/experimental_symptom_columns.joblib` (131 features, exact training-time order)

## API Changes
| Endpoint | Change |
|----------|--------|
| `GET /api/health` | Returns model metadata (type, version, feature_count, class_count, mode) |
| `GET /api/symptoms` | Returns 131 canonical symptom names in deterministic training-time order |
| `POST /api/predict` | Accepts `{"symptoms": [...]}`, validates, deduplicates, constructs 131-dim binary vector, returns top-5 predictions with disclaimer |

## Flutter Changes
- Disease prediction screen fetches symptoms from `GET /api/symptoms`.
- Dynamic symptom catalog replaces old 16-symptom mock list for production.
- Disclaimer displayed on prediction selection and result screens.
- Model score labeled "Experimental model score" (not "confidence").
- No medical claims in UI text.

## Tests
| Test Suite | Result |
|------------|--------|
| Backend pytest (21 tests) | PASS |
| Flask health endpoint | PASS |
| Flask symptoms endpoint (131 symptoms, no duplicates) | PASS |
| Flask valid prediction | PASS |
| Flask invalid symptom (HTTP 400) | PASS |
| Flask empty input (HTTP 400) | PASS |
| Flask duplicate input (PASS, deduplication) | PASS |
| Flask invalid JSON (HTTP 400) | PASS |
| Flask wrong data type (HTTP 400) | PASS |
| Prediction determinism (5x identical) | PASS |
| Flutter analyze | PASS (no issues) |
| Flutter test (23/23) | PASS |
| Debug APK build | PASS |

## Production Safety
- Original `disease_model.joblib` preserved, hash unchanged.
- Original `symptom_columns.joblib` preserved, hash unchanged.
- Original `disease_dataset_cleaned_v2.csv` preserved, hash unchanged.
- No dataset modifications.
- No model retraining or tuning.
- No unrelated backend changes.
- No unrelated Flutter changes.

## Rollback Procedure
1. Stop the Flask server.
2. In `backend/services/prediction_service.py`, change `DEFAULT_MODEL_PATH` to point to `disease_model.joblib` and `DEFAULT_SYMPTOMS_PATH` to point to `symptom_columns.joblib`.
3. Restart Flask.
4. The old Phase 7C Random Forest model (174 features, 46 classes) will be active again.
5. The Flutter app will need to fetch the old symptom vocabulary (the old mock list or the backend if reconfigured).

## Files Modified
### Backend
- `backend/services/prediction_service.py` — loads experimental model instead of old model
- `backend/routes/prediction_routes.py` — prediction and symptoms endpoints
- `backend/routes/health_routes.py` — health endpoint with model metadata
- `backend/config/config.py` — low confidence threshold config
- `backend/app.py` — model loading at startup

### Flutter
- `lib/features/disease_prediction/models/prediction_result.dart` — TopPrediction, Flask response parsing
- `lib/features/disease_prediction/services/flask_disease_prediction_service.dart` — fetch symptoms + predict via Flask
- `lib/features/disease_prediction/services/disease_prediction_service.dart` — fetchSymptoms contract
- `lib/features/disease_prediction/presentation/disease_prediction_screen.dart` — dynamic catalog, disclaimer
- `lib/features/disease_prediction/presentation/prediction_result_screen.dart` — result display
- `lib/features/disease_prediction/presentation/widgets/prediction_result_card.dart` — model score, top predictions
- `lib/core/constants/app_strings.dart` — disclaimer text, research labels
- `lib/features/disease_prediction/models/mock_symptoms.dart` — marked as test-only

### New Files
- `backend/ml/model/experimental_disease_model.joblib` — Phase 7I model
- `backend/ml/model/experimental_symptom_columns.joblib` — 131-feature vocabulary
- `backend/test_phase7j.py` — backend integration tests
- `backend/ml/phase7j/` — all Phase 7J records
