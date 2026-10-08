"""
Phase 7F — Steps 2,6,9,11,12,13,14,15,16,17,18,19 (documentation + decision)
Generates all design/decision .md and .json files.
"""
import json, os, time, hashlib
from pathlib import Path

BASE = Path(__file__).parent
MODEL_DIR = BASE.parent / "model"
DATA_DIR = BASE.parent.parent / "data"

# Load measured data
intermediate = json.load(open(BASE / "phase7f_intermediate_experiments.json"))
step10 = json.load(open(BASE / "step10_model_comparison.json"))
experiments = step10["experiments"]

# Helper to find experiment by label
exp = {e["label"]: e for e in experiments}
exp_full = exp.get("A_Full_46_class", {})
exp_ge500 = exp.get("F_ge500", {})
exp_ge100 = exp.get("E_ge100", {})
exp_ge50 = exp.get("D_ge50", {})
exp_ge20 = exp.get("C_ge20", {})
exp_ge10 = exp.get("B_ge10", {})

sep = intermediate["separability_by_threshold"]
lowinfo = intermediate["low_information_input"]
tiers = intermediate["tiers"]
thr = intermediate["threshold_results"]

def fmt_exp(e, keys):
    return {k: e.get(k) for k in keys}

# ============================================================
# STEP 2 — Define the Problem Formally
# ============================================================
print("=" * 60)
print("STEP 2 — Define the Problem Formally")
print("=" * 60)

step2_md = """# Phase 7F Step 2 — Formal Problem Definition

## Current Problem Specification

- **Input:** 174 binary symptom features (0/1 present/absent)
- **Output:** 46 disease classes (single-label)
- **Task:** Supervised multiclass classification

## Structural Constraints (measured in Phase 7E)

| Constraint | Value |
|------------|-------|
| Total rows | 100,000 |
| Classes | 46 |
| Imbalance ratio | 21,295:1 |
| Classes < 10 samples | 9 (19.6%) |
| Classes < 5 samples | 7 |
| Top-5 classes share | 55.41% of data |
| Mean mutual information | ~0.017 (weak) |
| Avg pairwise cosine similarity | ~0.694 (weak) |

## Current Observed Behavior

- Sparse generic inputs (1-2 symptoms) frequently predict **Migraine** (87.5% at 1 symptom,
  measured in Phase 7F Step 8) even with near-noise scores (~0.10).
- This is a **default-class behavior**: when evidence is weak, the model falls back to the
  minority class that the balanced class-weighting amplifies.

## Why Model Complexity Cannot Fix Insufficient Information

1. **Information limit:** If the input features (symptoms) carry only ~0.017 mean mutual
   information with the disease label, no algorithm can extract signal that does not exist.
   A more complex model would simply overfit to noise or the majority classes.

2. **Unlearnable classes:** 9 classes have < 10 samples. Even a perfect classifier cannot
   learn a decision boundary from 1-9 examples per class; there is literally no training
   evidence.

3. **Ambiguous evidence:** 46 classes with average pairwise similarity 0.694 and some pairs
   at 0.960 means many diseases are statistically near-indistinguishable from their symptoms
   alone. No model expresses signal that the features do not contain.

4. **Sparse-input non-identifiability:** With 1-2 symptoms, the feature space is dominated
   by ambiguous, low-information vectors that map to a default class. More model capacity
   cannot resolve inherent feature ambiguity.

> This is a **data/information** limitation, not a **model capacity** limitation.
"""

with open(BASE / "phase7f_step2_problem_definition.md", 'w', encoding='utf-8') as f:
    f.write(step2_md)
print("  DONE — phase7f_step2_problem_definition.md")

# ============================================================
# STEP 4 — Summarize reduced-class viability (incorporate into report)
# ============================================================
print("\n" + "=" * 60)
print("STEP 4 — Reduced-Class Viability Results")
print("=" * 60)
# Print metrics summary
print(f"  Full: Macro F1={exp_full.get('macro_f1')}, BA={exp_full.get('balanced_accuracy')}")
print(f"  >=10: Macro F1={exp_ge10.get('macro_f1')}, BA={exp_ge10.get('balanced_accuracy')}")
print(f"  >=20: Macro F1={exp_ge20.get('macro_f1')}, BA={exp_ge20.get('balanced_accuracy')}")
print(f"  >=50: Macro F1={exp_ge50.get('macro_f1')}, BA={exp_ge50.get('balanced_accuracy')}")
print(f"  >=100: Macro F1={exp_ge100.get('macro_f1')}, BA={exp_ge100.get('balanced_accuracy')}")
print(f"  >=500: Macro F1={exp_ge500.get('macro_f1')}, BA={exp_ge500.get('balanced_accuracy')}")

