# Phase 7F Step 15 — Muscle-Pain Mapping Issue (DOCUMENTATION ONLY)

## The Mismatch

- **Flutter** exposes a symptom `muscle-pain`.
- **Backend/model** vocabulary does **NOT** contain `symptom_muscle_pain` in
  `symptom_columns.joblib`. (Verified: False)

## Implication

- When a user selects `muscle-pain` in Flutter, the backend has no corresponding feature.
- Currently this either maps to nothing or to a wrong feature — an unresolved mapping defect.

## Resolution Constraint (this phase)

- Do NOT invent a replacement feature.
- Do NOT change the model.
- Do NOT change Flutter.

## Future Integration Issue

- This is a **future integration defect** to be resolved when the dynamic symptom vocabulary
  (Step 14) is implemented: the vocabulary/metadata must either include a valid canonical
  muscle-pain feature, or the Flutter option must be mapped to an existing valid feature or
  removed from the exposed list.
- The mismatch highlights the broader need for a single source of truth for symptom vocabulary
  (backend authoritative list consumed by Flutter), rather than two independently-maintained lists.
