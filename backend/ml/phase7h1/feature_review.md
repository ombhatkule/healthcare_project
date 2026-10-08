# Phase 7H.1 — Constant-Feature Review: `fluid_overload`

## Findings (from Phase 7H evidence)

| Check | Result |
|---|---|
| Positive values in `fluid_overload` | **0** (all-zero / constant) |
| Positive values in `fluid_overload_1` | **115** (all for `Alcoholic Hepatitis`) |
| `fluid_overload` constant? | **Yes** (zero variance) |
| `fluid_overload_1` constant? | No (carries signal) |
| Equality of the two columns | Equal on 4,846/4,961 rows; differ only because `fluid_overload` is always 0 while `fluid_overload_1` is 1 in 115 Alcoholic-Hepatitis rows |
| Column names | Raw source header contains `fluid_overload` twice (`fluid_overload` + pandas-appended `fluid_overload.1`); normalized to `fluid_overload` / `fluid_overload_1` |
| Source metadata explaining them | None found in Mendeley record or local artifacts |

## Interpretation
The `.1`/`_1` suffix is a **duplicate column-name artifact** from a CSV header containing
`fluid_overload` twice (pandas dedup suffix). It does **not by itself prove** the two columns
denote identical medical meaning. However, the data structure (one all-zero copy + one
signal-bearing copy of the *same named symptom*) is consistent with an accidental duplicate
column whose blank copy was retained.

## Does dropping `fluid_overload` change other features?
- No other feature is affected; no column-name collisions occur after removal.
- Feature count would go 132 → 131 for the training vocabulary.
- No downstream linkage exists (production `symptom_columns.joblib` is untouched).

## Decision
**REMOVE_CONSTANT_FEATURE** — for Phase 7I only, remove `fluid_overload` (all-zero constant,
zero variance, no class discriminative value) **with this documented reason**.
- The Phase 7H cleaned datasets (`backend/ml/phase7h/cleaned/*`) are **not modified** in Phase 7H.1.
- Removal is a **Phase 7I preprocessing decision**, recorded now; the 131-feature vocabulary
  must be regenerated deterministically in Phase 7I and reported.
- `fluid_overload_1` is retained (non-constant, carries signal). Its name is kept as-is;
  no semantic meaning for the suffix is invented.

Status: **REMOVE_CONSTANT_FEATURE (documented for Phase 7I; no dataset modification in this phase).**