# Phase 7H — Recommended Train/Test Strategy

## Leakage risk
- 304 unique symptom vectors; **every one appears multiple times** in the 4,961-row file.
- 4961 of 4,961 rows (100.0%) are exact repeats of another row.
- Naive random row-level split puts identical vectors in train and test → **information leakage** →
  unusably optimistic evaluation.

## Recommended strategy (for Phase 7I)
1. **Use representation C** (`cleaned/symbipredict_deduplicated.csv`, 304 association rows).
2. **Grouped split by unique symptom vector** — each vector assigned to exactly one fold.
3. Repeated grouped CV (5-fold grouped, repeated 10x) due to only 5-10 vectors/class.
4. Report macro-averaged metrics AND per-class support counts.
5. Treat all numbers as **exploratory** (small sample, community-curated associations).
6. Do NOT report as diagnostic/clinical performance.

Machine data: `analysis/leakage_analysis.json`
