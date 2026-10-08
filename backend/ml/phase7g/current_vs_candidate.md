# Phase 7G — Quality Screen: Current vs Candidate

Comparison of the CURRENT dataset (`disease_dataset_cleaned_v2.csv`) vs. acquired candidates.
No training, no cleaning, no production changes. Machine data: `current_vs_candidate_data.json` (prior analytic run) and `acquired_dataset_profile.json`.

## Headline metrics

| Metric | Current | SymbiPredict (primary) | Columbia KB (alternative) | Kaushil268 (mirror) |
|---|---|---|---|---|
| Rows | 100,000 | 4,961 | 1,858 | 4,920 |
| Classes | 46 | 41 | 134 | 41 |
| Min class size | **1** | **121** | 3 (assoc) / 42 (docs) | 120 |
| Max class size | 21,295 | 121 | 28 (assoc) / 3,363 (docs) | 120 |
| Imbalance ratio | 21,295:1 | **1.0:1** | 80.07:1 (docs) | 1.0:1 |
| Classes < 10 | 9 | 0 | 0 | 0 |
| Classes < 20 | 16 | 0 | 0 | 0 |
| Classes < 50 | 19 | 0 | 0 | 0 |
| Classes < 100 | **23** | **0** | **0** | 0 |
| Missing cells | 0% | 0% | 0% | 53% |
| Duplicate rows | 0 | 4,657 (94%) | 0 | 4,616 (94%) |
| Symptom features | 174 | 132 | 401 | 131 |

## Discriminative-quality measurements (measured on current vs SymbiPredict)

| Metric | Current | SymbiPredict | Improvement |
|---|---|---|---|
| Mean mutual information | 0.0164 | **0.1777** | **~10.8×** |
| Features with MI > 0.01 | 113/174 | **131/132** | ~all features |
| Avg pairwise cosine separability | 0.6942 | **0.1067** | much more separable |

## Verdict

- **SymbiPredict provides THE dataset the Phase 7E/7F failure analysis asked for**, on every dimension identified as root cause:
  - Adequate class support: 23 classes < 100 → **0** (min 121)
  - Class imbalance: 21,295:1 → **1.0:1**
  - Meaningful feature-label relationships: mean MI 0.016 → **0.178**
  - Disease separability: 0.694 → **0.107**
  - Documented provenance (Mendeley DOI, peer-reviewed source) + **CC BY 4.0 license** + directly usable binary matrix.
- **Decision: B — CONDITIONALLY APPROVED (PRIMARY).** Residual open items (manual review): association-family representation with 94% duplicate rows (Phase 7H representation/dedup decision), 3 symptom synonyms to confirm, and the fact that no model approval can be granted from metrics alone.
- **Columbia KB** = real-clinical alternative; license manual review required; not a direct train-ready matrix (association-count format), requires weighting/scoring. Not contradicting SymbiPredict recommendation.
- **Kaushil268** = undocumented mirror of the SymbiPredict family; rejected as primary (redundant); confirms structure independently (same 41-class family, 304 unique vector patterns).

> Final: **materially better (conditional B)** — supersedes the current dataset as the recommended training source for Phase 7H.