"""
Phase 7F — Experiments: Steps 1,3,4,5,7,8,10
Computes class-support tiers, reduced-class separability, one-vs-rest feasibility,
low-information input analysis, and reduced-class experimental model metrics.
All in-memory only; does not modify production files.
"""
import json, os, time, warnings, gc
import numpy as np
import pandas as pd
from pathlib import Path
from collections import Counter
warnings.filterwarnings('ignore')

BASE = Path(__file__).parent
DATA_DIR = BASE.parent.parent / "data"
MODEL_DIR = BASE.parent / "model"
PHASE7E = BASE.parent / "phase7e"

import matplotlib
matplotlib.use('Agg')

# ============================================================
# STEP 1 — Verify Phase 7E (summary) & write baseline.md
# ============================================================
print("=" * 60)
print("STEP 1 — Verify Phase 7E / Baseline")
print("=" * 60)

phase7e_files = {
    "phase7e_report.md": (PHASE7E / "phase7e_report.md").exists(),
    "current_dataset_scorecard.json": (PHASE7E / "current_dataset_scorecard.json").exists(),
    "step2_dataset_analysis.json": (PHASE7E / "step2_dataset_analysis.json").exists(),
    "decision_matrix.md": (PHASE7E / "decision_matrix.md").exists(),
    "compatibility_analysis.md": (PHASE7E / "compatibility_analysis.md").exists(),
}
print("  Phase 7E outputs present:", all(phase7e_files.values()))
for k, v in phase7e_files.items():
    print(f"    {k}: {'OK' if v else 'MISSING'}")

# Load step2 data
step2 = json.load(open(PHASE7E / "step2_dataset_analysis.json"))
class_counts_raw = step2["class_support"]["class_distribution"]
# Convert to int keys
class_counts = {k: int(v) for k, v in class_counts_raw.items()}

baseline_md = """# Phase 7F Baseline (from Phase 7E findings)

**Date:** 2026-09-08

## Phase 7E Conclusions that Affect Model Design

1. **Full 46-class problem is fundamentally unsuitable** for reliable prediction.
   - Best observed Macro F1 ~= 0.19 (Logistic Regression).
   - Mean mutual information ~= 0.017 (weak feature discrimination).
   - Average pairwise cosine similarity ~= 0.694 (weak disease separability).

2. **Extreme class imbalance:**
   - Largest class (Asthma) = 21,295 samples.
   - Smallest class (Metabolic_Syndrome) = 1 sample.
   - Imbalance ratio = 21,295:1.
   - Top-5 classes hold ~55.41% of the dataset.

3. **Rare-class support is the core constraint:**
   - 9/46 classes have < 10 samples (cannot be trained or evaluated reliably).
   - 7/46 classes have < 5 samples.

4. **All 100,000 symptom vectors are unique** (no repeated patterns); the data is
   'weakly structured' and 'statistically consistent with synthetic-style generation'.

5. **Low-information inputs are unreliable:** Empty/near-empty vectors predict
   Migraine with ~9-11% confidence; Migraine is over-represented ~8.6x vs prevalence.

## Implication for Model Design

Increasing model complexity alone CANNOT fix insufficient information in the input
features. The Phase 7F experiments focus on whether RESTRUCTURING the target (fewer,
better-supported classes) improves learnability — not on blindly training a 46-class model.
"""

with open(BASE / "phase7f_baseline.md", 'w', encoding='utf-8') as f:
    f.write(baseline_md)
print("  DONE — phase7f_baseline.md")

# ============================================================
# Load dataset
# ============================================================
print("\n  Loading dataset...")
t0 = time.time()
df = pd.read_csv(DATA_DIR / "disease_dataset_cleaned_v2.csv")
print(f"  Loaded {df.shape[0]} rows x {df.shape[1]} cols in {time.time()-t0:.1f}s")

# Identify disease column robustly (it is the FIRST column in practice)
disease_col = 'disease' if 'disease' in df.columns else None
if disease_col is None:
    for c in df.columns:
        if 'disease' in c.lower() or 'diagnosis' in c.lower() or 'condition' in c.lower():
            disease_col = c
            break
if disease_col is None:
    disease_col = df.columns[-1]
symptom_cols = [c for c in df.columns if c != disease_col]
y = df[disease_col].values
X = df[symptom_cols].values

# ============================================================
# STEP 3 — Class Support Tiers & Thresholds
# ============================================================
print("\n" + "=" * 60)
print("STEP 3 — Class Support Analysis")
print("=" * 60)

total_samples = len(y)
n_classes_full = len(set(y))

# Confirm class counts from data
counts = Counter(y)

