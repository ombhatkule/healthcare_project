# Phase 7I — Dataset Limitations

**Non-clinical research/educational evaluation; not clinically validated.**

## 1. 304 unique associations, not 304 patients
Representation C contains exactly **one canonical symptom vector per (disease, variant) association** (5–10 per class). These are **not independent clinical observations**:
- No patient-level noise, comorbidity, reporting error, or demographic spread.
- The original 4,961-row file is the same 304 associations repeated (up to ×91) in association-format; it must not be treated as 4,961 patient samples.

## 2. Small per-class support
- 41 classes with support 5–10 vectors (min 5: AIDS, Acne, Allergy, Fungal Infection, Gastroenteritis, Heart Attack, UTI, Paralysis).
- Per-class uncertainties are high; a single vector change can move an entire class's group-CV cell.
- Macro metrics on 5-fold grouped CV rest heavily on the smallest classes.

## 3. Canonical, noiseless signatures ⇒ ceiling results
- The perfect grouped-CV results reflect that the class signatures are essentially **fully separable in this representation** (avg vector cosine ≈ 0.106, Phase 7H) — not that the model generalizes to real patient variability.
- Likely to **over-estimate** real-world discrimination; out-of-distribution input (novel symptom combinations) is untested.

## 4. Provenance
- Community-curated symptom→disease association dataset (Mendeley, DOI `10.17632/dv5z3v2xyd.1`, CC BY 4.0). **CONDITIONAL** provenance: not established as a clinical patient cohort (per Phase 7H.1).

## 5. Synonym ambiguity
- 11 flagged synonym mappings (3 high-confidence, 8 possible) remain **PENDING_CLINICIAN_REVIEW**. The 131-feature vocabulary keeps synonym-ish columns distinct (e.g., `stomach_pain`/`belly_pain`/`abdominal_pain`). Not merging conserves exclusivity of the mapping review.

## 6. Duplicate feature artifact removed
- `fluid_overload` (all-zero duplicate of `fluid_overload_1`) removed per Phase 7H.1; its twin retained.

## 7. Comparison with the old production benchmark
- The previously documented Phase 7C production metrics (accuracy 0.32015, macro F1 0.198602, weighted F1 0.329881) come from a **different dataset and different evaluation protocol** (100k-row current dataset, ungrouped). They are **historical context only** — Phase 7I does not claim an "X% better" result against them.

## 8. Evaluation ceiling and winner rule
- Since 5 of 6 model configurations tie at the ceiling, no single experimental model is selected (**NO_CLEAR_WINNER**), and no deployment or integration was performed.

## Bottom line
- The dataset supports a research/educational benchmark of model behavior on canonical symptom signatures.
- It does **not** support claims of clinical validity, diagnosis-readiness, or real-world medical accuracy.