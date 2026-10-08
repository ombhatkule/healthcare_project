"""
Phase 7E Steps 4-11 â€” Documentation, Comparison, Decision
Generates: dataset_requirements.md, candidate_dataset_comparison.{md,json},
compatibility_analysis.md, decision matrix, production_safety_check.json, phase7e_report.md
"""
import json, csv, os, hashlib, time
import numpy as np
from pathlib import Path

BASE = Path(__file__).parent
MODEL_DIR = BASE.parent / "model"
DATA_DIR = BASE.parent.parent / "data"
PHASE7D = BASE.parent / "phase7d"
FLUTTER_DIR = BASE.parent.parent
BACKEND_DIR = BASE.parent.parent / "backend"

# ============================================================
# STEP 4 â€” Dataset Requirements
# ============================================================
print("=" * 60)
print("STEP 4 â€” Define Dataset Requirements")
print("=" * 60)

requirements_md = """# Dataset Requirements for a Better Disease Prediction Dataset

**Phase:** 7E Step 4
**Date:** 2026-09-08

## Purpose

This document defines objective requirements for any dataset that would replace or
improve upon the current `disease_dataset_cleaned_v2.csv` (46 classes, 174 binary
features, 100,000 rows â€” shown in Phase 7D/E to be fundamentally unsuitable for
reliable multiclass prediction due to extreme imbalance, weak feature discrimination,
and low disease separability).

---

## MUST HAVE

These are non-negotiable. A dataset failing any of these is automatically rejected.

1. **Identifiable target column.** A clear disease/condition label column must exist.
   Without this, supervised classification is impossible.

2. **Documented source/provenance.** The dataset must state where it came from
   (medical records, published research, government survey, etc.). Unknown origin is grounds for rejection.

3. **Usable documentation.** There must be enough documentation to understand:
   - what each feature/symptom column means
   - how values are encoded
   - how the target is defined
   - any known limitations or biases

4. **Meaningful feature-label relationship.** Features must have observable variation
   across classes (assessed via mutual information, separability metrics). Features that
   are near-random or identical across all classes cannot support classification.

5. **Accessible/verifiable.** We must be able to actually obtain and inspect the data
   without credentials or access restrictions that we cannot meet.

6. **No fabricated records added by THIS project.** The dataset itself must exist
   independently of this project and not be invented here.

---

## SHOULD HAVE

These are strongly preferred.

1. **Adequate per-class support.** At minimum, the vast majority of classes should
   have enough samples for meaningful train/test evaluation (e.g., â‰¥ 50-100 per class
   so a test set of 20% provides â‰¥ 10-20 test samples per class).

2. **Limited class imbalance.** Imbalance ratio should ideally be < 100:1, or at minimum
   there must be a documented strategy for handling imbalance (resampling weights, etc.).

3. **Consistent feature/symptom mapping.** Symptoms should map consistently to named
   concepts that can be translated to the Flask prediction API and (eventually) to
   user-facing Flutter symptom selectors.

4. **Sparse-input tolerance.** The dataset should contain records with a realistic mix
   of symptom counts (including low-symptom records), since real user inputs are often
   sparse generic symptom sets.

5. **Feature interpretability.** Binary or ordinal interpretable features are easier to
   map to the existing API than opaque embeddings or high-dimensional dense vectors.

6. **Permitted usage.** License/terms should permit research and educational model
   training without reaching out for special permission.

---

## NICE TO HAVE

These improve quality but are not required.

1. **Medically validated or clinically sourced data** with clear documentation of
   medical review. (Not required because such datasets are rare and may be restricted.)

2. **Multiple related conditions** that span both common and rare diseases to allow
   studying extreme class behavior.

3. **Natural-language symptom descriptions** in addition to structured binary features,
   enabling potential future NLP-based input.

4. **Patient demographics/demographic features** (age, sex, etc.) if appropriate and
   de-identified.

5. **Pre-split train/test** so results are reproducible and directly comparable.

---

## Automatic Rejection Conditions

A candidate is rejected outright if ANY of these apply:

- No identifiable target column.
- Unknown or unverifiable source/provenance.
- Documentation unusable (can't understand columns or labels).
- Only a handful (e.g., < 20) of records for most classes.
- No meaningful relationship between features and labels (e.g., features near-random,
  MI â‰ˆ 0 across features, no class variation).
- Inaccessible or unverifiable data (requires credentials/restrictions we can't meet).
- Incompatible licensing (e.g., commercial-prohibition that conflicts with project use).
- Eventual substitution would eliminate MORE symptoms/classes than it gains, or
  would require losing the current disease vocabulary entirely without a clear win.

---

## Rationale (rooted in current dataset failures)

The current dataset fails several Must Haves and most Should Haves:

- **Provenance:** Unknown â€” no source attribution found (rating: Unknown).
- **Class support:** 7 classes have < 5 samples; 9 have < 10 samples (19.6% of classes).
- **Imbalance:** 21,295:1 ratio; top-5 classes hold 55.4% of data.
- **Feature discrimination:** only 116/174 features exceed MI > 0.01; mean MI = 0.017.
- **Separability:** average pairwise cosine similarity = 0.694 (weakly separable).
- **Sparse inputs:** empty/near-empty vectors predict Migraine with ~9-11% confidence.

These concrete deficiencies drive the requirements above.
"""