tiers = {
    "Tier A (>=500)": [d for d, c in counts.items() if c >= 500],
    "Tier B (100-499)": [d for d, c in counts.items() if 100 <= c < 500],
    "Tier C (50-99)": [d for d, c in counts.items() if 50 <= c < 100],
    "Tier D (20-49)": [d for d, c in counts.items() if 20 <= c < 50],
    "Tier E (10-19)": [d for d, c in counts.items() if 10 <= c < 20],
    "Tier F (<10)": [d for d, c in counts.items() if c < 10],
}

tier_summary = {}
for tier_name, diseases in tiers.items():
    tier_samples = sum(counts[d] for d in diseases)
    tier_summary[tier_name] = {
        "n_classes": len(diseases),
        "total_samples": int(tier_samples),
        "pct_of_classes": round(len(diseases) / n_classes_full * 100, 2),
        "pct_of_dataset": round(tier_samples / total_samples * 100, 2),
        "diseases": diseases,
    }
    print(f"  {tier_name}: {len(diseases)} classes, {tier_samples:,} samples "
          f"({round(tier_samples/total_samples*100,1)}% of data)")

# Threshold evaluation
thresholds = [10, 20, 50, 100, 500]
threshold_results = {}
for thr in thresholds:
    keep = [d for d, c in counts.items() if c >= thr]
    keep_samples = sum(counts[d] for d in keep)
    if len(keep) == 0:
        continue
    min_c = min(counts[d] for d in keep)
    max_c = max(counts[d] for d in keep)
    imbalance = round(max_c / min_c, 1) if min_c > 0 else None
    # Expected test support under 80/20
    test_expected_min = round(min_c * 0.2, 1)
    test_expected_max = round(max_c * 0.2, 1)
    threshold_results[thr] = {
        "n_classes_retained": len(keep),
        "pct_classes_retained": round(len(keep) / n_classes_full * 100, 2),
        "rows_retained": int(keep_samples),
        "pct_dataset_retained": round(keep_samples / total_samples * 100, 2),
        "min_samples_per_class": int(min_c),
        "max_samples_per_class": int(max_c),
        "imbalance_ratio": imbalance,
        "expected_test_support_min_20pct": test_expected_min,
        "expected_test_support_max_20pct": test_expected_max,
        "diseases_retained": keep,
    }
    print(f"  >= {thr}: {len(keep)} classes, {keep_samples:,} rows "
          f"({round(keep_samples/total_samples*100,1)}%), imbalance {imbalance}:1")

# ============================================================
# STEP 5 + 7 class profile computation (shared)
# ============================================================
print("\n  Computing class profiles...")
def class_profiles(subset_classes):
    profile_map = {}
    mask = np.isin(y, list(subset_classes))
    Xs = X[mask]
    ys = y[mask]
    for d in subset_classes:
        dm = ys == d
        if dm.sum() > 0:
            profile_map[d] = Xs[dm].mean(axis=0)
    return profile_map, Xs, ys

def separability_metrics(profile_map):
    diseases = list(profile_map.keys())
    n = len(diseases)
    if n < 2:
        return None
    from numpy.linalg import norm
    sims = []
    for i in range(n):
        for j in range(i+1, n):
            n1, n2 = norm(profile_map[diseases[i]]), norm(profile_map[diseases[j]])
            if n1 > 0 and n2 > 0:
                sim = np.dot(profile_map[diseases[i]], profile_map[diseases[j]]) / (n1 * n2)
            else:
                sim = 0.0
            sims.append(sim)
    sims = np.array(sims)
    return {
        "n_classes": n,
        "average_similarity": round(float(sims.mean()), 6),
        "max_similarity": round(float(sims.max()), 6),
        "min_similarity": round(float(sims.min()), 6),
        "std_similarity": round(float(sims.std()), 6),
    }

# Full 46-class separability (reuse Phase 7E: avg 0.6942)
full_profiles, _, _ = class_profiles(set(counts.keys()))
full_sep = separability_metrics(full_profiles)
print(f"  Full 46-class avg similarity: {full_sep['average_similarity']}")

# ============================================================
# STEP 5 — Separability after filtering at each threshold
# ============================================================
print("\n" + "=" * 60)
print("STEP 5 — Class Separability After Filtering")
print("=" * 60)

sep_results = {"full_46_class": full_sep, "by_threshold": {}}
for thr in thresholds:
    keep = [d for d, c in counts.items() if c >= thr]
    if len(keep) < 2:
        continue
    profs, _, _ = class_profiles(set(keep))
    sep = separability_metrics(profs)
    sep_results["by_threshold"][str(thr)] = sep
    print(f"  >= {thr}: {sep['n_classes']} classes, avg sim {sep['average_similarity']}")

# ============================================================
# STEP 7 — One-vs-Rest Feasibility
# ============================================================
print("\n" + "=" * 60)
print("STEP 7 — One-vs-Rest Feasibility")
print("=" * 60)

