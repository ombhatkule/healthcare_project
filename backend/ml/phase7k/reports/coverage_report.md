# Phase 7K — Coverage Report

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## 1. Feature coverage (Columbia symptoms → 131-vocab)
| Metric | Value |
|--------|-------|
| Unique Columbia symptoms | 397 |
| EXACT matches | 14 (3.53%) |
| HIGH_CONFIDENCE matches | 10 (2.52%) |
| Mapped unique symptoms (EXACT+HIGH) | 24 (6.05%) |
| Unmatched symptoms | 373 (93.95%) |
| Distinct 131-vocab features covered | 20 / 131 (15.3%) |
| Association-row coverage (EXACT+HIGH) | 19.97% |

## 2. Label coverage (41 Phase 7I labels → Columbia diseases)
| Metric | Value |
|--------|-------|
| EXACT | 8 (19.5%) |
| HIGH_CONFIDENCE | 8 |
| POSSIBLE | 3 |
| NO_MATCH | 22 (53.7%) |
| Automatically usable (EXACT only) | 8 / 41 |

## 3. End-to-end usable observations
Per-disease feasibility for EXACT-label diseases, using only EXACT+HIGH_CONFIDENCE feature mappings:

| Disease | Columbia assoc. | Mapped usable feats | Signal retained |
|---------|-----------------|---------------------|-----------------|
| Arthritis | 10 | 3 | 30.0% |
| Diabetes | 14 | 8 | 57.1% |
| Gastroenteritis | 11 | 2 | 18.2% |
| Hepatitis B | 9 | 0 | 0.0% |
| Hepatitis C | 11 | 2 | 18.2% |
| Hypoglycemia | 10 | 1 | 10.0% |
| Hypothyroidism | 21 | 7 | 33.3% |
| Pneumonia | 19 | 5 | 26.3% |

- 8 EXACT-label diseases, but **1 retains 0%** of its evidence and **4 retain ≤30%**.
- No disease retains more than 57% of its Columbia symptom evidence.
- Effective "usable observations": **0** — no external case can be represented with sufficient fidelity to produce a
  meaningful prediction, and high-confidence/POSSIBLE mappings cannot be used without clinician review.

## 4. Coverage-vs-performance separation (no conflation)
- **Model performance:** not computable → no external metrics were produced.
- **Coverage limitation:** quantified above (label 19.5% automatic; feature 6.05% unique / 19.97% row; worst-case
  per-disease evidence loss 43–100%).
- These two are kept strictly separate per Phase 7K §11. Poor coverage is documented as a dataset/feasibility
  limitation, and it is the reason no "model failure" claim is made or implied for the Phase 7I model.

## 5. Conclusion
Coverage is far below what would make an external evaluation meaningful:
- **Feature coverage:** 6.05% of unique symptoms (≤57% of evidence per disease, most ≤30%).
- **Label coverage:** 19.5% automatic.
- **Observation type:** aggregated associations, not patient cases.
- **License:** pending.

**Outcome: C — INSUFFICIENT_EXTERNAL_DATA.**