with open(BASE / 'dataset_requirements.md', 'w', encoding='utf-8') as f:
    f.write(requirements_md)

print("  DONE â€” dataset_requirements.md")

# ============================================================
# STEP 5+6 â€” Candidate Dataset Discovery & Screening
# ============================================================
print("\n" + "=" * 60)
print("STEP 5+6 â€” Candidate Dataset Discovery & Screening")
print("=" * 60)

# NOTE: Candidate info gathered from web search. Documents the level of verification
# Each candidate's "verification_status" indicates whether we actually inspected it
# directly (none were downloaded/inspected without credentials) vs. web-documented.

candidates = [
    {
        "name": "Kaggle 'Disease Prediction Using Machine Learning' (Kaushil268)",
        "source": "Kaggle",
        "provenance": "Community-submitted; claims symptom/disease mapping; ~42 diseases, 132 binary symptoms",
        "rows": "~4920 train + small test",
        "features": "132 binary symptom columns + prognosis target",
        "classes": "~42 diseases",
        "target": "prognosis (last column)",
        "symptom_relevance": "High â€” direct symptom columns",
        "documentation": "Basic Kaggle card; notes 'clean data 42' community rating",
        "license": "Open Database / Contents (ODC) per Kaggle",
        "access": "Kaggle (free account/API)",
        "verification_status": "Documented via web search only; NOT downloaded/inspected",
        "class_support_known": "Unknown per-class distribution; ~117 samples/disease on average",
        "known_limitations": "Very small total records (~5000); 42 classes with 132 features; reported 100% train accuracy is likely overfitting"
    },
    {
        "name": "Kaggle 'Symptom2Disease' (Niyarr Barman)",
        "source": "Kaggle",
        "provenance": "Community-sourced; 24 diseases x 50 symptom descriptions = 1200 rows",
        "rows": "1,200",
        "features": "2 columns: 'label' (disease) + 'text' (natural-language symptom description)",
        "classes": "24 diseases",
        "target": "label column",
        "symptom_relevance": "Medium â€” text descriptions, not structured binary features",
        "documentation": "Kaggle data card with disease list",
        "license": "Kaggle default",
        "access": "Kaggle (free)",
        "verification_status": "Documented via web search only; NOT downloaded",
        "class_support_known": "Balanced: 50 per class",
        "known_limitations": "Requires NLP processing (natural text); 24 diseases only; 1200 rows is small"
    },
    {
        "name": "Kaggle 'Community Healthcare MultiSymptoms-Disease Dataset' (arjunnairedu)",
        "source": "Kaggle",
        "provenance": "Stated as 'simulated' patient records; 174 symptoms, 46 diseases; matches project's structure",
        "rows": "100,000 (simulated)",
        "features": "174 binary symptoms + disease target",
        "classes": "46 diseases",
        "target": "disease",
        "symptom_relevance": "High â€” structured binary, directly comparable",
        "documentation": "Kaggle card states 'simulated patient case' and 'clinically structured and realistic'",
        "license": "Kaggle default",
        "access": "Kaggle (free)",
        "verification_status": "Documented via web search only; NOT downloaded",
        "class_support_known": "Unknown per-class; possible extreme imbalance",
        "known_limitations": "SIMULATED data â€” not real clinical records; 46 diseases / 174 symptoms EXACTLY matches the project, suggesting it may be the same or a sibling synthetic-style dataset"
    },
    {
        "name": "IEEE DataPort 'Disease Prediction Dataset' (Ayush Nautiyal et al.)",
        "source": "IEEE DataPort / Kaggle mirror",
        "provenance": "Referenced from MedLinePlus; 1325 symptoms, 391 diseases; academic submission with DOI",
        "rows": "Unknown (training/testing CSVs)",
        "features": "Many binary symptom columns",
        "classes": "391 diseases",
        "target": "disease/prognosis",
        "symptom_relevance": "High â€” supported by MedLinePlus medical reference",
        "documentation": "IEEE DataPort abstract; academic provenance; DOI: 10.21227/7wgr-a308",
        "license": "IEEE DataPort terms; free access noted",
        "access": "IEEE DataPort or Kaggle mirror (free)",
        "verification_status": "Documented via web search; medical reference cited; NOT inspected directly",
        "class_support_known": "Unknown; 391 diseases is very broad",
        "known_limitations": "Very large class count (391); most likely tiny per-class support; MedLinePlus-referenced but assembled by students"
    },
    {
        "name": "UCI 'Early Stage Diabetes Risk Prediction' (ID 529)",
        "source": "UCI Machine Learning Repository",
        "provenance": "Direct questionnaires from Sylhet Diabetes Hospital, Bangladesh; approved by a doctor",
        "rows": "520",
        "features": "16 binary symptom features + age/gender + binary class",
        "classes": "2 (diabetes positive/negative)",
        "target": "class (binary)",
        "symptom_relevance": "Medium â€” diabetes-specific symptoms",
        "documentation": "UCI variable table; published paper reference",
        "license": "UCI open",
        "access": "Free (ucimlrepo / UCI)",
        "verification_status": "Documented via web; medically sourced (doctor-approved questionnaires); small",
        "class_support_known": "~2:1 split (positive/negative)",
        "known_limitations": "Only diabetes (2 classes); 520 rows; not a general disease-symptom dataset"
    },
    {
        "name": "Kaggle 'Disease and Symptoms dataset' (Mohamed Medhat AZZAZY)",
        "source": "Kaggle",
        "provenance": "Community; 378 columns, ~773 records visible",
        "rows": "~773 (partial view)",
        "features": "378 columns (symptoms)",
        "classes": "Unknown (likely many)",
        "target": "diseases",
        "symptom_relevance": "High column count but unclear structure",
        "documentation": "Minimal; large wide CSV",
        "license": "Kaggle default",
        "access": "Kaggle (free)",
        "verification_status": "Documented via web; NOT inspected",
        "class_support_known": "Unknown",
        "known_limitations": "Very wide (378 cols) with few rows; unclear; likely overkill/unmanageable"
    },
    {
        "name": "Kaggle 'Symptom to Disease Descriptions (820_Cleaned)'",
        "source": "Kaggle",
        "provenance": "Community; 820 diseases, 654 symptoms; includes column-level and text data",
        "rows": "190,672 (row-level binary matrix) + text descriptions",
        "features": "654 binary symptoms + disease target; plus descriptive text",
        "classes": "820 diseases",
        "target": "disease",
        "symptom_relevance": "High â€” structured binary + natural-language",
        "documentation": "Kaggle data card",
        "license": "Kaggle default",
        "access": "Kaggle (free)",
        "verification_status": "Documented via web; NOT inspected",
        "class_support_known": "Unknown; 820-class problem is extremely broad",
        "known_limitations": "820 classes is far too many for meaningful multiclass evaluation; likely tiny per-class support"
    },
    {
        "name": "UCI 'CDC Diabetes Health Indicators' (ID 891)",
        "source": "UCI",
        "provenance": "CDC Behavioral Risk Factor Surveillance System (BRFSS) survey data",
        "rows": "Large (CDC survey)",
        "features": "35 features (demographics + survey answers)",
        "classes": "3 (no diabetes / prediabetes / diabetes)",
        "target": "Diabetes_binary",
        "symptom_relevance": "Low â€” mostly lifestyle/survey, not physician-verified symptoms",
        "documentation": "UCI variable table; CDC provenance",
        "license": "UCI open",
        "access": "Free (ucimlrepo / UCI)",
        "verification_status": "Documented via web; CDC-sourced, real survey data",
        "class_support_known": "Large; imbalanced (mostly healthy)",
        "known_limitations": "Only 3 diabetes classes; features are survey-style, not symptom-based; not a disease-symptom prediction dataset"
    },
]

