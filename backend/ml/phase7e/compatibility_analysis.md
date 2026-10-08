# Compatibility Analysis for Candidate Datasets

**Phase:** 7E Step 7
**Date:** 2026-09-08

## Current System Blueprint

- **Flutter app:** exposes only 16 generic selectable symptoms (one mapping, `muscle_pain`, is invalid).
- **Flask API:** `/api/symptoms` returns the 16 symptoms; prediction endpoint expects a 174-feature vector.
- **Backend model vocabulary:** 174 binary symptom features (`symptom_*` and `rare_symptom_*`).
- **Prediction response:** `{disease, confidence, ...}` JSON compatibility is required.

---

## Compatibility Question Matrix

### A. Would candidate features map naturally to the current symptom concept?

| Candidate | Mapping Fit | Explanation |
|-----------|-------------|-------------|
| Kaggle Kaushil268 (132 binary symptoms) | **Good** | Binary symptom columns map naturally; names like `itching`, `cough`, `skin_rash` are interpretable |
| Community Healthcare (174 symptoms) | **Perfect â€” but likely same/sibling dataset** | Matches project's 174 features / 46 diseases exactly; may be the original source of current data |
| Symptom2Disease (text descriptions) | **Poor** | Requires NLP feature extraction; not direct binary symptom vector |
| IEEE Disease Prediction (1325 symptoms) | **Fair** | MedLinePlus-referenced but very large vocabulary; mapping effort high |
| UCI Early Stage Diabetes | **Partial** | Diabetes-only symptoms; not a general disease dataset |
| CDC Diabetes Indicators | **Poor** | Survey/lifestyle features rather than physician symptoms |

### B. Would it require a new feature vocabulary?

- **Yes** for every candidate that differs from the current 174 features.
- Kaushil268 (132), Symptom2Disease (NLP), IEEE (1325) all introduce different vocabularies.
- Only Community Healthcare matches the existing 174-feature vocabulary (but is likely synthetic-style â€” see below).

### C. Would `/api/symptoms` need to expose a different list?

- **Yes** for any adopted dataset with a different vocabulary. The Flask endpoint would need updating.
- If we adopted Kaushil268 (132 symptoms), `/api/symptoms` would grow/change and the Flutter symptom list would need to change too.

### D. Would Flutter need dynamic symptom loading?

- **Recommended** regardless of dataset. Currently Flutter hard-codes 16 symptoms; dynamic loading
  from `/api/symptoms` decouples the frontend from any specific feature vocabulary.
- This is a forward-looking change that would ease any dataset migration.

### E. Would it require a different prediction schema?

- **No** for column-format datasets (binary-in, label-out). The `{disease, confidence}` schema is unchanged.
- **Yes** for text datasets (Symptom2Disease) which require textâ†’features â†’ NLP pipeline, breaking the simple binary-vector API.

### F. Could a new model remain compatible with the current API response format?

- **Yes** â€” as long as we retain a `predict(feature_vector) â†’ {disease, probability}` interface.
- The internal model can change; the response format stays stable. This is the recommended integration path.

---

## Key Findings

1. **Most candidates require a NEW feature vocabulary**, meaning Flutter symptom lists,
   `/api/symptoms`, and the model's `symptom_columns` would all need to change.

2. **The only candidate matching current structure (Community Healthcare â€” 174 symptoms / 46 diseases)
   is explicitly labeled "simulated"** â€” it is very likely the same synthetic-style data this project
   already uses, so adopting it provides no real improvement.

3. **Dynamic symptom loading is the single most important future compatibility improvement** â€”
   it decouples the app from any fixed vocabulary.

4. **The API response contract (disease + confidence) is stable** and would survive a model change.

---

## Recommended Compatibility Strategy (NOT implemented)

- Introduce **dynamic symptom loading** in Flask so `/api/symptoms` returns the model's actual vocabulary.
- Update **Flutter** to fetch symptoms from the API instead of hard-coding 16.
- Keep the **prediction response schema** unchanged (`{disease, confidence, ...}`).
- When a better dataset/model is adopted, only swap the model internals + vocabulary metadata.