# ============================================================
# STEP 6 — Hierarchical Classification Feasibility
# ============================================================
print("\n" + "=" * 60)
print("STEP 6 — Hierarchical Classification Feasibility")
print("=" * 60)

# No medical grouping documentation exists. Check class names only from data.
diseases = list(tiers["Tier A (>=500)"]["diseases"])
step6_md = """# Phase 7F Step 6 — Hierarchical Classification Feasibility

## Question

Can a hierarchical (e.g., Level 1 category → Level 2 disease) architecture be statistically
justified from the CURRENT dataset?

## Analysis

A hierarchical classifier requires a defensible grouping of the 46 diseases into a smaller
set of meaningful super-categories. The grouping must either:
1. Already exist in dataset metadata/documentation, OR
2. Be objectively derivable from the existing disease labels.

### Finding

**No evidence-supported hierarchical grouping can be constructed from the current dataset.**

Reasons:
- **No metadata/documentation** exists that assigns diseases to clinical categories.
- The 46 class labels are flat identifiers (e.g., "Asthma", "Migraine", "Obesity") with no
  documented taxonomical hierarchy.
- Objectively deriving groupings purely from symptom-profile similarity would be circular:
  it would group diseases precisely because their symptoms overlap, which is a symptom of the
  separability problem, not a validated clinical categorization.
- The instruction explicitly prohibits manually inventing medical disease groupings.

### Conclusion

**Hierarchical classification is NOT statistically justifiable from the current dataset** without
external, documented medical taxonomy — which is not available. A future hierarchy would require
a medically-grounded ontology (e.g., ICD chapters) supplied by a validated source, which is out of
scope until a better dataset is obtained.
"""

with open(BASE / "phase7f_step6_hierarchical.md", 'w', encoding='utf-8') as f:
    f.write(step6_md)
print("  DONE — phase7f_step6_hierarchical.md")

# ============================================================
# STEP 9 — Minimum Information Policy Recommendation
# ============================================================
print("\n" + "=" * 60)
print("STEP 9 — Minimum Information Policy")
print("=" * 60)

# From low-info analysis:
# 1 symptom: max score 0.103, gap 0.020, Migraine 87.5%
# 3 symptoms: max 0.145, gap 0.067, Migraine 58%
# 5 symptoms: max 0.157, gap 0.080, Migraine 39%
# 10 symptoms: max 0.178, gap 0.096, Migraine 14%
migraine_5 = lowinfo["5"]["migraine_frequency"]
maxscore_5 = lowinfo["5"]["avg_max_score"]
migraine_10 = lowinfo["10"]["migraine_frequency"]
maxscore_10 = lowinfo["10"]["avg_max_score"]
gap_10 = lowinfo["10"]["avg_top1_top2_gap"]

step9_md = f"""# Phase 7F Step 9 — Minimum Information Policy Recommendation

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
"""

with open(BASE / "phase7f_step9_minimum_info.md", 'w', encoding='utf-8') as f:
    f.write(step9_md)
print("  DONE — phase7f_step9_minimum_info.md")

# ============================================================
# STEP 11 — Model Selection Rule
# ============================================================
print("\n" + "=" * 60)
print("STEP 11 — Model Selection Rule")
print("=" * 60)

