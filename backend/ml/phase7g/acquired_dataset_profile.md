# Phase 7G — Acquired Dataset Profile

Local-only structural/statistical profile of the three acquired candidate files (READ-ONLY; no training, no cleaning, no production changes). Raw data: `acquired_dataset_profile.json`.

## Current dataset (reference)
- **`disease_dataset_cleaned_v2.csv`** — 100,000 rows × 175 cols (174 symptom features + `disease`), 46 classes, min 1 / max 21,295 (**imbalance 21,295:1**), 9 classes < 10, 16 < 20, 19 < 50, 23 < 100; no missing, no duplicate rows; mean MI **0.016**, avg cosine separability **0.694**. *(Root-cause of Phase 7E/7F failure.)*

---

## 1. SymbiPredict (SDPD) — `acquired/symbipredict_2022.csv`

- **Format:** binary matrix — **132** symptom columns (0/1) + `prognosis` (tie-break/synonym-resolved).
- **Rows:** 4,961   ·   **Columns:** 133   ·   **Classes:** 41
- **Class sizes:** min 121 / max 121 → **imbalance 1.0:1**
- **Classes below thresholds:** <10 = **0**, <20 = **0**, <50 = **0**, <100 = **0**
- **Missing:** 0 cells (0.0%)   ·   **Column dtypes:** all integer 0/1 (1,369,764 binary cells; 1-present = 36,969)
- **Duplicate rows:** 4,657 (**94%**); unique row patterns = 304 (6.13%) *(association-format redundancy — Phase 7H item #3)*
- **Measured quality (prior analytic pass, `phase7g_compare.py`):**
  - Mean mutual information: **0.178** (current: 0.016)
  - Features with MI > 0.01: **131/132** (current: 113/174)
  - Avg pairwise cosine separability: **0.107** (current: 0.694)
- **SHA-256:** `9834c90dd48eb2fef1fa56282f8f016a6781b0e4ada878015dc34a81af8e9e1b`
- **Result:** **B — CONDITIONALLY APPROVED** (primary recommendation)

## 2. Columbia University Disease-Symptom Knowledge DB — `acquired/columbia_disease_symptom_kb.csv`

- **Format:** association rows — `disease`, `count_of_disease_occurrence`, `symptom` (UMLS-mapped)
- **Rows:** 1,858   ·   **Columns:** 3   ·   **Diseases:** 134   ·   **Symptoms:** 401
- **Associations per disease:** min 3 / median 13 / max 28
- **Document counts (real clinical notes):** min 42 / max 3,363 → **imbalance 80.07:1** (document-level)
- **Missing:** 0   ·   **Duplicate rows:** 0
- **Provenance:** 25,074 NYP Hospital 2004 discharge summaries, MedLEE NLP, UMLS codes, AMIA 2008 (PMC2656103), ~90% recall / ~92% precision.
- **SHA-256:** `51b81b8999b072768bb0692376be1983f15b59a77a8eb5c95af276fcbfa73a17`
- **Result:** ALTERNATIVE — CONDITIONALLY APPROVED, **license manual review required**

## 3. Kaushil268 (long-format mirror) — `acquired/kaushil268_disease_prediction.csv`

- **Format:** `Disease` + `Symptom_1..Symptom_17` (missing cells for absent symptoms)
- **Rows:** 4,920   ·   **Classes:** 41   ·   **Class sizes:** 120 each (imbalance 1.0)
- **Missing:** 53.06% of cells (46,992); duplicate rows 4,616 (93.8%); 131 unique symptom strings; avg 7.45 symptoms/row
- **SHA-256:** `ebbd391c4ba4d64f57a00eb3d0a55f0ca9b920b0c5de6b9af4234e72519c9618`
- **Result:** REJECTED as materially-better candidate (undocumented mirror of SymbiPredict family; synthetic-expression redundancy)

---

## Comparison vs current

| Metric | Current | SymbiPredict | Columbia KB | Kaushil268 |
|---|---|---|---|---|
| Rows | 100,000 | 4,961 | 1,858 | 4,920 |
| Classes | 46 | **41** | **134** | 41 |
| Min/max class size | 1 / 21,295 | **121 / 121** | 3–28 assoc (docs 42–3,363) | 120 / 120 |
| Imbalance ratio | 21,295:1 | **1.0:1** | 80.07:1 (docs) | 1.0:1 |
| Classes < 100 | 23 | **0** | **0** | 0 |
| Mean MI | 0.016 | **0.178** | n/a (association format) | ~0.18 (same family) |
| Avg cosine separability | 0.694 | **0.107** | n/a | ~0.11 (same family) |
| Missing | 0% | 0% | 0% | 53% |
| Duplicates | 0 | 94% | 0 | 94% |
| Provenance | Unknown | **Documented (DOI + MDPI paper)** | **Real clinical (AMIA 2008)** | Undocumented |
| License | n/a | **CC BY 4.0** | Unknown (review) | Apache 2.0 |

**Verdict:** SymbiPredict is materially better than the current dataset on every Phase 7E/7F failure dimension (conditional approval B). Columbia KB adds the strongest real-clinical provenance as an alternative pending license confirmation.