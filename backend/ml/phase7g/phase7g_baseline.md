# Phase 7G Baseline

**Date:** 2026-09-09
**Phase:** 7G — Approved Dataset Acquisition & Verification

## Previous Decisions Referenced

- **Phase 7E:** Current dataset fundamentally unsuitable for 46-class prediction. 8 candidates identified via web search but NONE downloaded or verified.
- **Phase 7F:** OPTION 4 — Stop disease classification until a better dataset is obtained.
- Phase 7E/7F established: unknown provenance, extreme imbalance (21,295:1), 9/46 classes <10 samples, weak MI (~0.017), weak separability (cosine 0.694), sparse-input bias.

## Phase 7G Scope

DATA ACQUISITION AND VALIDATION ONLY.

- No ML model training
- No Flask changes
- No Flutter changes
- No API changes
- No deployment
- No Phase 8 start
- No production model replacement
- No production dataset modification

## Requirements Summary (from Phase 7E/7F)

### MUST HAVE
1. Identifiable target column (disease/condition label)
2. Documented source/provenance
3. Usable documentation (features, encoding, target, limitations)
4. Meaningful feature-label relationships (MI well above ~0.017)
5. Accessible/verifiable without unauthorized access
6. Not fabricated by this project

### SHOULD HAVE
1. Most classes >= 50-100 samples
2. Imbalance ratio < 100:1
3. Consistent symptom features mappable to API
4. Sparse-input tolerance
5. Feature interpretability (binary/ordinal)
6. Permitted usage

### REJECT IF
- Unknown/unverifiable provenance
- Unclear target labels
- Unusable documentation
- Most classes < 20 samples
- No feature-label discrimination
- Inaccessible or unauthorized
- Incompatible licensing
- Would eliminate more symptoms/classes than gained
- Obvious fabrication/synthetic without clinical basis

## Current Dataset (for comparison baseline)
- 46 diseases, 174 binary symptoms, 100,000 rows
- Imbalance ratio: 21,295:1
- 9 classes with <10 samples
- 7 classes with <5 samples
- Mean MI: 0.017
- Average cosine similarity: 0.694
- Provenance: Unknown
- Rating: Fundamentally unsuitable
