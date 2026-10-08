# Dataset Requirements for a Better Disease Prediction Dataset

**Phase:** 7E Step 4
**Date:** 2026-09-08

## Purpose

This document defines objective requirements for any dataset that would replace or
improve upon the current `disease_dataset_cleaned_v2.csv` (46 classes, 174 binary
features, 100,000 rows â€” shown in Phase 7D/E to be fundamentally unsuitable for
reliable multiclass prediction due to extreme imbalance, weak feature discrimination,
and low disease separability).

---

## MUST HAVE

These are non-negotiable. A dataset failing any of these is automatically rejected.

1. **Identifiable target column.** A clear disease/condition label column must exist.
   Without this, supervised classification is impossible.

2. **Documented source/provenance.** The dataset must state where it came from
   (medical records, published research, government survey, etc.). Unknown origin is grounds for rejection.

3. **Usable documentation.** There must be enough documentation to understand:
   - what each feature/symptom column means
   - how values are encoded
   - how the target is defined
   - any known limitations or biases

4. **Meaningful feature-label relationship.** Features must have observable variation
   across classes (assessed via mutual information, separability metrics). Features that
   are near-random or identical across all classes cannot support classification.

5. **Accessible/verifiable.** We must be able to actually obtain and inspect the data
   without credentials or access restrictions that we cannot meet.

6. **No fabricated records added by THIS project.** The dataset itself must exist
   independently of this project and not be invented here.

---

## SHOULD HAVE

These are strongly preferred.

1. **Adequate per-class support.** At minimum, the vast majority of classes should
   have enough samples for meaningful train/test evaluation (e.g., â‰¥ 50-100 per class
   so a test set of 20% provides â‰¥ 10-20 test samples per class).

2. **Limited class imbalance.** Imbalance ratio should ideally be < 100:1, or at minimum
   there must be a documented strategy for handling imbalance (resampling weights, etc.).

3. **Consistent feature/symptom mapping.** Symptoms should map consistently to named
   concepts that can be translated to the Flask prediction API and (eventually) to
   user-facing Flutter symptom selectors.

4. **Sparse-input tolerance.** The dataset should contain records with a realistic mix
   of symptom counts (including low-symptom records), since real user inputs are often
   sparse generic symptom sets.

5. **Feature interpretability.** Binary or ordinal interpretable features are easier to
   map to the existing API than opaque embeddings or high-dimensional dense vectors.

6. **Permitted usage.** License/terms should permit research and educational model
   training without reaching out for special permission.

---

## NICE TO HAVE

These improve quality but are not required.

1. **Medically validated or clinically sourced data** with clear documentation of
   medical review. (Not required because such datasets are rare and may be restricted.)

2. **Multiple related conditions** that span both common and rare diseases to allow
   studying extreme class behavior.

3. **Natural-language symptom descriptions** in addition to structured binary features,
   enabling potential future NLP-based input.

4. **Patient demographics/demographic features** (age, sex, etc.) if appropriate and
   de-identified.

5. **Pre-split train/test** so results are reproducible and directly comparable.

---

## Automatic Rejection Conditions

A candidate is rejected outright if ANY of these apply:

- No identifiable target column.
- Unknown or unverifiable source/provenance.
- Documentation unusable (can't understand columns or labels).
- Only a handful (e.g., < 20) of records for most classes.
- No meaningful relationship between features and labels (e.g., features near-random,
  MI â‰ˆ 0 across features, no class variation).
- Inaccessible or unverifiable data (requires credentials/restrictions we can't meet).
- Incompatible licensing (e.g., commercial-prohibition that conflicts with project use).
- Eventual substitution would eliminate MORE symptoms/classes than it gains, or
  would require losing the current disease vocabulary entirely without a clear win.

---

## Rationale (rooted in current dataset failures)

The current dataset fails several Must Haves and most Should Haves:

- **Provenance:** Unknown â€” no source attribution found (rating: Unknown).
- **Class support:** 7 classes have < 5 samples; 9 have < 10 samples (19.6% of classes).
- **Imbalance:** 21,295:1 ratio; top-5 classes hold 55.4% of data.
- **Feature discrimination:** only 116/174 features exceed MI > 0.01; mean MI = 0.017.
- **Separability:** average pairwise cosine similarity = 0.694 (weakly separable).
- **Sparse inputs:** empty/near-empty vectors predict Migraine with ~9-11% confidence.

These concrete deficiencies drive the requirements above.
