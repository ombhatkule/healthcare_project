# Phase 7H.1 — Manual Review, Provenance Gate & Feature/Synonym Sign-off

**Phase 7H.1 does not train or deploy a model.**

## Purpose
Close the manual-review/sign-off gate left open by Phase 7H decision B: provenance documentation review, symptom-synonym review, `fluid_overload` constant-feature review, small-sample limitation documentation, and a formal GO/CONDITIONAL/BLOCKED gate for Phase 7I.

## Input files (read-only usage)
- `backend/ml/phase7g/acquired/symbipredict_2022.csv` (source of truth, unmodified)
- `backend/ml/phase7g/*.md`, `*.json` (7G acquisition evidence)
- `backend/ml/phase7h/reports/phase7h_report.md`, `dataset_card.md`, `train_test_strategy.md`, `separability_report.md`
- `backend/ml/phase7h/analysis/symptom_mapping_review.json`, `feature_analysis.json`, `duplicate_analysis.json`, `contradictory_patterns.json`, `representations.json`, `leakage_analysis.json`, `separability_analysis.json`, `column_normalization.json`, `label_normalization.json`
- `backend/ml/phase7h/validation/phase7h_validation.json`, `phase7h_baseline.json`, `raw_profile.json`
- Production model/dataset/metadata (hash-verified only — never opened for writing)

## Commands / scripts used
No new analysis scripts were required; all evidence was assembled from the deterministic Phase 7H scripts
(`backend/ml/phase7h/scripts/phase7h_*.py`). A hash check was run for the production safety gate:
- `Get-FileHash` (SHA-256) for the 3 production files → all MATCH Phase 7H baseline / Phase 7G.
Evidence saved to `evidence/production_hash_check.txt`.

## Outputs
- `provenance_review.md` — provenance gate (CONDITIONAL)
- `synonym_review.md` — 3 high-confidence + 8 possible synonym review (all PENDING_CLINICIAN_REVIEW)
- `feature_review.md` — `fluid_overload` constant-feature review (REMOVE_CONSTANT_FEATURE, Phase 7I)
- `manual_review.md` — formal manual-review record (Gate: CONDITIONAL_GO_TO_7I)
- `phase7h1_decision.md` — final decision document
- `outputs/phase7h1_decision.json` — machine-readable gate record
- `evidence/` — production hash check + evidence index

## Decisions
- Provenance: **CONDITIONAL** (documented source/DOI/license; community-curated associations; not a clinical patient cohort)
- Synonyms: **PENDING_CLINICIAN_REVIEW** (none applied to cleaned data)
- `fluid_overload`: **REMOVE_CONSTANT_FEATURE** (Phase 7I preprocessing, documented reason; cleaned data untouched)
- Representation: **C** (304 unique vector+disease associations)
- Leakage control: **grouped split by unique symptom vector**
- **Phase 7I gate: CONDITIONAL_GO_TO_7I** (non-clinical research/educational evaluation only)

## Unresolved items
1. Clinician confirmation of 3 high-confidence + 8 possible synonyms (no clinician sign-off exists).
2. Provenance remains conditional — no independent verification of a patient cohort; verification limited to metadata.
3. Small association sample (304) — evaluation uncertainty expected; metrics are exploratory.

## How Phase 7I should consume these results
- Use `backend/ml/phase7h/cleaned/symbipredict_deduplicated.csv` (Representation C).
- Drop `fluid_overload` (constant) in preprocessing with the documented reason; regenerate the 131-feature vocabulary deterministically.
- Split by unique symptom vector (grouped CV); never naive row-split the 4,961-row file.
- Do NOT apply any synonym mapping; keep novel 132/131 vocabulary primary.
- Label all results: **"Non-clinical research/educational evaluation; not clinically validated."**
- Report per-class support; treat metrics as exploratory.