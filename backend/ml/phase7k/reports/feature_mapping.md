# Phase 7K — Feature (Symptom) Mapping

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Objective
Map the 397 unique Columbia UMLC symptom names to the Phase 7I 131-feature vocabulary
(`backend/ml/phase7i/data/symptom_columns_131.json`), with explicit statuses. Nothing was invented; only the
11 Phase 7H.1 synonym candidates remain PENDING_CLINICIAN_REVIEW and none were treated as approved.

## Mapping method (deterministic, documented)
1. Normalization: lowercase, strip punctuation, collapse spaces; singular-stem variation.
2. EXACT: normalized/stemmed string equality with a vocabulary feature.
3. HIGH_CONFIDENCE: explicit curated synonym table (e.g., `dyspnea → breathlessness`, `pruritus → itching`,
   `anorexia → loss_of_appetite`, `diarrhea → diarrhoea`, `fever → high_fever`, `pain chest → chest_pain`,
   `syncope/vertigo → dizziness`, `asthenia → fatigue`, `palpitation → palpitations`, `jaundice → yellowish_skin`).
4. POSSIBLE: fuzzy matches (difflib, cutoff 0.88) requiring review.
5. NO_MATCH: everything else.

Full table: `backend/ml/phase7k/mappings/feature_mapping_full.csv`

## Results (unique Columbia symptoms)

| Status | Count | % of 397 |
|--------|-------|----------|
| EXACT | 14 | 3.53% |
| HIGH_CONFIDENCE | 10 | 2.52% |
| POSSIBLE | 0 | 0.00% |
| NO_MATCH | 373 | 93.95% |
| **Mapped (EXACT + HIGH)** | **24** | **6.05%** |

## Feature-space view
- Distinct Phase 7I vocabulary features covered by any mapped Columbia symptom: **20 / 131 (15.3%)**.
- 111 of 131 Phase 7I features can never occur in any Columbia-derived vector.
- Association-row coverage (fraction of the 1,858 Columbia rows whose symptom maps EXACT or HIGH): **19.97%** —
  ~80% of Columbia associations are fully dropped.

## Per-disease signal retention (EXACT-label diseases only, using EXACT+HIGH_CONFIDENCE features)
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

1 of 8 diseases would retain 0% of its symptoms; 4 of 8 retain ≤30%. The best case (Diabetes) retains 57%.

## Interpretation
This is a **feature/label coverage limitation**, not a model failure (Per Phase 7K §11). With ≤57% of external
symptom evidence surviving and 15.3% of the model's feature space representable, any Columbia→7I vector would be a
severe projection of the Columbia data onto a largely non-overlapping vocabulary. Metrics computed from such vectors
would be dominated by mapping loss and would not measure generalization. Hence **no evaluation was performed**.