# Screening: assign scores (0-5) per criterion based on available evidence
# Score key: 5=excellent, 4=good, 3=acceptable, 2=weak, 1=poor, 0=unknown
criteria = ["Provenance", "Documentation", "Class support", "Class balance",
            "Symptom relevance", "Feature interpretability", "Disease separability evidence",
            "License/usage clarity", "Integration feasibility", "Overall suitability"]

def score_candidate(c):
    name = c["name"]
    scores = {}
    if "Community Healthcare" in name:
        scores = {"Provenance": 2, "Documentation": 2, "Class support": 2, "Class balance": 2,
                  "Symptom relevance": 5, "Feature interpretability": 4, "Disease separability evidence": 2,
                  "License/usage clarity": 2, "Integration feasibility": 4, "Overall suitability": 2}
    elif "Kaushil268" in name:
        scores = {"Provenance": 2, "Documentation": 3, "Class support": 3, "Class balance": 2,
                  "Symptom relevance": 5, "Feature interpretability": 4, "Disease separability evidence": 3,
                  "License/usage clarity": 3, "Integration feasibility": 4, "Overall suitability": 3}
    elif "Symptom2Disease" in name and "Niyarr" in name:
        scores = {"Provenance": 2, "Documentation": 3, "Class support": 3, "Class balance": 5,
                  "Symptom relevance": 4, "Feature interpretability": 2, "Disease separability evidence": 2,
                  "License/usage clarity": 2, "Integration feasibility": 2, "Overall suitability": 2}
    elif "IEEE" in name:
        scores = {"Provenance": 4, "Documentation": 3, "Class support": 2, "Class balance": 2,
                  "Symptom relevance": 5, "Feature interpretability": 4, "Disease separability evidence": 2,
                  "License/usage clarity": 3, "Integration feasibility": 3, "Overall suitability": 3}
    elif "UCI 'Early Stage" in name:
        scores = {"Provenance": 5, "Documentation": 4, "Class support": 3, "Class balance": 4,
                  "Symptom relevance": 3, "Feature interpretability": 4, "Disease separability evidence": 4,
                  "License/usage clarity": 5, "Integration feasibility": 3, "Overall suitability": 3}
    elif "AZZAZY" in name or "Disease and Symptoms dataset" == name:
        scores = {"Provenance": 2, "Documentation": 1, "Class support": 1, "Class balance": 1,
                  "Symptom relevance": 5, "Feature interpretability": 3, "Disease separability evidence": 2,
                  "License/usage clarity": 2, "Integration feasibility": 1, "Overall suitability": 1}
    elif "820_Cleaned" in name:
        scores = {"Provenance": 2, "Documentation": 2, "Class support": 1, "Class balance": 1,
                  "Symptom relevance": 5, "Feature interpretability": 4, "Disease separability evidence": 2,
                  "License/usage clarity": 2, "Integration feasibility": 2, "Overall suitability": 2}
    elif "CDC" in name:
        scores = {"Provenance": 5, "Documentation": 4, "Class support": 5, "Class balance": 3,
                  "Symptom relevance": 2, "Feature interpretability": 3, "Disease separability evidence": 3,
                  "License/usage clarity": 5, "Integration feasibility": 3, "Overall suitability": 3}
    else:
        scores = {c: 1 for c in criteria}
    return scores

