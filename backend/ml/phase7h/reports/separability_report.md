# Phase 7H — Separability Report

Class-mean symptom-profile cosine similarity (structural, not clinical validity).

| Representation | Avg cosine | Median | Min | Max | Pairs |
|---|---|---|---|---|---|
| Raw 4,961 rows | 0.106681 | 0.0 | 0.0 | 0.829611 | 820 |
| Dedup 304 assoc | 0.105753 | 0.0 | 0.0 | 0.825573 | 820 |

## Most similar pairs (raw)

- Hepatitis D <-> Hepatitis E: 0.829611
- Hepatitis A <-> Hepatitis D: 0.797711
- Chronic Cholestasis <-> Hepatitis D: 0.755929
- Chronic Cholestasis <-> Hepatitis A: 0.679854
- Hepatitis C <-> Hepatitis D: 0.679089
- Tuberculosis <-> Pneumonia: 0.6668
- Hepatitis A <-> Hepatitis E: 0.663341
- Malaria <-> Typhoid: 0.635729

## Least similar pairs (raw)

- Fungal Infection <-> Allergy: 0.0
- Fungal Infection <-> GERD: 0.0
- Fungal Infection <-> Peptic Ulcer Disease: 0.0
- Fungal Infection <-> AIDS: 0.0
- Fungal Infection <-> Diabetes: 0.0
- Fungal Infection <-> Gastroenteritis: 0.0
- Fungal Infection <-> Bronchial Asthma: 0.0
- Fungal Infection <-> Hypertension: 0.0

**Finding:** dedicated counts reproduce Phase 7G (~0.107 raw). Deduplication does not
materially change separability, confirming separability is a property of the association
table, not of repetition counts.

Machine data: `analysis/separability_analysis.json`

