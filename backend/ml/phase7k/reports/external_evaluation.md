# Phase 7K — External Evaluation

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Status: NO EXTERNAL EVALUATION PERFORMED

The Phase 7I experimental model (LR class_weight=None, 131 features, 41 classes) was **not invoked** on any external
dataset in Phase 7K.

## Why no evaluation could validly be run

Phase 7K rules require:
1. A credible, **independent** dataset (§3, §8).
2. Only **EXACT** label mappings used automatically (HIGH_CONFIDENCE/POSSIBLE require clinician review — §5).
3. Adequate **feature representation** in the 131-vocab (§6, §11).
4. No manufactured evidence (§17 final rule).

Each requirement fails for every obtainable candidate:
- **Columbia KB (only independent clinical candidate):** license pending; association-count (not case-level);
  22/41 labels NO_MATCH (only 8 EXACT automatically usable, 19.5%); feature mapping 6.05% of unique symptoms, and the
  8 EXACT-label diseases retain only 0–57% of their symptom evidence (4 of 8 ≤30%, 1 = 0%). → evaluation would be a
  coverage artifact.
- **SymbiPredict / kaushil268 / "Disease & Symptoms" Kaggle sets:** same canonical family (leakage — not independent).
- **"Disease and symptoms 2023" (246k rows):** artificially generated.
- **DDXPlus:** synthetic (Synthea + KB); categorical features/negative framing incompatible.
- **Brazil SINAN / HCMC dengue:** real but single-disease (Dengue) → 1/41 class coverage.
- **MIMIC-III:** no symptom-presence matrix; credentialed access.

## What was computed instead (transparently)
- Full validation of the Columbia candidate (integrity OK — see validation_report.md).
- Label mapping table: 8 EXACT / 8 HIGH / 3 POSSIBLE / 22 NO_MATCH (mappings/label_mapping_full.csv).
- Feature mapping table: 14 EXACT / 10 HIGH / 373 unmapped (mappings/feature_mapping_full.csv).
- Coverage & feasibility bounds (coverage_report.md).
- Content-independence (leakage) check: mean symptom-set Jaccard between Columbia and Phase 7I for shared
  EXACT-label diseases = **0.022** (range 0.000–0.071) → **no row/signature copying; sources are content-independent**.

## Reporting convention
Accuracy / Balanced Accuracy / Macro P-R-F1 / Weighted P-R-F1 / per-class metrics / confusion matrix:

> **NOT REPORTED** — no valid evaluation set exists. A "cross-dataset" table built from coverage-collapsed vectors
> would be a mapping artifact, not an external generalization result, and would violate the no-manufactured-evidence rule.

Evaluated class count: **0**.

## Clarification (Phase 7K §16)
Nothing about Phase 7I is called a failure here. The statement is only:
**The Phase 7I ceiling performance could not be tested against independent observations because no adequate
independent dataset was obtainable.**