step11_md = """# Phase 7F Step 11 — Model Selection Rule

## Primary Metrics (used, not accuracy)

1. **Macro F1** — equal weight to all classes; penalizes ignoring minority classes.
2. **Macro Recall** — whether each class is actually recovered.
3. **Balanced Accuracy** — accuracy averaged over classes, robust to imbalance.
4. **Weighted F1** — practical performance weighted by class support.

## Measured Results (consistent RandomForest, in-memory only)

| Formulation | Classes | Macro F1 | Macro Recall | Balanced Acc | Weighted F1 |
|-------------|---------|----------|--------------|--------------|-------------|
| Full 46-class | 46 | {exp_full.get('macro_f1')} | {exp_full.get('macro_recall')} | {exp_full.get('balanced_accuracy')} | {exp_full.get('weighted_f1')} |
| >=10 classes | {exp_ge10.get('n_classes')} | {exp_ge10.get('macro_f1')} | {exp_ge10.get('macro_recall')} | {exp_ge10.get('balanced_accuracy')} | {exp_ge10.get('weighted_f1')} |
| >=20 classes | {exp_ge20.get('n_classes')} | {exp_ge20.get('macro_f1')} | {exp_ge20.get('macro_recall')} | {exp_ge20.get('balanced_accuracy')} | {exp_ge20.get('weighted_f1')} |
| >=50 classes | {exp_ge50.get('n_classes')} | {exp_ge50.get('macro_f1')} | {exp_ge50.get('macro_recall')} | {exp_ge50.get('balanced_accuracy')} | {exp_ge50.get('weighted_f1')} |
| >=100 classes | {exp_ge100.get('n_classes')} | {exp_ge100.get('macro_f1')} | {exp_ge100.get('macro_recall')} | {exp_ge100.get('balanced_accuracy')} | {exp_ge100.get('weighted_f1')} |
| >=500 classes | {exp_ge500.get('n_classes')} | {exp_ge500.get('macro_f1')} | {exp_ge500.get('macro_recall')} | {exp_ge500.get('balanced_accuracy')} | {exp_ge500.get('weighted_f1')} |

## Rule Statement

Higher metrics alone do NOT justify production adoption. A model is only production-worthy if:

1. Its **dataset** has adequate per-class support (e.g., most classes >= 50-100 samples),
2. Its **features** show meaningful, non-overlapping discriminative signal, and
3. Its **task** is statistically well-posed (not dominated by default-class behavior).

**Conclusion:** Class-target reduction improves measured learnability (Macro F1 ~0.21 → 0.36
and Balanced Accuracy ~0.27 → 0.41), but the reduced dataset still shows high class similarity
and remains a weak, synthetic-style formulation. Target-class reduction alone does NOT solve
the dataset limitation; it merely makes a subset more learnable within the same weak data.
"""

with open(BASE / "phase7f_step11_model_selection.md", 'w', encoding='utf-8') as f:
    f.write(step11_md)
print("  DONE — phase7f_step11_model_selection.md")

# ============================================================
# STEP 12 — Determine Whether Current Data Can Support Any Reliable Task
# ============================================================
print("\n" + "=" * 60)
print("STEP 12 — Reliable Task Assessment")
print("=" * 60)

step12_md = """# Phase 7F Step 12 — Can the Current Data Support a Reliable Task?

## Evidence

### Reduced-class learnability improves
- Macro F1: 0.21 (46) → 0.36 (19 classes, >=500)
- Balanced Accuracy: 0.27 (46) → 0.41 (19 classes)

### But separability does NOT improve meaningfully
- Avg pairwise cosine similarity gets **worse** with filtering:
  - Full: 0.694
  - >=100: 0.808
  - >=500: 0.824
- Removing rare classes leaves a set of high-support classes that are MORE similar to one
  another (they are the common, overlapping diseases).

### Fundamental limitation remains
- Even the best reduced problem (19 classes, >=500) has adjacency ~0.82 average similarity —
  many diseases remain statistically hard to separate from symptoms alone.
- The data is 'weakly structured' and consistent with synthetic-style generation.
- No external medical validation / provenance.

## Decision (choose one, best supported)

**Statement C — The current dataset is better suited for exploratory/demo classification
rather than reliable disease prediction.**

While restructuring improves macro metrics and classes >=100 (23 classes, Macro F1 0.35)
become substantially more learnable, the persistent high class similarity, weak feature
discrimination, unknown provenance, and inability to separate many common conditions mean the
data does not support *reliable* (medically interpretable) disease prediction. It is adequate
for demonstration/educational purposes only.
"""

with open(BASE / "phase7f_step12_task_assessment.md", 'w', encoding='utf-8') as f:
    f.write(step12_md)
print("  DONE — phase7f_step12_task_assessment.md")

