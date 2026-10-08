# Phase 7F Step 17 — Final Model Strategy Decision

## Evaluation of Options

| Option | Description | Assessment |
|--------|-------------|------------|
| 1 | Continue 46-class after better dataset | Valid long-term, but waits on better data |
| 2 | Restructure into smaller supported-class problem | Improves metrics (Macro F1 0.21→0.36) but data is still synthetic/weak |
| 3 | Restructure into another statistically defensible task | No evidence-supported alternative exists (hierarchy NOT feasible) |
| 4 | Stop disease classification until better dataset | Most honest given data quality |

## Decision: **OPTION 4 — Stop disease classification development until a better dataset is obtained.**

### Rationale

1. **Dataset quality gates everything.** The current data:
   - Has unknown provenance.
   - Is "weakly structured" and statistically consistent with synthetic-style generation.
   - Has weak feature discrimination (mean MI ~0.017).
   - Has weak separability even after class reduction (avg similarity rises to 0.82).
   - Cannot be medically validated.

2. **Restructuring (Option 2) improves metrics but not data quality.** The improved Macro F1
   (0.21 → 0.36) reflects a more learnable subset, not reliable disease prediction. Choosing it
   based on better metrics would violate the instruction not to choose on metrics alone.

3. **No defensible alternative task (Option 3)** exists — hierarchical grouping is not
   justifiable (Step 6).

4. **Option 1** requires better data, which we haven't obtained/verified.

### Conditional Note
Option 2 is the ONLY acceptable path if development must proceed before better data arrives,
and strictly as an exploratory/demo limited-class model — never as a production medical tool.

---

## Recommended Next Phase (do NOT execute)
> **Phase 7G — Approved Dataset Acquisition & Integration** (obtain a verified, documented,
> well-supported disease-symptom dataset) — with a prerequisite of manual dataset inspection
> and the dynamic symptom vocabulary (Step 14) groundwork.