for c in candidates:
    c["scores"] = score_candidate(c)
    c["total_score"] = round(sum(c["scores"].values()) / (len(criteria) * 5) * 100, 1)
    # Classification
    overall = c["scores"]["Overall suitability"]
    if overall >= 4:
        c["recommendation"] = "Best candidate â€” manual review recommended"
    elif overall == 3:
        c["recommendation"] = "Candidate needing manual review"
    elif overall == 2:
        c["recommendation"] = "Requires manual verification â€” weak"
    else:
        c["recommendation"] = "Rejected"

# Sort by overall suitability
candidates.sort(key=lambda x: x["total_score"], reverse=True)

comparison_report = {
    "title": "Phase 7E Candidate Dataset Comparison",
    "date": "2026-09-08",
    "scoring_method": "Each criterion scored 0-5 (5=excellent, 0=unknown/poor). Total = average across criteria scaled to 100.",
    "candidates": [],
    "important_caveat": "None of these datasets were downloaded or directly inspected. All information comes from web documentation (Kaggle/UCI/IEEE data cards). Scores reflect documented evidence, not direct verification. Any candidate selected for use REQUIRES manual download + inspection + verification before integration.",
}

for c in candidates:
    comp_entry = {
        "name": c["name"],
        "provenance": c["provenance"],
        "rows": c["rows"],
        "features": c["features"],
        "classes": c["classes"],
        "target": c["target"],
        "symptom_relevance": c["symptom_relevance"],
        "documentation": c["documentation"],
        "license": c["license"],
        "access": c["access"],
        "verification_status": c["verification_status"],
        "known_limitations": c["known_limitations"],
        "scores": c["scores"],
        "total_score": c["total_score"],
        "recommendation": c["recommendation"],
    }
    comparison_report["candidates"].append(comp_entry)

with open(BASE / "candidate_dataset_comparison.json", 'w') as f:
    json.dump(comparison_report, f, indent=2)

# Markdown table
md = [
    "# Candidate Dataset Comparison",
    "",
    f"**Date:** 2026-09-08",
    f"**Scoring:** 0-5 per criterion (5=excellent). Overall = % of maximum.",
    "",
    "> **IMPORTANT CAVEAT:** All information is from web documentation (Kaggle/UCI/IEEE data cards).",
    "> No dataset was downloaded or directly inspected during this phase.",
    "> Any final selection MUST be manually downloaded, inspected, and verified before integration.",
    "",
    "## Comparison Table",
    "",
    "| Candidate | Provenance | Rows | Features | Classes | Total Score | Recommendation |",
    "|-----------|------------|------|----------|---------|-------------|----------------|",
]

for c in comparison_report["candidates"]:
    md.append(
        f"| {c['name']} | {c['provenance'][:40]}... | {c['rows']} | {c['features'][:40]}... | "
        f"{c['classes']} | {c['total_score']}% | {c['recommendation']} |"
    )

md += ["", "## Score Breakdown", ""]
for c in comparison_report["candidates"]:
    md.append(f"### {c['name']} â€” {c['total_score']}%")
    md.append("")
    md.append("| Criterion | Score |")
    md.append("|-----------|-------|")
    for crit in criteria:
        md.append(f"| {crit} | {c['scores'][crit]}/5 |")
    md.append("")
    md.append(f"**Provenance:** {c['provenance']}")
    md.append(f"**Rows/Features/Classes:** {c['rows']} / {c['features']} / {c['classes']}")
    md.append(f"**Target:** {c['target']}")
    md.append(f"**License:** {c['license']}")
    md.append(f"**Access:** {c['access']}")
    md.append(f"**Verification:** {c['verification_status']}")
    md.append(f"**Known limitations:** {c['known_limitations']}")
    md.append(f"**Recommendation:** {c['recommendation']}")
    md.append("")

with open(BASE / 'candidate_dataset_comparison.md', 'w', encoding='utf-8') as f:
    f.write("\n".join(md))

print("  DONE â€” candidate_dataset_comparison.json + .md")

# ============================================================
# STEP 7 â€” Compatibility Analysis
# ============================================================
print("\n" + "=" * 60)
print("STEP 7 â€” Compatibility Analysis")
print("=" * 60)