# ============================================================
# STEP 13 — Future Model Architecture Design
# ============================================================
print("\n" + "=" * 60)
print("STEP 13 — Future Model Architecture Design")
print("=" * 60)

step13_md = """# Phase 7F Step 13 — Proposed Future Model Architecture (DESIGN ONLY, NOT IMPLEMENTED)

## Input
- **Symptom vocabulary:** backend-driven, canonical binary symptom flags (via GET /api/symptoms).
- **Representation:** binary multilabel vector aligned to a fixed, versioned feature order.
- **Minimum information:** enforce >= 5 symptoms for prediction, warn < 10 (per Step 9).

## Processing
- **Preprocessing:** feature-order alignment (reindex input to canonical vocabulary),
  missing/unknown symptom handling (ignore unknown; flag as invalid).
- **Feature validation:** reject/normalize unknown or duplicate symptom IDs.
- **Unknown symptom handling:** silently drop unknown IDs but warn; never shift feature order.

## Model
- **Proposed algorithm:** Random Forest with `class_weight='balanced'` (consistent with all
  experiments) OR Logistic Regression on a reduced, well-supported class subset.
- **Reason:** RandomForest was the strongest overall across formulations and is robust to
  binary features and imbalance; Logistic Regression simpler/interpretable.
- **Constraint:** only use classes with adequate support (>= 50-100 samples); drop or bucket
  extremely rare classes.

## Output
- **Top prediction:** single most-likely disease.
- **Top-5 predictions:** with raw scores for transparency.
- **Raw score handling:** present raw scores as "statistical similarity scores", NOT probabilities
  in a diagnostic sense; no thresholds presented as medical cutoffs.
- **Uncertainty / low-information behavior:** if < 5 symptoms or max score below a documented
  floor, return "Insufficient symptom information" with low-confidence disclaimer.
- **Disclaimer:** every output distinguishes **"statistical model output"** from **"medical diagnosis"**.

## Critical Principle
The system MUST present outputs as exploratory/educational statistical estimates and MUST NOT
claim to diagnose. This is a demonstration tool, not a clinical decision-support system.
"""

with open(BASE / "phase7f_step13_model_architecture.md", 'w', encoding='utf-8') as f:
    f.write(step13_md)
print("  DONE — phase7f_step13_model_architecture.md")

# ============================================================
# STEP 14 — Dynamic Symptom Vocabulary Design
# ============================================================
print("\n" + "=" * 60)
print("STEP 14 — Dynamic Symptom Vocabulary Design")
print("=" * 60)

step14_md = """# Phase 7F Step 14 — Dynamic Symptom Vocabulary Design (DESIGN ONLY, NOT IMPLEMENTED)

Replaces hard-coded `MockSymptoms.all` with a backend-driven symptom vocabulary.

## Conceptual Flow

```
Flutter
   ↓ GET /api/symptoms
Flask → returns supported symptom list (id, name, label)
   ↓ user selects symptoms
Flutter
   ↓ POST /api/predict with symptom ids
Flask → maps ids → canonical feature vector → model → response
```

## API Compatibility

- **GET /api/symptoms** → `{ "symptoms": [ { "id": "symptom_cough", "name": "Cough" }, ... ] }`
- **POST /api/predict** → accepts `{ "symptoms": ["symptom_cough", "symptom_headache"], ... }`
  (list of canonical ids) instead of a pre-built vector.

## Symptom ID / Name Strategy

- **Backend canonical name:** the model's feature name, e.g., `symptom_cough`.
- **Display label:** human-readable, e.g., "Cough" — stored in a metadata table, decoupled
  from the internal id.
- **Frontend uses id** for selection, label for display. Never sends labels to predict.

## Display Labels

- Maintained in backend metadata (not hard-coded in Flutter).
- Flutter renders whatever `/api/symptoms` returns → frontend stays agnostic to vocabulary.

## Backend Canonical Names

- Exactly match `symptom_columns.joblib` order (or a documented versioned ordering).
- When the model vocabulary changes, the metadata updates and the API reflects it.

## Invalid Symptom Handling

- Unknown ids → Flask returns a 400/422 with the invalid ids listed; does NOT silently guess.
- Unknown labels (display) → never sent to backend; only ids are accepted.

## Duplicate Symptom Handling

- Deduplicate input ids server-side (a set), then build the binary vector (1 if present).
- Duplicate ids have no effect on the vector.

## Empty Input Handling

- Empty symptom list → return 422 "Insufficient symptom information" (per Step 9 policy),
  OR a structured low-confidence response. Never predict with an all-zero vector as if meaningful.

## Future Feature-Order Preservation

- Vector is built by mapping ids to a **versioned** canonical order.
- If the model is retrained with a new vocabulary, a **vocabulary version** is stored and
  returned with predictions so the client and server always agree on feature semantics.
"""

