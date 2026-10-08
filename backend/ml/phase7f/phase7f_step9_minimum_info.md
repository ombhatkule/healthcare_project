# Phase 7F Step 9 — Minimum Information Policy Recommendation

## Evidence (measured with production model, random trials)

| # Symptoms | Avg max score | Avg top1-top2 gap | Migraine frequency |
|-----------|---------------|-------------------|--------------------|
| 1 | 0.103 | 0.020 | 87.5% |
| 2 | 0.128 | 0.050 | 73.5% |
| 3 | 0.145 | 0.067 | 58.0% |
| 5 | 0.157 | 0.080 | 39.0% |
| 10 | 0.178 | 0.096 | 14.0% |
| 15 | 0.157 | 0.073 | 5.0% |
| 20 | 0.152 | 0.073 | 4.5% |
| 30 | 0.125 | 0.048 | 1.5% |

## Analysis

- **Very sparse inputs (1-3 symptoms)** produce **Migraine in 58-87%** of trials with the
  LOWEST scores (~0.10-0.145) and tightest top1-top2 gaps (~0.02-0.067). These are effectively
  **near-noise / default-class outputs**.
- **The 10-symptom point is the knee of the curve:** highest average max score (0.178) and
  widest top1-top2 gap (0.096), with Migraine already down to 14%.
- Beyond 10 symptoms, average max score declines (0.157 → 0.125) because random symptom
  combinations dilute predictive signal, though Migraine continues to drop.

## Recommended Policy (NOT implemented)

**Recommend a minimum of 5 symptoms** for a prediction attempt, with a **warning below 10**.

Rationale (evidence-based, NOT a medical rule):
- At **< 5 symptoms**, Migraine dominates (39-87%) with near-noise scores and tiny top1-top2
  gaps — the output is unreliable/arbitrary.
- At **5-9 symptoms**, prediction becomes meaningfully more informative (Migraine <= 39%,
  scores ~0.157).
- At **>= 10 symptoms**, the model shows its best discrimination (max score 0.178, gap 0.096).

### Recommended user-facing policy (for a FUTURE phase):
- **< 5 symptoms:** "Insufficient symptom information for meaningful model evaluation."
  (Reject or warn; do not present a predictive result as meaningful.)
- **5-9 symptoms:** Allow but display strong low-confidence disclaimer.
- **>= 10 symptoms:** Allow normal prediction flow.

> This threshold is a statistical heuristic derived from experimental measurements.
> It is NOT a medical guideline and must be labeled as such.
