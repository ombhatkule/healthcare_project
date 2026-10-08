# Phase 7J — API Validation Report

**Date:** 2026-09-10  
**Status:** ALL TESTS PASS

## Endpoints Tested

### GET /api/health
- **Status:** 200 OK
- **Returns:** API status, model metadata (type, version, feature_count, class_count, mode)
- **Model status:** loaded
- **Model type:** LogisticRegression
- **Feature count:** 131
- **Class count:** 41
- **Mode:** research_educational_experimental

### GET /api/symptoms
- **Status:** 200 OK
- **Returns:** 131 symptom names in deterministic training-time order
- **Duplicates:** None
- **Count:** 131
- **First 5:** itching, skin_rash, nodal_skin_eruptions, continuous_sneezing, shivering
- **Last 3:** blister, red_sore_around_nose, yellow_crust_ooze
- **fluid_overload:** ABSENT
- **fluid_overload_1:** PRESENT

### POST /api/predict
- **Status:** 200 OK (valid input)
- **Returns:** disease, score, confidence_status, top_predictions (5), disclaimer
- **Disclaimer present:** YES
- **Score type:** Raw Logistic Regression probability (un-calibrated)
- **Research disclaimer included:** YES

## Input Validation Tests

| Test Case | Input | Expected | Result |
|-----------|-------|----------|--------|
| Valid prediction | `["high_fever","cough","fatigue","headache","nausea"]` | HTTP 200 | PASS |
| Unknown symptom | `["itching","fake_xyz"]` | HTTP 400 | PASS |
| Empty symptom list | `[]` | HTTP 400 | PASS |
| Duplicate symptoms | `["itching","itching","cough","cough","cough"]` | HTTP 200 (dedup) | PASS |
| Invalid JSON | `not valid json` | HTTP 400 | PASS |
| Wrong data type | `{"symptoms":"itching"}` (string, not list) | HTTP 400 | PASS |

## Determinism Test

Same input submitted 5 times → identical disease prediction each time.  
**Result:** PASS

## Notes

- The `confidence_status` field is an engineering heuristic based on a configurable threshold (default 0.5). It is NOT a medical reliability measure.
- The `score` is the raw Logistic Regression class probability. It is NOT a calibrated medical probability.