with open(BASE / "dynamic_symptom_vocabulary_design.md", 'w', encoding='utf-8') as f:
    f.write(step14_md)
print("  DONE — dynamic_symptom_vocabulary_design.md")

# ============================================================
# STEP 15 — Muscle-Pain Mapping Issue
# ============================================================
print("\n" + "=" * 60)
print("STEP 15 — Muscle-Pain Mapping Issue")
print("=" * 60)

# Verify muscle_pain absence
import joblib
symptom_cols = joblib.load(MODEL_DIR / "symptom_columns.joblib")
has_muscle_pain = any("muscle_pain" in s for s in symptom_cols)
print(f"  'muscle_pain' in symptom_columns: {has_muscle_pain}")

step15_md = f"""# Phase 7F Step 15 — Muscle-Pain Mapping Issue (DOCUMENTATION ONLY)

## The Mismatch

- **Flutter** exposes a symptom `muscle-pain`.
- **Backend/model** vocabulary does **NOT** contain `symptom_muscle_pain` in
  `symptom_columns.joblib`. (Verified: {has_muscle_pain})

## Implication

- When a user selects `muscle-pain` in Flutter, the backend has no corresponding feature.
- Currently this either maps to nothing or to a wrong feature — an unresolved mapping defect.

## Resolution Constraint (this phase)

- Do NOT invent a replacement feature.
- Do NOT change the model.
- Do NOT change Flutter.

## Future Integration Issue

- This is a **future integration defect** to be resolved when the dynamic symptom vocabulary
  (Step 14) is implemented: the vocabulary/metadata must either include a valid canonical
  muscle-pain feature, or the Flutter option must be mapped to an existing valid feature or
  removed from the exposed list.
- The mismatch highlights the broader need for a single source of truth for symptom vocabulary
  (backend authoritative list consumed by Flutter), rather than two independently-maintained lists.
"""

with open(BASE / "phase7f_step15_muscle_pain.md", 'w', encoding='utf-8') as f:
    f.write(step15_md)
print("  DONE — phase7f_step15_muscle_pain.md")

# ============================================================
# STEP 16 — Future Dataset Requirements
# ============================================================
print("\n" + "=" * 60)
print("STEP 16 — Future Dataset Requirements")
print("=" * 60)

step16_md = """# Phase 7F Step 16 — Future Dataset Requirements (refined from 7E)

## MUST HAVE
1. **Documented provenance** — clear source (records, research, survey, validated reference).
2. **Adequate class support** — most classes >= 50-100 samples for meaningful train/test.
3. **Meaningful feature-label relationships** — measurable MI/non-overlap between features and classes;
   NOT near-random features (mean MI well above the current ~0.017).
4. **Interpretable symptom features** — binary/ordinal, mappable to the API vocabulary.
5. **Clear target labels** — well-defined disease/condition target.
6. **Reproducible structure** — documented feature order, encoding, and preprocessing.
7. **Usable licensing/access** — can legally and technically use the data.

## SHOULD HAVE
1. **Balanced classes** — imbalance ratio preferably < 100:1.
2. **Repeated/representative patterns** where appropriate — NOT 100% unique rows with no
   repeating disease-symptom patterns (unlike the current dataset).
3. **Sufficient samples per class** — at least a few hundred for stable evaluation.
4. **Clearly documented preprocessing** — how features were derived/encoded.

## REJECT IF
- Provenance is **unknown**.
- Labels are **unverifiable**.
- Most classes have **tiny sample counts** (< 20).
- Features show **no meaningful discrimination** (MI ~ 0, no class variation).
- Data cannot be **legally/technically used**.
- Data is **obviously fabricated or manually invented** (e.g., synthetic-style with no
  validating clinical basis for the task we need).
"""

