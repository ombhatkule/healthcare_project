# Phase 7I — Preprocessing Report

**Non-clinical research/educational evaluation; not clinically validated.**

## Input
- Dataset: `backend/ml/phase7h/cleaned/symbipredict_deduplicated.csv` (SymbiPredict Representation C, approved in Phase 7H)
- Dataset SHA-256: `8396a6644296c43daa12df521632393265c98878c930de247b746b77c7b6e8bc`
- Rows: 304 | Columns: 133 (132 features + target `prognosis`) | Classes: 41

## Transformations applied
- Target column: `prognosis` (kept as-is)
- Removed constant feature: **`fluid_overload`** (all-zero, duplicated-header artifact approved for removal in Phase 7H.1)
- Feature count after removal: **131**
- **No** synonym mappings applied (all 11 Phase 7H.1 candidates remain `PENDING_CLINICIAN_REVIEW`)
- **No** data augmentation, no synthetic rows, no duplication

## Deterministic feature vocabulary
- File: `backend/ml/phase7i/data/symptom_columns_131.json`
- Feature order taken exactly from Representation C after dropping `fluid_overload`
- Vocabulary SHA-256: `88da86895db4f73acf80b572606fcbdbb5a798a260042581370cb7c27e12618d`

## Validation results
| Check | Result |
|---|---|
| All features binary (0/1) | true |
| Missing values | 0 |
| NaN | 0 |
| Infinity | 0 |
| Duplicate rows | 0 |
| Contradictory vectors (same vector -> >1 class) | 0 |
| Unique feature vectors | 304 |
| Constant features before removal | `fluid_overload` only |
| Constant features after removal | none |
| Classes | 41 |
| Min / max support | 5 / 10 |
| Imbalance ratio (max/min) | 2.0 |
| Active symptoms per vector (min / max / mean / median) | 3 / 17 / 7.65 / 7.0 |

## Outputs
- `data/symptom_columns_131.json` — deterministic 131-feature vocabulary
- `data/symbipredict_representationC_131feat.csv` — processed dataset (SHA-256 `0f60f9816c9996a16d39a8845d9ff1efcdfabbdb6dbb7e3bf78efd795aef69e4`)
- `validation/phase7i_preprocessing.json` — machine-readable preprocessing record

## Notes
- 304 rows are **unique associations**, not 304 patients and not clinical observations.
- The Phase 7H cleaned dataset was not modified; all Phase 7I data artifacts live under `backend/ml/phase7i/`.