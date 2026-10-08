# Phase 7K — Error Analysis

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Status: NOT APPLICABLE (no external predictions were made)

No external evaluation was performed (see external_evaluation.md), so there are no external prediction errors,
confusion patterns, or confidence distributions to analyze.

## What this file documents instead

**Why no predictions exist:** the only genuinely independent, clinically-sourced candidate (Columbia KB) cannot be
represented in the Phase 7I 131-feature space with sufficient fidelity:
- 93.95% of Columbia symptoms have no mapping to the 131-feature vocabulary.
- For the 8 EXACT-label diseases, retained symptom evidence is 0–57% (one disease 0%, four ≤30%).
- 111 of 131 Phase 7I features could never be activated by any Columbia-derived vector.

Running the model here would produce confidences on coverage-collapsed (near-empty) vectors. Any errors or patterns
found would be attributable to mapping loss, not to genuine disease confusion — so they would be misleading.

## Predictions / confidence claims
- Number of external predictions made: **0**
- Prediction confidence analysis: **NOT PERFORMED**

## Also out of scope
- Repeated prediction patterns, dominant predicted class, and systematic re-labeling of external cases:
  **NOT EVALUATED** (no valid external labeling exists to compare against).
- Per-class precision/recall/F1 and confusion matrix on external data: **NOT APPLICABLE**.

## Relevant cross-check that WAS performed (leakage independence)
Mean symptom-set Jaccard (Columbia vs Phase 7I `symbipredict_representationC_131feat.csv`) over shared EXACT-label
diseases = **0.022** — confirming the two sources are content-independent; the absence of overlap is itself the reason
the vocabularies do not align, which is precisely what makes the external evaluation infeasible.