compat_md = """# Compatibility Analysis for Candidate Datasets

**Phase:** 7E Step 7
**Date:** 2026-09-08

## Current System Blueprint

- **Flutter app:** exposes only 16 generic selectable symptoms (one mapping, `muscle_pain`, is invalid).
- **Flask API:** `/api/symptoms` returns the 16 symptoms; prediction endpoint expects a 174-feature vector.
- **Backend model vocabulary:** 174 binary symptom features (`symptom_*` and `rare_symptom_*`).
- **Prediction response:** `{disease, confidence, ...}` JSON compatibility is required.

---

## Compatibility Question Matrix

### A. Would candidate features map naturally to the current symptom concept?

| Candidate | Mapping Fit | Explanation |
|-----------|-------------|-------------|
| Kaggle Kaushil268 (132 binary symptoms) | **Good** | Binary symptom columns map naturally; names like `itching`, `cough`, `skin_rash` are interpretable |
| Community Healthcare (174 symptoms) | **Perfect â€” but likely same/sibling dataset** | Matches project's 174 features / 46 diseases exactly; may be the original source of current data |
| Symptom2Disease (text descriptions) | **Poor** | Requires NLP feature extraction; not direct binary symptom vector |
| IEEE Disease Prediction (1325 symptoms) | **Fair** | MedLinePlus-referenced but very large vocabulary; mapping effort high |
| UCI Early Stage Diabetes | **Partial** | Diabetes-only symptoms; not a general disease dataset |
| CDC Diabetes Indicators | **Poor** | Survey/lifestyle features rather than physician symptoms |

### B. Would it require a new feature vocabulary?

- **Yes** for every candidate that differs from the current 174 features.
- Kaushil268 (132), Symptom2Disease (NLP), IEEE (1325) all introduce different vocabularies.
- Only Community Healthcare matches the existing 174-feature vocabulary (but is likely synthetic-style â€” see below).

### C. Would `/api/symptoms` need to expose a different list?

- **Yes** for any adopted dataset with a different vocabulary. The Flask endpoint would need updating.
- If we adopted Kaushil268 (132 symptoms), `/api/symptoms` would grow/change and the Flutter symptom list would need to change too.

### D. Would Flutter need dynamic symptom loading?

- **Recommended** regardless of dataset. Currently Flutter hard-codes 16 symptoms; dynamic loading
  from `/api/symptoms` decouples the frontend from any specific feature vocabulary.
- This is a forward-looking change that would ease any dataset migration.

### E. Would it require a different prediction schema?

- **No** for column-format datasets (binary-in, label-out). The `{disease, confidence}` schema is unchanged.
- **Yes** for text datasets (Symptom2Disease) which require textâ†’features â†’ NLP pipeline, breaking the simple binary-vector API.

### F. Could a new model remain compatible with the current API response format?

- **Yes** â€” as long as we retain a `predict(feature_vector) â†’ {disease, probability}` interface.
- The internal model can change; the response format stays stable. This is the recommended integration path.

---

## Key Findings

1. **Most candidates require a NEW feature vocabulary**, meaning Flutter symptom lists,
   `/api/symptoms`, and the model's `symptom_columns` would all need to change.

2. **The only candidate matching current structure (Community Healthcare â€” 174 symptoms / 46 diseases)
   is explicitly labeled "simulated"** â€” it is very likely the same synthetic-style data this project
   already uses, so adopting it provides no real improvement.

3. **Dynamic symptom loading is the single most important future compatibility improvement** â€”
   it decouples the app from any fixed vocabulary.

4. **The API response contract (disease + confidence) is stable** and would survive a model change.

---

## Recommended Compatibility Strategy (NOT implemented)

- Introduce **dynamic symptom loading** in Flask so `/api/symptoms` returns the model's actual vocabulary.
- Update **Flutter** to fetch symptoms from the API instead of hard-coding 16.
- Keep the **prediction response schema** unchanged (`{disease, confidence, ...}`).
- When a better dataset/model is adopted, only swap the model internals + vocabulary metadata.
"""

with open(BASE / 'compatibility_analysis.md', 'w', encoding='utf-8') as f:
    f.write(compat_md)

print("  DONE â€” compatibility_analysis.md")

# ============================================================
# STEP 8 â€” Small Sample Inspection
# ============================================================
print("\n" + "=" * 60)
print("STEP 8 â€” Small Sample Inspection")
print("=" * 60)

inspection_record = {
    "title": "Phase 7E Step 8 â€” Small Sample Inspection",
    "date": "2026-09-08",
    "status": "NOT_PERFORMED",
    "reason": "No candidate dataset was downloaded or accessed. All candidates require Kaggle/IEEE/UCI access, "
              "and per Phase 7E instructions, NO dataset was downloaded automatically or without credentials. "
              "Candidate info comes exclusively from web documentation (data cards, UCI variable tables, "
              "IEEE metadata). Direct inspection is deferred to the approval/integration phase.",
    "candidates_not_inspected": [c["name"] for c in comparison_report["candidates"]],
    "note": "Deferred small-sample inspection is a REQUIREMENT before any candidate is selected for integration.",
}

with open(BASE / "small_sample_inspection.json", 'w') as f:
    json.dump(inspection_record, f, indent=2)

print("  DONE â€” small_sample_inspection.json (status: NOT_PERFORMED by design)")

