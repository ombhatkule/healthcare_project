# Phase 7H.1 Evidence Index

## Production safety (hash-verified, 2026-09-10)
| File | SHA-256 | Status |
|---|---|---|
| backend/ml/model/disease_model.joblib | f772b3b8a48e5e07196ee153e593a0e096e0f19875349ddb9dcfaf83895d16a6 | MATCH |
| backend/ml/model/symptom_columns.joblib | 9fea903cfcbdf2d02e1a37082d88d4cbcdd495a264bf59bf81eafd947d99332e | MATCH |
| backend/data/disease_dataset_cleaned_v2.csv | 5912fa31e8a2b22dbd65ad8d584482dc531154452f5b8881e9bb5d12cd2c2e50 | MATCH |

## Source-of-truth dataset
| File | SHA-256 |
|---|---|
| backend/ml/phase7g/acquired/symbipredict_2022.csv | 9834c90dd48eb2fef1fa56282f8f016a6781b0e4ada878015dc34a81af8e9e1b |

## Derived Phase 7H cleaned candidates (unchanged; not modified in 7H.1)
| File | Notes |
|---|---|
| backend/ml/phase7h/cleaned/symbipredict_cleaned.csv | 4,961 rows, normalized names |
| backend/ml/phase7h/cleaned/symbipredict_deduplicated.csv | Representation C, 304 rows |

## Analysis evidence consumed
- backend/ml/phase7h/analysis/symptom_mapping_review.json (EXACT 20 / HIGH 3 / POSSIBLE 8 / NO_MATCH 101)
- backend/ml/phase7h/analysis/duplicate_analysis.json (duplicate structure, conclusion: legitimate association repetition)
- backend/ml/phase7h/analysis/contradictory_patterns.json (0 contradictions)
- backend/ml/phase7h/analysis/representations.json (A/B/C/D)
- backend/ml/phase7h/analysis/leakage_analysis.json (grouped-split strategy)
- backend/ml/phase7h/analysis/separability_analysis.json (avg cosine 0.1067 raw / 0.1058 dedup)
- backend/ml/phase7h/validation/feature_analysis.json (fluid_overload constant; fluid_overload_1 signal 115)
- backend/ml/phase7h/validation/class_validation.json (5–10 unique vectors/class)
- backend/ml/phase7h/validation/phase7h_validation.json (aggregate validation + decision B)
- backend/ml/phase7h/validation/production_safety_check.json

## Misc
- Manual verification of `fluid_overload` vs `fluid_overload.1` values (0 vs 115 positives; equal 4,846/4,961) performed inline during Phase 7H; documented in feature_review.md.