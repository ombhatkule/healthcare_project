# Phase 7F Step 14 — Dynamic Symptom Vocabulary Design (DESIGN ONLY, NOT IMPLEMENTED)

Replaces hard-coded `MockSymptoms.all` with a backend-driven symptom vocabulary.

## Conceptual Flow

```
Flutter
   ↓ GET /api/symptoms
Flask → returns supported symptom list (id, name, label)
   ↓ user selects symptoms
Flutter
   ↓ POST /api/predict with symptom ids
Flask → maps ids → canonical feature vector → model → response
```

## API Compatibility

- **GET /api/symptoms** → `{ "symptoms": [ { "id": "symptom_cough", "name": "Cough" }, ... ] }`
- **POST /api/predict** → accepts `{ "symptoms": ["symptom_cough", "symptom_headache"], ... }`
  (list of canonical ids) instead of a pre-built vector.

## Symptom ID / Name Strategy

- **Backend canonical name:** the model's feature name, e.g., `symptom_cough`.
- **Display label:** human-readable, e.g., "Cough" — stored in a metadata table, decoupled
  from the internal id.
- **Frontend uses id** for selection, label for display. Never sends labels to predict.

## Display Labels

- Maintained in backend metadata (not hard-coded in Flutter).
- Flutter renders whatever `/api/symptoms` returns → frontend stays agnostic to vocabulary.

## Backend Canonical Names

- Exactly match `symptom_columns.joblib` order (or a documented versioned ordering).
- When the model vocabulary changes, the metadata updates and the API reflects it.

## Invalid Symptom Handling

- Unknown ids → Flask returns a 400/422 with the invalid ids listed; does NOT silently guess.
- Unknown labels (display) → never sent to backend; only ids are accepted.

## Duplicate Symptom Handling

- Deduplicate input ids server-side (a set), then build the binary vector (1 if present).
- Duplicate ids have no effect on the vector.

## Empty Input Handling

- Empty symptom list → return 422 "Insufficient symptom information" (per Step 9 policy),
  OR a structured low-confidence response. Never predict with an all-zero vector as if meaningful.

## Future Feature-Order Preservation

- Vector is built by mapping ids to a **versioned** canonical order.
- If the model is retrained with a new vocabulary, a **vocabulary version** is stored and
  returned with predictions so the client and server always agree on feature semantics.