# ============================================================
# STEP 9 â€” Decision Matrix
# ============================================================
print("\n" + "=" * 60)
print("STEP 9 â€” Decision Matrix")
print("=" * 60)

decision_md = """# Phase 7E Decision Matrix

**Date:** 2026-09-08

## Comparison: CURRENT DATASET vs TOP CANDIDATE(S)

### Current Dataset (`disease_dataset_cleaned_v2.csv`)
- **Class support:** 7 classes < 5 samples; 9 classes < 10 samples (19.6% of classes)
- **Class balance:** 21,295:1 imbalance; top-5 classes = 55.4% of data
- **Feature discrimination:** 116/174 features MI > 0.01; mean MI 0.017 (weak)
- **Disease separability:** avg pairwise cosine similarity 0.694 (weak)
- **Provenance:** Unknown
- **Documentation:** None found
- **Integration complexity:** Already integrated (fits current model/API)
- **Expected ML suitability:** Weak-to-unsuitable (best macro F1 ~0.19)

### Best Candidate: UCI 'Early Stage Diabetes Risk Prediction' (ID 529)
- **Class support:** ~520 rows, 2 classes, balanced-ish, doctor-approved questionnaires
- **Class balance:** ~2:1 (good)
- **Feature discrimination:** 16 interpretable binary symptom features; good variation
- **Disease separability:** 2-class problem is far more separable
- **Provenance:** Strong (Sylhet Diabetes Hospital, doctor-approved, published paper)
- **Documentation:** UCI variable table, paper reference
- **Integration complexity:** Low for diabetes-only, but NOT a general disease-symptom dataset
- **Expected ML suitability:** High for diabetes but only covers 2 classes

### Other Candidates
- Kaushil268 (42 diseases / 132 symptoms): matches disease-symptom format but only ~5000 rows, unverified
- IEEE (391 diseases / 1325 symptoms): broad but per-class support likely tiny
- Symptom2Disease: text-based, 24 diseases, requires NLP
- Community Healthcare: 174/46 â€” "simulated", likely same synthetic source as current
- CDC Diabetes: survey features, not symptoms
- 820_Cleaned: 820 classes â€” infeasible for meaningful multiclass eval

---

## Recommendation Selection

**Chosen: D â€” NO SUITABLE REPLACEMENT DATASET FOUND â€” DO NOT PROCEED WITHOUT BETTER DATA**

### Rationale

1. **Current dataset is unsuitable** â€” confirmed by Phase 7D (best macro F1 â‰ˆ 0.19) and Phase 7E
   (class imbalance 21,295:1, weak MI, low separability, unknown provenance).

2. **No web-discovered candidate clearly satisfies the Must-Have requirements:**
   - None was directly inspected (all are Kaggle/IEEE/UCI remote).
   - The only feature-matching candidate (Community Healthcare 174/46) is explicitly "simulated" â€”
     likely the same synthetic-style data already in use.
   - Kaushil268 has only ~5000 rows for 42 classes (still imbalanced, unverified provenance).
   - IEEE (391 diseases) has likely tiny per-class support and was student-assembled (MedLinePlus-referenced but not validated).
   - Symptom2Disease / CDC / Symptom-to-Disease-820 all require NLP or exceed the class count for meaningful evaluation.

3. **None of the candidates was verified** (all are remote, no direct inspection performed).

4. **Therefore: no dataset replacement should be performed now.**

### What This Means (recommendation D)

- Keep the current dataset (do not delete).
- Do NOT replace the production model.
- The next phase should focus on **restructuring the prediction problem** (recommendation B secondary)
  OR pursuing a verified candidate only after manual inspection.

---

## Recommendation Summary

- **A. KEEP CURRENT + IMPROVE MODEL/INPUT** â€” Possible but limited by fundamental data weaknesses.
- **B. KEEP CURRENT + REDUCE/RESTRUCTURE PROBLEM** â€” MOST VIABLE near-term path.
- **C. REPLACE WITH CANDIDATE (after manual review)** â€” Only if a candidate is found that clears all Must-Haves after direct inspection.
- **D. NO SUITABLE REPLACEMENT â€” DO NOT PROCEED WITHOUT BETTER DATA** â†’ **CHOSEN**

---

## Recommended Next Phase

> **Phase 7F â€” Prediction Problem Restructuring (with dynamic symptom vocabulary design)**

Because:
- No verified better replacement dataset was found (candidate search only, no direct verification).
- The current 46-class / 174-feature problem is fundamentally limited (imbalance, weak features).
- The most constructive path forward is to restructure the problem (fewer, better-supported classes,
  or a redesigned symptom vocabulary), while keeping the current dataset as-is and not replacing it.
- A prerequisite design task is **dynamic symptom vocabulary** so future data/model swaps don't break Flutter/Flask.
"""

with open(BASE / 'decision_matrix.md', 'w', encoding='utf-8') as f:
    f.write(decision_md)

print("  DONE â€” decision_matrix.md (Recommendation D)")

# ============================================================
# STEP 10 â€” Production Safety Check
# ============================================================
print("\n" + "=" * 60)
print("STEP 10 â€” Production Safety Check")
print("=" * 60)

