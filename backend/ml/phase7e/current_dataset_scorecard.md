# Current Dataset Suitability Scorecard

**Date:** 2026-09-08
**Dataset:** disease_dataset_cleaned_v2.csv
**Rows:** 100,000 | **Classes:** 46 | **Features:** 174

## Scorecard

| Category | Rating |
|----------|--------|
| Class Support Adequacy | **Critical problem** |
| Class Balance | **Critical problem** |
| Feature Discriminative Strength | **Weak** |
| Disease Separability | **Weak** |
| Rare-Class Evaluability | **Critical problem** |
| Consistency of Symptom Patterns | **Weak** |
| Suitability for Sparse User Inputs | **Weak** |
| Suitability for 46-Class Classification | **Critical problem** |
| Reproducibility/Documentation | **Unknown** |
| Medical/Clinical Provenance | **Unknown** |

## Summary

- Strong: 0
- Acceptable: 0
- Weak: 4
- Critical problem: 4
- Unknown: 2

## Overall Assessment

**Fundamentally unsuitable for reliable 46-class multiclass disease prediction**

## Evidence Details

### Class Support Adequacy — Critical problem

9 classes (19.6%) have fewer than 10 samples total. Smallest class has 1 sample(s). Train/test evaluation impossible for these classes.

### Class Balance — Critical problem

Imbalance ratio is 21295:1. Top 5 classes hold 55.41% of all data. Largest class (Asthma) has 21,295 samples; smallest has 1.

### Feature Discriminative Strength — Weak

Mean mutual information is 0.016966. Only 116 of 174 features have MI > 0.01. Top MI score is 0.054308. Assessment: B. Only a few symptoms provide useful discrimination.

### Disease Separability — Weak

Average pairwise cosine similarity is 0.6942 (std 0.1446). Many disease profiles are highly overlapping. Most similar pair (Generalized_Anxiety_Disorder, Pneumonia) similarity = 0.9598.

### Rare-Class Evaluability — Critical problem

7 classes have <5 samples (cannot even appear in both train and test). 2 more have 5-9 samples (insufficient for reliable evaluation).

### Consistency of Symptom Patterns — Weak

Every row has a unique feature vector (100000/100000). No repeated disease-symptom patterns exist. Active symptom count mean=28.5, std=13.5. Structure classification: weakly structured.

### Suitability for Sparse User Inputs — Weak

Empty vector predicts Migraine with 9.5% confidence (Phase 7D). Single symptom also predicts Migraine. Model cannot reliably handle the sparse inputs typical of real user interactions.

### Suitability for 46-Class Classification — Critical problem

Best macro F1 across all models is ~0.19 (LogReg). 46 classes with 27 classes having <50 samples makes 46-class classification infeasible.

### Reproducibility/Documentation — Unknown

No documentation found for how the dataset was generated or collected. No source attribution. No data dictionary. CSV structure is consistent but provenance is unknown.

### Medical/Clinical Provenance — Unknown

No documentation of clinical origin. No patient consent records referenced. No institutional review. Feature values appear to be binary symptom present/absent, but the mapping methodology is undocumented.
