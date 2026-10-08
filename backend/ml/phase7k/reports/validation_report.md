# Phase 7K — External Data Validation

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Dataset validated: Columbia University Disease-Symptom KB (COL-001)
Local: `backend/ml/phase7g/acquired/columbia_disease_symptom_kb.csv` · SHA-256 `51B81B8999B072768BB0692376BE1983F15B59A77A8EB5C95AF276FCBFA73A17`

| Check | Result |
|-------|--------|
| Rows | 1,858 |
| Columns | 3 (`disease`, `count_of_disease_occurrence`, `symptom`) |
| Missing values | 0.0% (all columns) |
| Duplicate rows | 0 |
| Duplicate (disease, symptom) pairs | 1 (single re-assertion; count aggregation unaffected) |
| Unique diseases (raw) | 134 |
| Unique diseases (normalized labels) | 134 |
| Unique symptoms | 397 |
| Invalid values | None observed (counts integer ≥ 0; zero-count rows: 0) |
| Contradictory observations | N/A — association-count format; each row is a single disease→symptom mapping with a note count, not a labeled observation with conflicts |
| Class support (associations/disease) | min 3, max 28; 3 diseases have <5 associations |
| Occurrence-count stats | min 42, median 141, max 3,363 |
| All-zero rows | 0 |
| All-one rows | N/A (binary matrix form not used) |
| Symptom-count distribution | 3–28 associations per disease (see per-class table in `evidence/coverage_feasibility_per_disease.json` for mapped subset) |

## Exclusions
For external evaluation, observations are excluded NOT because of malformation but because of mapping/coverage:

| Reason | Count excluded |
|--------|----------------|
| External diseases with NO_MATCH to the 41 Phase 7I labels | 22/41 labels (114 of 134 Columbia diseases → 1,610 of 1,858 rows) |
| External diseases with POSSIBLE mapping (require review) | 3 labels (chronic alcoholic intoxication, biliary calculus, oral candidiasis) |
| External diseases with HIGH_CONFIDENCE mapping (require review) | 8 labels |
| Symptoms with NO_MATCH to the 131-feature vocabulary | 373/397 symptoms (≈80% of association rows) |
| **Total usable observations for an automatic evaluation** | **see coverage_report.md — none are usable end-to-end** |

## Integrity conclusion
The Columbia KB is internally consistent (no missingness, no malformed rows, no contradictions). The blocker is
**mapping adequacy**, not data quality. Observations are validly documented "aggregated clinical associations",
but they are (a) not case/patient-level, (b) license-pending, and (c) only partially representable in the 131-feature
space — so they cannot support a valid external generalization metric.