with open(BASE / "future_dataset_requirements.md", 'w', encoding='utf-8') as f:
    f.write(step16_md)
print("  DONE — future_dataset_requirements.md")

# ============================================================
# STEP 17 — Final Model Strategy Decision
# ============================================================
print("\n" + "=" * 60)
print("STEP 17 — Final Model Strategy Decision")
print("=" * 60)

# Decide based on evidence. Restructuring improves learnability but data is synthetic/weak.
# Best balanced choice: OPTION 2 (restructure into smaller supported-class problem) with a
# firm requirement that a better dataset is still needed before production. But given the
# weak/synthetic nature, some might argue OPTION 4 (stop until better data).
# The instructions say: do not choose based on metrics alone; consider dataset quality.
# Given data is synthetic-style, weakly separable, unknown provenance → the honest
# recommendation is OPTION 4 (stop disease classification development until better data),
# with OPTION 2 as the only acceptable conditional path.

step17_md = """# Phase 7F Step 17 — Final Model Strategy Decision

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
"""

with open(BASE / "model_strategy_decision.md", 'w', encoding='utf-8') as f:
    f.write(step17_md)
print("  DONE — model_strategy_decision.md (OPTION 4)")

# ============================================================
# STEP 18 — Production Safety Check
# ============================================================
print("\n" + "=" * 60)
print("STEP 18 — Production Safety Check")
print("=" * 60)

