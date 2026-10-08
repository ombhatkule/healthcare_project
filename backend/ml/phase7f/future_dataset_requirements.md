# Phase 7F Step 16 — Future Dataset Requirements (refined from 7E)

## MUST HAVE
1. **Documented provenance** — clear source (records, research, survey, validated reference).
2. **Adequate class support** — most classes >= 50-100 samples for meaningful train/test.
3. **Meaningful feature-label relationships** — measurable MI/non-overlap between features and classes;
   NOT near-random features (mean MI well above the current ~0.017).
4. **Interpretable symptom features** — binary/ordinal, mappable to the API vocabulary.
5. **Clear target labels** — well-defined disease/condition target.
6. **Reproducible structure** — documented feature order, encoding, and preprocessing.
7. **Usable licensing/access** — can legally and technically use the data.

## SHOULD HAVE
1. **Balanced classes** — imbalance ratio preferably < 100:1.
2. **Repeated/representative patterns** where appropriate — NOT 100% unique rows with no
   repeating disease-symptom patterns (unlike the current dataset).
3. **Sufficient samples per class** — at least a few hundred for stable evaluation.
4. **Clearly documented preprocessing** — how features were derived/encoded.

## REJECT IF
- Provenance is **unknown**.
- Labels are **unverifiable**.
- Most classes have **tiny sample counts** (< 20).
- Features show **no meaningful discrimination** (MI ~ 0, no class variation).
- Data cannot be **legally/technically used**.
- Data is **obviously fabricated or manually invented** (e.g., synthetic-style with no
  validating clinical basis for the task we need).
