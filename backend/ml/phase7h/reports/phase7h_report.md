# Phase 7H — Dataset Preprocessing & Validation Report

**Date:** 2026-09-10
**Scope:** ANALYSIS + PREPROCESSING + VALIDATION of the approved Phase 7G candidate **SymbiPredict (SDPD)**. No training, no production changes, no Phase 7I/7J/8.

---

## Executive summary

SymbiPredict is **structurally valid**. Its 4,657 duplicate rows are **legitimate association-format repetition** (not accidental duplicates, not independent patients) — evidenced by every unique vector mapping to exactly one disease (**0 contradictions**). The deduplicated information-bearing representation is **304 association rows** (5–10 unique vectors per disease). Feature vocabulary normalizes deterministically with **0 collisions**; labels are clean. Mean MI 0.1777 (131/132 features >0.01) and avg cosine separability 0.107 confirm strong structural class separation that does **not** degrade after deduplication. Leakage from repeated rows is fully characterized and mitigated by a **grouped split by unique vector**.

**DECISION: B — CONDITIONALLY APPROVED FOR PHASE 7I — MANUAL REVIEW REQUIRED.**

---

## Answers to the 15 required questions

**1. Is SymbiPredict structurally valid?**
Yes. 4,961×133; 132 binary features (0/1); 0 missing/NaN/inf/invalid values; 41 classes × 121 (imbalance 1.0:1); no all-zero or all-one rows; active symptoms 3–17 (mean 7.45).

**2. Are the 4,657 duplicate rows legitimate association redundancy, accidental, mixed, or uncertain?**
**LEGITIMATE association-format repetition.** Every unique vector is repeated (multiplicities 6/12/18/67/73/79/85/91), and no vector crosses disease boundaries. Each disease repeats just 5–10 canonical vectors to reach 121 rows. Conclusion path recorded in `analysis/duplicate_analysis.json`.

**3. How many unique symptom patterns exist?**
**304** unique symptom vectors = 304 unique vector+disease pairs (perfect 1:1 with labels; all vectors are class-specific).

**4. Are there contradictory symptom vectors?**
**No.** 0 identical vectors map to multiple diseases (0 rows, 0 diseases affected, 0% of unique vectors). `analysis/contradictory_patterns.json`.

**5. Is the 132-feature vocabulary valid?**
Yes. All 132 are symptom-like and binary. One constant column (`fluid_overload`, all-zero) is a source duplicate-header artifact (its twin `fluid_overload_1` carries the signal) — kept distinct and flagged for a documented Phase 7I removal decision. `analysis/column_normalization.json`.

**6. Are there normalization collisions?**
**0.** Few messy tokens (`foul_smell_of urine`, `spotting_ urination`, `toxic_look_(typhos)`, `dischromic _patches`, `fluid_overload.1`) normalize deterministically without merging distinct symptoms.

**7. Are any labels ambiguous?**
No label is ambiguous at the formatting level; 41 clean labels, 0 collisions. Any medical synonym-merging (e.g., hepatitis subtypes) is **deliberately not performed** — not justified by source docs. `analysis/label_normalization.json`.

**8. Which synonym mappings are safe?**
Only **3 HIGH_CONFIDENCE_SYNONYM** (for candidate/vocabulary documentation, not auto-applied): `stomach_pain→abdominal_pain`, `belly_pain→abdominal_pain`, `breathlessness→shortness_of_breath` — require clinician blessing before use as product-facing labels. **8 POSSIBLE_SYNONYM** require manual confirmation; **101** are new vocabulary. No synonyms were applied to the cleaned datasets. `analysis/symptom_mapping_review.json`.

**9. What cleaned representation should Phase 7I use?**
**Representation C — unique vector+disease associations** (`cleaned/symbipredict_deduplicated.csv`, 304 rows, 41 classes, 5–10 vectors/class, imbalance 2.0:1). The 4,961-row repeated file (`symbipredict_cleaned.csv`) is preserved but must NOT be treated as i.i.d. samples. `analysis/representations.json`.

**10. What split strategy should Phase 7I use?**
**Grouped split by unique symptom vector** (each vector in exactly one fold), repeated stratified grouped CV (5-fold ×10), macro metrics + per-class support. Naive random row-splitting of the 4,961-row file is prohibited. `reports/train_test_strategy.md`.

**11. What leakage risks exist?**
High under naive row splitting: 100% of unique vectors repeat (4,961/4,961 rows = 100% are repeats of another row; max multiplicity 91). Identical vectors would straddle train/test. Eliminated by the grouped-association design. `analysis/leakage_analysis.json`.

**12. How does cleaned SymbiPredict compare with the old dataset?**
| Metric | Current v2 | SymbiPredict cleaned/dedup |
|---|---|---|
| Rows (total) | 100,000 | 4,961 / **304 unique** |
| Classes | 46 | **41** |
| Features | 174 | 132 |
| Class imbalance | 21,295:1 | **1.0:1 raw / 2.0:1 assoc** |
| Missing | 0% | 0% |
| Mean MI | 0.0164 | **0.1777** |
| Features MI > 0.01 | 113/174 | **131/132** |
| Avg cosine separability | 0.694 | **0.107** |
| Provenance/License | Unknown | **DOI + CC BY 4.0** |

**13. Does preprocessing materially change separability?**
No. Raw avg cosine 0.10668 vs dedup 0.10575 — separability is a property of the association table, not the repetition counts.

**14. Is the dataset approved to proceed to Phase 7I?**
**Conditional yes (decision B).** Structure, representation, and strategy are approved; Phase 7I may be **planned**, but execution requires the manual-review items (below) to be resolved/signed off.

**15. What unresolved manual-review items remain?**
1. **Provenance sign-off** — community-curated symptom→disease associations, NOT patient-level records (acceptable for exploratory/educational use only).
2. **3 HIGH_CONFIDENCE synonyms** need clinician confirmation before product-facing labels.
3. **8 POSSIBLE synonyms** confirmation.
4. **`fluid_overload`** constant-column removal decision (documented zero-variance reason).
5. Small-sample (304 associations) evaluation uncertainty — report as exploratory.

---

## Final decision

> **B — CONDITIONALLY APPROVED FOR PHASE 7I — MANUAL REVIEW REQUIRED**

Justification: structural validity, duplicate semantics, leakage, class support, feature quality, separability, provenance, and intended use are all satisfactory or mitigable; residual items are human-review (provenance characterization + synonym blessing), not dataset blockers.

## Production safety (verified)
- `disease_model.joblib`, `symptom_columns.joblib`, `disease_dataset_cleaned_v2.csv` — all **UNCHANGED** (hash-verified vs Phase 7H baseline and Phase 7G).
- Flask, Flutter, API, production config — **UNCHANGED**.
- No model trained/deployed; no Phase 7I/7J/8 started.
- Phase 7H outputs isolated under `backend/ml/phase7h/`; SymbiPredict source untouched.

## Next phase (do NOT start)
> **PHASE 7I — TRAINING & BENCHMARKING** (planned): use `cleaned/symbipredict_deduplicated.csv`, grouped-vector CV, 41-class exploratory classifier benchmark. Blocked until decision-B manual-review items are signed off. **STOP.**