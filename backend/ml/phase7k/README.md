# Phase 7K — Independent Generalization / External Validation

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Objective
Determine whether the Phase 7I experimental model (LR class_weight=None, 131 features, 41 classes; grouped-CV
macro F1 ≈ 1.000) has any evidence of external/generalization validity on a genuinely independent dataset.

## Input
- Phase 7I experimental model metadata: `backend/ml/phase7i/models/experimental_model_metadata.json`
- Phase 7I feature vocabulary: `backend/ml/phase7i/data/symptom_columns_131.json` (131 features)
- Phase 7I experimental data (reference only): `backend/ml/phase7i/data/symbipredict_representationC_131feat.csv`
- Phase 7I decision: `backend/ml/phase7i/outputs/phase7i_decision.json` (D — NO_CLEAR_WINNER)
- Candidate data (already acquired in Phase 7G, re-analyzed here):
  `backend/ml/phase7g/acquired/columbia_disease_symptom_kb.csv`,
  `.../symbipredict_2022.csv`, `.../kaushil268_disease_prediction.csv`

## External dataset source
**No usable external dataset selected.** Primary conditional candidate analyzed (only): Columbia University
Disease-Symptom Knowledge Database (real NYP discharge-note provenance, AMIA 2008 / PMC2656103; license UNKNOWN/pending).

## Preprocessing
None applied to any dataset (no fitting of preprocessors). Analysis was read-only:
- Normalization of Columbia disease/symptom names for mapping.
- Deterministic label/feature mapping (EXACT / HIGH_CONFIDENCE / POSSIBLE / NO_MATCH).
- Validation and coverage statistics computed via `scripts/phase7k_analysis.py`.

## Mappings
- Labels: 8 EXACT / 8 HIGH_CONFIDENCE / 3 POSSIBLE / 22 NO_MATCH (of 41) → see `mappings/label_mapping_full.csv`.
- Features: 14 EXACT / 10 HIGH_CONFIDENCE / 373 NO_MATCH (of 397 symptoms) → see `mappings/feature_mapping_full.csv`.
- No medical synonyms treated as approved (11 Phase 7H.1 candidates remain PENDING_CLINICIAN_REVIEW).

## Exclusions
- 22/41 labels with NO_MATCH excluded.
- 11 HIGH_CONFIDENCE/POSSIBLE mappings excluded (require clinician review; unavailable).
- 93.95% of Columbia symptoms excluded (no feature mapping).
- Resulting usable end-to-end observations: **0**.

## Evaluation protocol
Planned: no retraining/fine-tuning/tuning; Phase 7I model evaluated on independent data only.
Executed: **no evaluation** — no valid external test set could be constructed (coverage/representation collapse).

## Model used
Phase 7I experimental LR class_weight=None (131 features, 41 classes). **Not invoked.**

## Limitations
- No credible independent, case/patient-level, adequately-covered dataset obtainable.
- Columbia candidate blocked by license-pending status, aggregated association format, and low feature/label overlap.
- External generalization remains **untested**.

## Final decision
**C — INSUFFICIENT_EXTERNAL_DATA**

## Production safety result
**PASS** — `disease_model.joblib`, `symptom_columns.joblib`, `disease_dataset_cleaned_v2.csv` unchanged
(see `evidence/production_baseline_hashes.txt` vs `evidence/production_final_hashes.txt`).

## Contents
- `acquired/` — (no new acquisitions; analyses reference Phase 7G files)
- `data/` — (no new datasets)
- `mappings/` — label & feature mapping tables (full CSVs with statuses)
- `validation/` — analysis output JSON
- `evaluation/` — (empty by design; no evaluation performed)
- `predictions/` — (empty by design; no predictions made)
- `reports/` — dataset_candidates, selected_external_dataset, provenance_review, label_mapping, feature_mapping,
  validation_report, coverage_report, external_evaluation, error_analysis, phase7k_decision
- `outputs/` — `phase7k_decision.json`
- `evidence/` — candidate registry, dataset hashes, validation/mapping/coverage/leakage counts, evaluation record,
  reproducibility info, production baseline+final hashes
- `scripts/` — `phase7k_analysis.py`, `phase7k_evidence.py` (reproducible analysis)