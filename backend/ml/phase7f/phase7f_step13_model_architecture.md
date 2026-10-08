# Phase 7F Step 13 — Proposed Future Model Architecture (DESIGN ONLY, NOT IMPLEMENTED)

## Input
- **Symptom vocabulary:** backend-driven, canonical binary symptom flags (via GET /api/symptoms).
- **Representation:** binary multilabel vector aligned to a fixed, versioned feature order.
- **Minimum information:** enforce >= 5 symptoms for prediction, warn < 10 (per Step 9).

## Processing
- **Preprocessing:** feature-order alignment (reindex input to canonical vocabulary),
  missing/unknown symptom handling (ignore unknown; flag as invalid).
- **Feature validation:** reject/normalize unknown or duplicate symptom IDs.
- **Unknown symptom handling:** silently drop unknown IDs but warn; never shift feature order.

## Model
- **Proposed algorithm:** Random Forest with `class_weight='balanced'` (consistent with all
  experiments) OR Logistic Regression on a reduced, well-supported class subset.
- **Reason:** RandomForest was the strongest overall across formulations and is robust to
  binary features and imbalance; Logistic Regression simpler/interpretable.
- **Constraint:** only use classes with adequate support (>= 50-100 samples); drop or bucket
  extremely rare classes.

## Output
- **Top prediction:** single most-likely disease.
- **Top-5 predictions:** with raw scores for transparency.
- **Raw score handling:** present raw scores as "statistical similarity scores", NOT probabilities
  in a diagnostic sense; no thresholds presented as medical cutoffs.
- **Uncertainty / low-information behavior:** if < 5 symptoms or max score below a documented
  floor, return "Insufficient symptom information" with low-confidence disclaimer.
- **Disclaimer:** every output distinguishes **"statistical model output"** from **"medical diagnosis"**.

## Critical Principle
The system MUST present outputs as exploratory/educational statistical estimates and MUST NOT
claim to diagnose. This is a demonstration tool, not a clinical decision-support system.