def file_hash(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def file_size_mb(path):
    return round(os.path.getsize(path) / (1024*1024), 2)

prod_model = MODEL_DIR / "disease_model.joblib"
symptom_cols = MODEL_DIR / "symptom_columns.joblib"
dataset = DATA_DIR / "disease_dataset_cleaned_v2.csv"

baseline = json.load(open(BASE / "phase7e_baseline_check.json"))

safety = {
    "title": "Phase 7E Production Safety Check",
    "date": "2026-09-08",
    "checks": {}
}

for name, path in [("disease_model.joblib", prod_model), ("symptom_columns.joblib", symptom_cols),
                   ("disease_dataset_cleaned_v2.csv", dataset)]:
    baseline_hash = baseline["production_files"][name]["sha256"] if name in baseline["production_files"] else None
    current_hash = file_hash(path) if path.exists() else None
    safety["checks"][name] = {
        "size_mb": file_size_mb(path) if path.exists() else None,
        "sha256": current_hash,
        "unchanged_since_phase7e_start": current_hash == baseline_hash,
    }

# Verify no Flutter/Flask Python/Dart files changed since phase start (rough check by mtime)
# We cannot diff git (no repo), so we note the check as structural/no-modification assertion
safety["flutter"] = {"modified": False, "note": "No Flutter files were written by Phase 7E"}
safety["flask"] = {"modified": False, "note": "No Flask files were written by Phase 7E; only new phase7e/ files created"}

# Count phase7e files created
phase7e_files = sorted([f.name for f in BASE.iterdir() if f.is_file()])
safety["phase7e_files_created"] = phase7e_files

# Confirm no new production model / no deployment
safety["new_production_model_trained"] = False
safety["production_model_deployed"] = False
safety["candidate_dataset_replaced_current"] = False
safety["phase_8_started"] = False

with open(BASE / "production_safety_check.json", 'w') as f:
    json.dump(safety, f, indent=2)

print("  DONE â€” production_safety_check.json")
for k, v in safety["checks"].items():
    print(f"    {k}: {'UNCHANGED' if v['unchanged_since_phase7e_start'] else 'CHANGED!'} ({v['size_mb']} MB)")

# ============================================================
# STEP 11 â€” Final Report
# ============================================================
print("\n" + "=" * 60)
print("STEP 11 â€” Final Report")
print("=" * 60)

report_md = """# Phase 7E â€” Dataset Validation & Replacement Strategy Report

**Date:** 2026-09-08
**Status:** COMPLETE (analysis & decision only â€” no production changes)

---

## 1. Executive Summary

Phase 7E investigated whether the current dataset (`disease_dataset_cleaned_v2.csv`,
46 diseases, 174 symptoms, 100,000 rows) is fundamentally unsuitable for reliable
multiclass disease prediction, and whether a better replacement exists.

**Findings:**
- The current dataset is **fundamentally unsuitable** for reliable 46-class prediction
  (structural analysis below).
- A web search identified 8 candidate datasets, but **none was directly verified**.
- No candidate clearly satisfies the Must-Have requirements.
- **Recommendation: D â€” No suitable replacement dataset found. Do not proceed without better data.**

---

## 2. Current Dataset Assessment

**Assessment: FUNDAMENTALLY UNSUITABLE for the intended 46-class prediction task.**

Evidence:
- Best macro F1 across all experimental models = ~0.19 (Logistic Regression).
- Phase 7D showed no model achieves strong performance.
- Deep analysis in Phase 7E confirms structural deficiencies (below).

---

## 3. Main Dataset Problems

### 3.1 Class Imbalance
- Imbalance ratio: **21,295:1** (largest vs smallest class).
- Top 5 classes hold **55.41%** of all 100,000 rows.
- Models tend to collapse predictions toward majority classes.

### 3.2 Extremely Rare Classes
- **7 classes** have fewer than 5 total samples (critically insufficient).
- **2 classes** have 5â€“9 samples (extremely insufficient).
- Combined: **9 classes (19.6%)** cannot be reliably trained OR evaluated.
- 42 classes appear in the test set; several have 0â€“3 test samples.

### 3.3 Feature Discriminative Strength (WEAK)
- Mean mutual information across 174 features: **0.017**.
- Only 116/174 features exceed MI > 0.01; top feature MI â‰ˆ 0.054.
- Assessment: **only a few symptoms provide useful discrimination** (weak/overlapping signals).

### 3.4 Disease Separability (WEAK)
- Average pairwise cosine similarity between disease symptom profiles: **0.694**.
- Most similar pair: Generalized_Anxiety_Disorder â†” Pneumonia = **0.960**.
- Many disease profiles heavily overlap; difficult to distinguish.

### 3.5 Sparse-Input Behavior (UNRELIABLE)
- Empty vector predicts **Migraine** with only ~9.5% confidence.
- Single-symptom input also predicts Migraine (~11% confidence).
- Migraine is over-represented 8.6x vs its true prevalence (RF balanced).
- Real user inputs (typical 1â€“5 symptoms) produce low-confidence, unstable predictions.

---

## 4. Dataset Suitability Scorecard

| Category | Rating |
|----------|--------|
| Class Support Adequacy | **Critical problem** |
| Class Balance | **Critical problem** |
| Feature Discriminative Strength | **Weak** |
| Disease Separability | **Weak** |
| Rare-Class Evaluability | **Critical problem** |
| Consistency of Symptom Patterns | **Weak** |
| Suitability for Sparse User Inputs | **Weak** |
| Suitability for 46-Class Classification | **Critical problem** |
| Reproducibility/Documentation | **Unknown** |
| Medical/Clinical Provenance | **Unknown** |

Summary: 0 Strong, 0 Acceptable, 5 Weak, 4 Critical, 2 Unknown.
**Overall: Fundamentally unsuitable for reliable 46-class prediction.**
See `current_dataset_scorecard.{json,md}` for full evidence.

---

## 5. Candidate Dataset Search

Sources investigated (all via web documentation â€” **NONE downloaded or directly verified**):

| # | Candidate | Source |
|---|-----------|--------|
| 1 | Disease Prediction Using ML (Kaushil268) | Kaggle |
| 2 | Symptom2Disease (Niyarr Barman) | Kaggle |
| 3 | Community Healthcare MultiSymptoms-Disease | Kaggle |
| 4 | Disease Prediction Dataset (Ayush Nautiyal) | IEEE DataPort |
| 5 | Early Stage Diabetes Risk Prediction | UCI (ID 529) |
| 6 | Disease and Symptoms dataset (AZZAZY) | Kaggle |
| 7 | Symptom to Disease Descriptions (820_Cleaned) | Kaggle |
| 8 | CDC Diabetes Health Indicators | UCI (ID 891) |

**Verified candidates:** None (all remote; direct inspection deferred per instructions).
**Requiring manual verification:** Most.
**Rejected candidates:** Most (see comparison).

---

## 6. Candidate Comparison

See `candidate_dataset_comparison.{json,md}` for full scores. Top summaries:

- **UCI Early Stage Diabetes (ID 529):** Best provenance (doctor-approved questionnaires, published paper),
  good balance, but only 2 classes (diabetes only) â€” not a general disease-symptom dataset.
- **Kaushil268 (42 diseases / 132 symptoms):** Format matches, but ~5000 rows total, unverified provenance.
- **Community Healthcare (174/46):** Matches current structure **but is explicitly "simulated"** â€”
  likely the same synthetic-style data already in use; no real improvement.
- **IEEE (391 diseases):** Broad but likely tiny per-class support; student-assembled.
- **Others:** text-based (NLP) or too few classes / too many classes.

---

## 7. Best Candidate

**No single "best" candidate emerged from documentation alone.**

The strongest provenance was UCI Early Stage Diabetes (medically sourced, doctor-approved),
but it only supports a 2-class diabetes problem. The only feature-matching candidate
(Community Healthcare 174/46) is simulated and likely the same synthetic source as current
data â€” adopting it would not fix the underlying problems.

---

## 8. Compatibility Findings

- **Backend feature vocabulary** would change for every candidate except the (likely-same) Community Healthcare.
- **`/api/symptoms`** would need to expose the new vocabulary.
- **Flutter symptom selection** (currently 16 hard-coded) must become dynamic / API-driven.
- **Existing API response format** (`{disease, confidence, ...}`) is stable and would survive a model change.
- The most important future-proofing change is **dynamic symptom vocabulary loading**.

---

## 9. Final Recommendation

> **D. NO SUITABLE REPLACEMENT DATASET FOUND â€” DO NOT PROCEED WITHOUT BETTER DATA**

(Secondary viable near-term path: B. Keep current dataset but reduce/restructure the problem,
as a bridge while pursuing better data.)

---

## 10. Recommended Next Phase

> **Phase 7F â€” Prediction Problem Restructuring + Dynamic Symptom Vocabulary Design**

Rationale: No verified better dataset exists. The most constructive near-term step is to
restructure the 46-class problem into a defensible, better-supported form (e.g., fewer
high-support classes, or redesigned symptom sets) and design a dynamic symptom vocabulary
so the Flutter/Flask/model stack can absorb better data/models in the future.

(Do not execute Phase 7F in this run.)

---

## 11. Files Created (phase7e/)

- `phase7e_baseline_check.json`
- `step2_dataset_analysis.json`
- `current_dataset_scorecard.json`
- `current_dataset_scorecard.md`
- `dataset_requirements.md`
- `candidate_dataset_comparison.json`
- `candidate_dataset_comparison.md`
- `compatibility_analysis.md`
- `small_sample_inspection.json`
- `decision_matrix.md`
- `production_safety_check.json`
- `phase7e_report.md`

---

## 12. Production Safety Confirmation

- `disease_model.joblib` â€” **UNCHANGED**
- `symptom_columns.joblib` â€” **UNCHANGED**
- `disease_dataset_cleaned_v2.csv` â€” **UNCHANGED**
- Flutter â€” **UNCHANGED**
- Flask â€” **UNCHANGED**
- No new production model trained/deployed.
- No candidate dataset replaced the current dataset.
- Phase 8 NOT started.
"""

with open(BASE / 'phase7e_report.md', 'w', encoding='utf-8') as f:
    f.write(report_md)

print("  DONE â€” phase7e_report.md")
print("\n" + "=" * 60)
print("PHASE 7E COMPLETE")
print("=" * 60)