ovr_rows = []
for d, c in counts.items():
    neg = total_samples - c
    pos_pct = round(c / total_samples * 100, 3)
    test_pos = round(c * 0.2, 1)
    test_neg = round(neg * 0.2, 1)
    feasible = c >= 50  # need enough positives for binary
    ovr_rows.append({
        "disease": d,
        "positive_samples": int(c),
        "negative_samples": int(neg),
        "positive_percentage": pos_pct,
        "expected_test_positive_20pct": test_pos,
        "expected_test_negative_20pct": test_neg,
        "one_vs_rest_statistically_feasible": feasible,
    })

ovr_sorted = sorted(ovr_rows, key=lambda r: r["positive_samples"], reverse=True)
with open(BASE / "one_vs_rest_feasibility.csv", 'w', newline='') as f:
    import csv
    w = csv.DictWriter(f, fieldnames=list(ovr_sorted[0].keys()))
    w.writeheader()
    w.writerows(ovr_sorted)

feasible_count = sum(1 for r in ovr_rows if r["one_vs_rest_statistically_feasible"])
print(f"  {feasible_count} diseases have >= 50 positive samples (statistically feasible OVR)")
print("  DONE — one_vs_rest_feasibility.csv")

# ============================================================
# STEP 8 — Low-Information Input Analysis (production model)
# ============================================================
print("\n" + "=" * 60)
print("STEP 8 — Low-Information Input Analysis")
print("=" * 60)

symptom_cols_loaded = None
try:
    import joblib
    prod_model = joblib.load(MODEL_DIR / "disease_model.joblib")
    symptom_columns = joblib.load(MODEL_DIR / "symptom_columns.joblib")
    feature_names = symptom_columns if isinstance(symptom_columns, list) else list(symptom_columns)
    print(f"  Loaded production model, {len(feature_names)} features")

    # Get top discriminative features from Phase 7D feature importance if available
    # Build a deterministic pseudo-random sampler over symptom names
    rng = np.random.RandomState(42)
    # Use the most prevalent symptoms to simulate "user-selected" common symptoms
    # Determine prevalence from the dataset
    prevalences = X.mean(axis=0)
    prev_rank = np.argsort(-prevalences)
    common_symptom_indices = prev_rank[:40]  # top-40 most prevalent

    low_info_results = {}
    n_infos = [1, 2, 3, 5, 10, 15, 20, 30]
    for n in n_infos:
        pred_diseases = []
        max_scores = []
        gaps = []
        top5_diversity = []
        migraine_count = 0
        n_trials = 200
        for trial in range(n_trials):
            vec = np.zeros((1, len(feature_names)))
            # Sample symptoms preferentially from common ones
            chosen = rng.choice(len(feature_names), size=min(n, len(feature_names)), replace=False)
            vec[0, chosen] = 1
            proba = prod_model.predict_proba(vec)[0]
            order = np.argsort(-proba)
            top1 = prod_model.classes_[order[0]]
            top1_score = proba[order[0]]
            gap = proba[order[0]] - proba[order[1]]
            pred_diseases.append(top1)
            max_scores.append(top1_score)
            gaps.append(gap)
            top5_diversity.append(len(set(prod_model.classes_[order[:5]])))
            if top1 == "Migraine":
                migraine_count += 1
        from collections import Counter
        pred_counter = Counter(pred_diseases)
        low_info_results[str(n)] = {
            "avg_max_score": round(float(np.mean(max_scores)), 6),
            "avg_top1_top2_gap": round(float(np.mean(gaps)), 6),
            "avg_top5_diversity": round(float(np.mean(top5_diversity)), 2),
            "migraine_frequency": round(migraine_count / n_trials * 100, 1),
            "top1_distribution_count_classes": len(pred_counter),
            "most_common_top1": pred_counter.most_common(5),
        }
        print(f"  {n} symptom(s): top1={pred_counter.most_common(1)[0][0]} "
              f"({pred_counter.most_common(1)[0][1]}/{n_trials}), "
              f"avg max score={low_info_results[str(n)]['avg_max_score']:.3f}, "
              f"Migraine={low_info_results[str(n)]['migraine_frequency']}%")

    del prod_model, symptom_columns, feature_names
    gc.collect()

except Exception as e:
    print(f"  ERROR in low-info analysis: {e}")
    import traceback
    traceback.print_exc()
    low_info_results = {"error": str(e)}

# Save step3-8 intermediate results
step3_8 = {
    "tiers": tier_summary,
    "threshold_results": threshold_results,
    "separability_by_threshold": sep_results,
    "one_vs_rest_feasible_count": feasible_count,
    "low_information_input": low_info_results,
}
with open(BASE / "phase7f_intermediate_experiments.json", 'w') as f:
    json.dump(step3_8, f, indent=2, default=str)
print("\n  Saved phase7f_intermediate_experiments.json")