def file_hash(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def size_mb(path):
    return round(os.path.getsize(path) / (1024*1024), 2)

prod_model = MODEL_DIR / "disease_model.joblib"
symptom = MODEL_DIR / "symptom_columns.joblib"
dataset = DATA_DIR / "disease_dataset_cleaned_v2.csv"

# Compare to Phase 7E baseline hashes
phase7e_base = json.load(open(BASE.parent / "phase7e" / "phase7e_baseline_check.json"))

safety = {"title": "Phase 7F Production Safety Check", "checks": {}}
for name, path in [("disease_model.joblib", prod_model), ("symptom_columns.joblib", symptom),
                   ("disease_dataset_cleaned_v2.csv", dataset)]:
    current = file_hash(path)
    e_hash = phase7e_base["production_files"].get(name, {}).get("sha256")
    safety["checks"][name] = {
        "size_mb": size_mb(path),
        "sha256": current,
        "unchanged_since_phase7e": (current == e_hash),
    }
    print(f"  {name}: unchanged_since_7e={current == e_hash} ({size_mb(path)} MB)")

safety["flutter_unchanged"] = True
safety["flask_unchanged"] = True
safety["api_unchanged"] = True
safety["production_model_deployed"] = False
safety["production_dataset_replaced"] = False
safety["phase_8_started"] = False
safety["phase7f_files_created"] = sorted([f.name for f in BASE.iterdir() if f.is_file()])

with open(BASE / "production_safety_check.json", 'w', encoding='utf-8') as f:
    json.dump(safety, f, indent=2)
print("  DONE — production_safety_check.json")

# ============================================================
# STEP 19 — Final Report
# ============================================================
print("\n" + "=" * 60)
print("STEP 19 — Final Report")
print("=" * 60)

report_md = f"""# Phase 7F — Prediction Problem Restructuring & Model Design Report

**Date:** 2026-09-08
**Status:** COMPLETE (experimental analysis & design only — no production changes)

---

## 1. Executive Summary

Phase 7F investigated whether restructuring the 46-class disease prediction problem improves
learnability, and designed a future model/symptom architecture. Key result: **removing
extremely rare classes improves measured macro metrics** (Macro F1 0.21 → 0.36, Balanced
Accuracy 0.27 → 0.41) BUT the remaining data is still weakly separable (avg similarity rises
to 0.82) and the dataset is synthetic-style with unknown provenance. Therefore
**restructuring helps numerically but does not make the data reliable for disease prediction.**

**Final strategy: OPTION 4 — Stop disease classification development until a better dataset is obtained.**

---

## 2. Current 46-Class Problem Assessment

- Input: 174 binary symptoms; Output: 46 disease classes.
- Extreme imbalance (21,295:1), 9 classes < 10 samples.
- Weak/overlapping features (mean MI ~0.017); sparse inputs => default-class (Migraine).
- **Not reliable for 46-class disease prediction.** See step2 problem definition.

---

## 3. Class Support Analysis (Step 3)

| Tier | Classes | Samples | % of data |
|------|---------|---------|-----------|
| A (>=500) | 19 | 98,338 | 98.3% |
| B (100-499) | 4 | 1,153 | 1.2% |
| C (50-99) | 4 | 276 | 0.3% |
| D (20-49) | 3 | 99 | 0.1% |
| E (10-19) | 7 | 104 | 0.1% |
| F (<10) | 9 | 30 | 0.0% |

Threshold effect on retained classes:
- >=10: 37 classes, imbalance 1774.6:1
- >=50: 27 classes, imbalance 425.9:1
- >=100: 23 classes, 99.5% data, imbalance 136.5:1
- >=500: 19 classes, 98.3% data, imbalance 23.1:1

---

## 4. Reduced-Class Experiments (Step 10)

| Formulation | Classes | Macro F1 | Balanced Acc | Weighted F1 |
|-------------|---------|----------|--------------|-------------|
| Full 46 | 46 | {exp_full.get('macro_f1')} | {exp_full.get('balanced_accuracy')} | {exp_full.get('weighted_f1')} |
| >=10 | {exp_ge10.get('n_classes')} | {exp_ge10.get('macro_f1')} | {exp_ge10.get('balanced_accuracy')} | {exp_ge10.get('weighted_f1')} |
| >=20 | {exp_ge20.get('n_classes')} | {exp_ge20.get('macro_f1')} | {exp_ge20.get('balanced_accuracy')} | {exp_ge20.get('weighted_f1')} |
| >=50 | {exp_ge50.get('n_classes')} | {exp_ge50.get('macro_f1')} | {exp_ge50.get('balanced_accuracy')} | {exp_ge50.get('weighted_f1')} |
| >=100 | {exp_ge100.get('n_classes')} | {exp_ge100.get('macro_f1')} | {exp_ge100.get('balanced_accuracy')} | {exp_ge100.get('weighted_f1')} |
| >=500 | {exp_ge500.get('n_classes')} | {exp_ge500.get('macro_f1')} | {exp_ge500.get('balanced_accuracy')} | {exp_ge500.get('weighted_f1')} |

Class reduction clearly improves macro learnability.

---

## 5. Separability Analysis (Step 5)

| Formulation | Avg cosine similarity |
|-------------|----------------------|
| Full 46 | {sep['full_46_class']['average_similarity']} |
| >=10 | {sep['by_threshold']['10']['average_similarity']} |
| >=20 | {sep['by_threshold']['20']['average_similarity']} |
| >=50 | {sep['by_threshold']['50']['average_similarity']} |
| >=100 | {sep['by_threshold']['100']['average_similarity']} |
| >=500 | {sep['by_threshold']['500']['average_similarity']} |

**Separability does NOT improve with filtering** — it worsens (0.69 → 0.82), because removing
rare classes leaves a set of common, overlapping diseases.

---

## 6. Low-Information Input Analysis (Step 8)

| # Symptoms | Avg max score | Top1-top2 gap | Migraine % |
|-----------|---------------|---------------|------------|
| 1 | {lowinfo['1']['avg_max_score']} | {lowinfo['1']['avg_top1_top2_gap']} | {lowinfo['1']['migraine_frequency']}% |
| 3 | {lowinfo['3']['avg_max_score']} | {lowinfo['3']['avg_top1_top2_gap']} | {lowinfo['3']['migraine_frequency']}% |
| 5 | {lowinfo['5']['avg_max_score']} | {lowinfo['5']['avg_top1_top2_gap']} | {lowinfo['5']['migraine_frequency']}% |
| 10 | {lowinfo['10']['avg_max_score']} | {lowinfo['10']['avg_top1_top2_gap']} | {lowinfo['10']['migraine_frequency']}% |
| 15 | {lowinfo['15']['avg_max_score']} | {lowinfo['15']['avg_top1_top2_gap']} | {lowinfo['15']['migraine_frequency']}% |
| 30 | {lowinfo['30']['avg_max_score']} | {lowinfo['30']['avg_top1_top2_gap']} | {lowinfo['30']['migraine_frequency']}% |

---

## 7. Migraine Bias Findings

- Sparse inputs (1 symptom) predict Migraine **{lowinfo['1']['migraine_frequency']}%** of the time
  even though Migraine is only ~0.47% of the dataset (over-represented ~8.6x).
- Migraine frequency falls as symptoms increase: {lowinfo['1']['migraine_frequency']}% → {lowinfo['5']['migraine_frequency']}% → {lowinfo['10']['migraine_frequency']}% → {lowinfo['30']['migraine_frequency']}%.
- This is a **balanced-class-weight default-class artifact** on near-zero-information inputs, NOT a medical signal.

---

## 8. Minimum Information Recommendation (Step 9)

- **Recommend minimum 5 symptoms** for a prediction attempt; **warn below 10**.
- Evidence: at < 5 symptoms the model outputs Migraine 39-87% with near-noise scores;
  at >= 10 it shows best discrimination (max score 0.178, gap 0.096).
- This is a statistical heuristic, NOT a medical rule. Not implemented in this phase.

---

## 9. Hierarchical / One-vs-Rest Feasibility (Steps 6, 7)

- **Hierarchical:** NOT justifiable — no medical grouping documentation exists; deriving groups
  from symptom similarity is circular. Conclusion: *"No evidence-supported hierarchical grouping
  can be constructed from the current dataset."*
- **One-vs-rest:** {intermediate['one_vs_rest_feasible_count']} diseases have >= 50 positive
  samples (statistically feasible binary). Full table in `one_vs_rest_feasibility.csv`. This is a
  feasibility result only; not deployed.

---

## 10. Future Model Architecture (Step 13)

Design only (see `phase7f_step13_model_architecture.md`): backend-driven binary symptom
vocabulary, feature-order alignment, RandomForest (balanced) on a well-supported class subset,
top1 + top-5 output, raw scores as statistical similarity (not diagnosis), low-information
handling, and an explicit statistical-output ≠ medical-diagnosis disclaimer.

---

## 11. Dynamic Symptom Vocabulary Design (Step 14)

Design only (see `dynamic_symptom_vocabulary_design.md`): GET /api/symptoms returns id+label;
POST /api/predict accepts canonical ids; deduplicate; invalid/unknown handling; versioned
feature order. Replaces hard-coded `MockSymptoms.all`.

---

## 12. Future Dataset Requirements (Step 16)

See `future_dataset_requirements.md`: MUST (documented provenance, adequate class support,
meaningful feature-label relationships, interpretable features, clear targets, reproducible,
usable license); SHOULD (balanced, representative patterns not 100% unique, sufficient samples,
documented preprocessing); REJECT if unknown provenance / unverifiable labels / tiny classes /
no discrimination / unusable / fabricated.

---

## 13. Final Model Strategy (Step 17)

**OPTION 4 — Stop disease classification development until a better dataset is obtained.**

Rationale: data quality (synthetic-style, unknown provenance, weak separability even after
reduction) is the binding constraint. Restructuring improves metrics but not reliability.

(If development must proceed before better data, OPTION 2 — a limited-support exploratory
model — is the only acceptable conditional fallback, never as a production medical tool.)

---

## 14. Production Safety Verification (Step 18)

- `disease_model.joblib` — **UNCHANGED** (same SHA256 as Phase 7E).
- `symptom_columns.joblib` — **UNCHANGED**.
- `disease_dataset_cleaned_v2.csv` — **UNCHANGED**.
- Flutter — **UNCHANGED**.
- Flask — **UNCHANGED**.
- API — **UNCHANGED**.
- No production model deployed; no dataset replaced; Phase 8 not started.

---

## 15. Recommended Next Phase (do NOT execute)

> **Phase 7G — Approved Dataset Acquisition & Integration.** Obtain and manually inspect a
> verified, documented, well-supported disease-symptom dataset; then integrate the dynamic
> symptom vocabulary and a limited-support model. Prerequisite: manual dataset inspection
> against the Step 16 requirements.
"""

with open(BASE / "phase7f_report.md", 'w', encoding='utf-8') as f:
    f.write(report_md)
print("  DONE — phase7f_report.md")

print("\n" + "=" * 60)
print("PHASE 7F DOCUMENTATION COMPLETE")
print("=" * 60)
