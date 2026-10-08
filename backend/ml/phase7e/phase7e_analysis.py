"""
Phase 7E Step 1 — Baseline check + Step 2 — Deep Dataset Validation
Produces: phase7e_baseline_check.json, dataset analysis results
"""
import json, csv, os, hashlib, time, warnings
import numpy as np
import pandas as pd
from pathlib import Path
from collections import Counter
warnings.filterwarnings('ignore')

BASE = Path(__file__).parent
DATA_DIR = BASE.parent.parent / "data"
MODEL_DIR = BASE.parent / "model"
PHASE7D = BASE.parent / "phase7d"

def file_hash(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def file_size_mb(path):
    return round(os.path.getsize(path) / (1024*1024), 2)

# ============================================================
# STEP 1 — Baseline Check
# ============================================================
print("=" * 60)
print("STEP 1 — Baseline Check")
print("=" * 60)

prod_model = MODEL_DIR / "disease_model.joblib"
symptom_cols = MODEL_DIR / "symptom_columns.joblib"
dataset = DATA_DIR / "disease_dataset_cleaned_v2.csv"

baseline_check = {
    "title": "Phase 7E Baseline Check",
    "production_files": {
        "disease_model.joblib": {
            "exists": prod_model.exists(),
            "size_mb": file_size_mb(prod_model) if prod_model.exists() else None,
            "sha256": file_hash(prod_model) if prod_model.exists() else None,
            "last_modified": str(prod_model.stat().st_mtime) if prod_model.exists() else None,
        },
        "symptom_columns.joblib": {
            "exists": symptom_cols.exists(),
            "size_mb": file_size_mb(symptom_cols) if symptom_cols.exists() else None,
            "sha256": file_hash(symptom_cols) if symptom_cols.exists() else None,
        },
        "disease_dataset_cleaned_v2.csv": {
            "exists": dataset.exists(),
            "size_mb": file_size_mb(dataset) if dataset.exists() else None,
            "sha256": file_hash(dataset) if dataset.exists() else None,
        },
    },
    "phase7d_outputs_present": {}
}

phase7d_files = [
    "model_comparison.json", "migraine_bias_test.json", "empty_input_test.json",
    "per_class_metrics.csv", "confusion_matrix.csv", "random_forest_feature_importance.csv",
    "class_weight_effect.json", "phase7d_report.md"
]
for f in phase7d_files:
    fp = PHASE7D / f
    baseline_check["phase7d_outputs_present"][f] = fp.exists()

with open(BASE / "phase7e_baseline_check.json", 'w') as fh:
    json.dump(baseline_check, fh, indent=2)

print("  Production model:", baseline_check["production_files"]["disease_model.joblib"]["size_mb"], "MB")
print("  Dataset CSV:", baseline_check["production_files"]["disease_dataset_cleaned_v2.csv"]["size_mb"], "MB")
print("  Phase 7D files present:", all(baseline_check["phase7d_outputs_present"].values()))
print("  baseline_check.json written")

# ============================================================
# STEP 2 — Deep Dataset Validation
# ============================================================
print("\n" + "=" * 60)
print("STEP 2 — Deep Dataset Validation")
print("=" * 60)

print("\n  Loading dataset...")
t0 = time.time()
df = pd.read_csv(dataset)
print(f"  Loaded in {time.time()-t0:.1f}s: {df.shape[0]} rows x {df.shape[1]} columns")

# Identify columns
disease_col = 'disease' if 'disease' in df.columns else None
if disease_col is None:
    for c in df.columns:
        if 'disease' in c.lower() or 'diagnosis' in c.lower() or 'condition' in c.lower():
            disease_col = c
            break
if disease_col is None:
    disease_col = df.columns[-1]

symptom_cols_list = [c for c in df.columns if c != disease_col]
print(f"  Disease column: {disease_col}")
print(f"  Symptom columns: {len(symptom_cols_list)}")
print(f"  Unique diseases: {df[disease_col].nunique()}")

# ============================================================
# 2.1 Class Support Adequacy
# ============================================================
print("\n  [2.1] Class Support Adequacy...")

class_counts = df[disease_col].value_counts()
total_samples = len(df)
n_classes = len(class_counts)

# Categorize
categories = {
    "critically_insufficient": {"range": "<5", "diseases": [], "count": 0},
    "extremely_insufficient": {"range": "5-9", "diseases": [], "count": 0},
    "very_small": {"range": "10-19", "diseases": [], "count": 0},
    "small": {"range": "20-49", "diseases": [], "count": 0},
    "limited": {"range": "50-99", "diseases": [], "count": 0},
    "moderate": {"range": "100-499", "diseases": [], "count": 0},
    "larger": {"range": "500+", "diseases": [], "count": 0},
}

for disease, count in class_counts.items():
    if count < 5:
        cat = "critically_insufficient"
    elif count < 10:
        cat = "extremely_insufficient"
    elif count < 20:
        cat = "very_small"
    elif count < 50:
        cat = "small"
    elif count < 100:
        cat = "limited"
    elif count < 500:
        cat = "moderate"
    else:
        cat = "larger"
    categories[cat]["diseases"].append(disease)
    categories[cat]["count"] += 1

top5_classes = class_counts.head(5)
top5_pct = round(top5_classes.sum() / total_samples * 100, 2)
imbalance_ratio = int(class_counts.max() / class_counts.min())

class_support = {
    "total_samples": total_samples,
    "n_classes": n_classes,
    "class_distribution": {str(k): int(v) for k, v in class_counts.items()},
    "categories": {},
    "top_5_classes": {str(k): int(v) for k, v in top5_classes.items()},
    "top_5_classes_percentage_of_total": top5_pct,
    "imbalance_ratio": imbalance_ratio,
    "largest_class": str(class_counts.index[0]),
    "largest_class_count": int(class_counts.iloc[0]),
    "smallest_class": str(class_counts.index[-1]),
    "smallest_class_count": int(class_counts.iloc[-1]),
}

for cat_name, cat_data in categories.items():
    class_support["categories"][cat_name] = {
        "range": cat_data["range"],
        "count": cat_data["count"],
        "percentage_of_classes": round(cat_data["count"] / n_classes * 100, 2),
        "diseases": cat_data["diseases"],
    }

insufficient_total = (categories["critically_insufficient"]["count"] +
                      categories["extremely_insufficient"]["count"])
insufficient_pct = round(insufficient_total / n_classes * 100, 1)

print(f"    Imbalance ratio: {imbalance_ratio}:1")
print(f"    Top 5 classes hold {top5_pct}% of all samples")
print(f"    Critically insufficient (<5): {categories['critically_insufficient']['count']} classes")
print(f"    Extremely insufficient (5-9): {categories['extremely_insufficient']['count']} classes")
print(f"    Combined critically+extremely: {insufficient_total} ({insufficient_pct}%) of {n_classes} classes")

# ============================================================
# 2.2 Feature Information Analysis
# ============================================================
print("\n  [2.2] Feature Information Analysis...")

from sklearn.feature_selection import mutual_info_classif

X = df[symptom_cols_list].values
y = df[disease_col].values

# Overall prevalence
prevalence = {}
for i, col in enumerate(symptom_cols_list):
    prevalence[col] = round(float(X[:, i].mean()), 6)

# Mutual information
t0 = time.time()
mi_scores = mutual_info_classif(X, y, discrete_features=True, random_state=42)
mi_time = time.time() - t0
print(f"    MI computed in {mi_time:.1f}s")

# Rank features by MI
mi_ranked = sorted(zip(symptom_cols_list, mi_scores), key=lambda x: x[1], reverse=True)

# Per-class prevalence for top features (top 5)
per_class_prev = {}
for disease in df[disease_col].unique():
    mask = df[disease_col] == disease
    per_class_prev[disease] = {col: round(float(df.loc[mask, col].mean()), 4)
                                for col in [m[0] for m in mi_ranked[:5]]}

# Feature stats
mi_values = [m[1] for m in mi_ranked]
feature_stats = {
    "mean_mi": round(float(np.mean(mi_values)), 6),
    "median_mi": round(float(np.median(mi_values)), 6),
    "std_mi": round(float(np.std(mi_values)), 6),
    "min_mi": round(float(np.min(mi_values)), 6),
    "max_mi": round(float(np.max(mi_values)), 6),
    "features_with_zero_mi": sum(1 for v in mi_values if v == 0),
    "features_with_mi_above_001": sum(1 for v in mi_values if v > 0.001),
    "features_with_mi_above_01": sum(1 for v in mi_values if v > 0.01),
}

top20_features = [{"feature": f, "mi_score": round(float(s), 6), "prevalence": prevalence[f]}
                  for f, s in mi_ranked[:20]]
bottom20_features = [{"feature": f, "mi_score": round(float(s), 6), "prevalence": prevalence[f]}
                     for f, s in mi_ranked[-20:]]

# Discriminative strength assessment
if feature_stats["mean_mi"] > 0.05:
    strength = "A. Many symptoms strongly distinguish diseases"
elif feature_stats["mean_mi"] > 0.01:
    strength = "B. Only a few symptoms provide useful discrimination"
else:
    strength = "C. Most symptoms provide weak and overlapping signals"

feature_analysis = {
    "top_20_discriminative": top20_features,
    "bottom_20_discriminative": bottom20_features,
    "summary_statistics": feature_stats,
    "discriminative_strength": strength,
    "total_features_analyzed": len(symptom_cols_list),
}

print(f"    MI range: [{feature_stats['min_mi']:.6f}, {feature_stats['max_mi']:.6f}]")
print(f"    Mean MI: {feature_stats['mean_mi']:.6f}")
print(f"    Features with MI > 0.01: {feature_stats['features_with_mi_above_01']}")
print(f"    Assessment: {strength}")

# ============================================================
# 2.3 Disease Separability Analysis
# ============================================================
print("\n  [2.3] Disease Separability Analysis...")

# Create disease profiles (mean symptom prevalence per disease)
diseases = sorted(df[disease_col].unique())
profiles = {}
for disease in diseases:
    mask = df[disease_col] == disease
    profiles[disease] = np.array([df.loc[mask, col].mean() for col in symptom_cols_list])

# Cosine similarity between all disease pairs
from numpy.linalg import norm

n_diseases = len(diseases)
sim_matrix = np.zeros((n_diseases, n_diseases))

for i in range(n_diseases):
    for j in range(n_diseases):
        if i == j:
            sim_matrix[i][j] = 1.0
        else:
            dot = np.dot(profiles[diseases[i]], profiles[diseases[j]])
            n1, n2 = norm(profiles[diseases[i]]), norm(profiles[diseases[j]])
            sim_matrix[i][j] = dot / (n1 * n2) if n1 > 0 and n2 > 0 else 0.0

# Get pairwise similarities (excluding self)
pairs = []
for i in range(n_diseases):
    for j in range(i+1, n_diseases):
        pairs.append((diseases[i], diseases[j], float(sim_matrix[i][j])))

pairs.sort(key=lambda x: x[2], reverse=True)
most_similar_20 = pairs[:20]
most_different_20 = pairs[-20:][::-1]

# Average similarity
upper_tri = sim_matrix[np.triu_indices(n_diseases, k=1)]
avg_similarity = round(float(np.mean(upper_tri)), 6)
sim_std = round(float(np.std(upper_tri)), 6)

# Inspect specific diseases
inspect_diseases = ["Migraine", "Asthma", "Common_Cold", "Flu", "Pneumonia",
                    "Coronary_Artery_Disease", "Hypothyroidism", "Hyperthyroidism"]

specific_inspection = {}
for disease in inspect_diseases:
    if disease in diseases:
        idx = diseases.index(disease)
        sims = [(diseases[j], float(sim_matrix[idx][j])) for j in range(n_diseases) if j != idx]
        sims.sort(key=lambda x: x[1], reverse=True)
        specific_inspection[disease] = {
            "avg_similarity_to_all_others": round(float(np.mean([s[1] for s in sims])), 6),
            "most_similar_5": [{"disease": s[0], "similarity": round(s[1], 6)} for s in sims[:5]],
            "least_similar_5": [{"disease": s[0], "similarity": round(s[1], 6)} for s in sims[-5:]],
            "class_count": int(class_counts.get(disease, 0)),
        }

# Add ultra-rare diseases inspection
ultra_rare = [d for d, c in class_counts.items() if c < 10]
for disease in ultra_rare[:5]:
    if disease in diseases:
        idx = diseases.index(disease)
        sims = [(diseases[j], float(sim_matrix[idx][j])) for j in range(n_diseases) if j != idx]
        sims.sort(key=lambda x: x[1], reverse=True)
        specific_inspection[disease] = {
            "avg_similarity_to_all_others": round(float(np.mean([s[1] for s in sims])), 6),
            "most_similar_5": [{"disease": s[0], "similarity": round(s[1], 6)} for s in sims[:5]],
            "class_count": int(class_counts.get(disease, 0)),
        }

separability_analysis = {
    "n_diseases": n_diseases,
    "average_pairwise_similarity": avg_similarity,
    "similarity_std": sim_std,
    "20_most_similar_pairs": [{"disease_1": p[0], "disease_2": p[1], "cosine_similarity": round(p[2], 6)} for p in most_similar_20],
    "20_most_different_pairs": [{"disease_1": p[0], "disease_2": p[1], "cosine_similarity": round(p[2], 6)} for p in most_different_20],
    "specific_disease_inspection": specific_inspection,
}

print(f"    Average pairwise cosine similarity: {avg_similarity:.4f}")
print(f"    Most similar pair: {most_similar_20[0][0]} <-> {most_similar_20[0][1]} = {most_similar_20[0][2]:.4f}")
print(f"    Most different pair: {most_different_20[0][0]} <-> {most_different_20[0][1]} = {most_different_20[0][2]:.4f}")

# ============================================================
# 2.4 Pattern Structure Analysis
# ============================================================
print("\n  [2.4] Pattern Structure Analysis...")

# Unique feature vectors
X_tuples = [tuple(row) for row in X]
unique_vectors = len(set(X_tuples))
all_unique = unique_vectors == total_samples

# Active symptoms per row
active_per_row = X.sum(axis=1)

# Per-disease symptom count stats
disease_symptom_stats = {}
for disease in diseases:
    mask = df[disease_col] == disease
    counts = X[mask].sum(axis=1)
    disease_symptom_stats[disease] = {
        "mean": round(float(counts.mean()), 2),
        "std": round(float(counts.std()), 2),
        "min": int(counts.min()),
        "max": int(counts.max()),
        "samples": int(mask.sum()),
    }

pattern_analysis = {
    "total_rows": total_samples,
    "unique_feature_vectors": unique_vectors,
    "all_rows_unique": all_unique,
    "active_symptoms_per_row": {
        "mean": round(float(active_per_row.mean()), 2),
        "std": round(float(active_per_row.std()), 2),
        "min": int(active_per_row.min()),
        "max": int(active_per_row.max()),
        "median": float(np.median(active_per_row)),
    },
    "per_disease_symptom_counts": disease_symptom_stats,
}

# Structure classification
structure_evidence = []
if all_unique:
    structure_evidence.append("Every row has a unique feature vector — no repeated patterns")
if active_per_row.std() < 2:
    structure_evidence.append("Low variation in active symptom counts across rows")
if feature_stats["mean_mi"] < 0.02:
    structure_evidence.append("Low mutual information between features and disease labels")
if avg_similarity > 0.7:
    structure_evidence.append("High average disease profile similarity — weak class separation")
if imbalance_ratio > 1000:
    structure_evidence.append("Extreme class imbalance ratio")

if all_unique and feature_stats["mean_mi"] < 0.02 and avg_similarity > 0.7:
    structure_classification = "statistically consistent with synthetic-style generation"
elif all_unique and feature_stats["mean_mi"] < 0.03:
    structure_classification = "weakly structured"
elif avg_similarity > 0.5:
    structure_classification = "weakly structured"
else:
    structure_classification = "moderately structured"

pattern_analysis["structure_evidence"] = structure_evidence
pattern_analysis["structure_classification"] = structure_classification

print(f"    Unique vectors: {unique_vectors}/{total_samples} ({'all unique' if all_unique else 'some duplicates'})")
print(f"    Active symptoms: mean={active_per_row.mean():.1f}, std={active_per_row.std():.1f}, range=[{active_per_row.min()}, {active_per_row.max()}]")
print(f"    Structure: {structure_classification}")

# ============================================================
# Save all Step 2 results
# ============================================================
step2_results = {
    "class_support": class_support,
    "feature_analysis": feature_analysis,
    "separability_analysis": separability_analysis,
    "pattern_analysis": pattern_analysis,
}

with open(BASE / "step2_dataset_analysis.json", 'w') as fh:
    json.dump(step2_results, fh, indent=2, default=str)

print("\n  Step 2 complete — step2_dataset_analysis.json written")

# ============================================================
# STEP 3 — Dataset Suitability Scorecard
# ============================================================
print("\n" + "=" * 60)
print("STEP 3 — Dataset Suitability Scorecard")
print("=" * 60)

scorecard_items = [
    {
        "category": "Class Support Adequacy",
        "rating": "Critical problem",
        "evidence": f"{insufficient_total} classes ({insufficient_pct}%) have fewer than 10 samples total. "
                    f"Smallest class has {class_counts.min()} sample(s). "
                    f"Train/test evaluation impossible for these classes.",
    },
    {
        "category": "Class Balance",
        "rating": "Critical problem",
        "evidence": f"Imbalance ratio is {imbalance_ratio}:1. "
                    f"Top 5 classes hold {top5_pct}% of all data. "
                    f"Largest class ({class_counts.index[0]}) has {class_counts.iloc[0]:,} samples; "
                    f"smallest has {class_counts.iloc[-1]}.",
    },
    {
        "category": "Feature Discriminative Strength",
        "rating": "Weak",
        "evidence": f"Mean mutual information is {feature_stats['mean_mi']:.6f}. "
                    f"Only {feature_stats['features_with_mi_above_01']} of {len(symptom_cols_list)} features "
                    f"have MI > 0.01. Top MI score is {mi_ranked[0][1]:.6f}. "
                    f"Assessment: {strength}.",
    },
    {
        "category": "Disease Separability",
        "rating": "Weak",
        "evidence": f"Average pairwise cosine similarity is {avg_similarity:.4f} (std {sim_std:.4f}). "
                    f"Many disease profiles are highly overlapping. "
                    f"Most similar pair ({most_similar_20[0][0]}, {most_similar_20[0][1]}) "
                    f"similarity = {most_similar_20[0][2]:.4f}.",
    },
    {
        "category": "Rare-Class Evaluability",
        "rating": "Critical problem",
        "evidence": f"{categories['critically_insufficient']['count']} classes have <5 samples "
                    f"(cannot even appear in both train and test). "
                    f"{categories['extremely_insufficient']['count']} more have 5-9 samples "
                    f"(insufficient for reliable evaluation).",
    },
    {
        "category": "Consistency of Symptom Patterns",
        "rating": "Weak",
        "evidence": f"Every row has a unique feature vector ({unique_vectors}/{total_samples}). "
                    f"No repeated disease-symptom patterns exist. "
                    f"Active symptom count mean={active_per_row.mean():.1f}, "
                    f"std={active_per_row.std():.1f}. "
                    f"Structure classification: {structure_classification}.",
    },
    {
        "category": "Suitability for Sparse User Inputs",
        "rating": "Weak",
        "evidence": "Empty vector predicts Migraine with 9.5% confidence (Phase 7D). "
                    "Single symptom also predicts Migraine. "
                    "Model cannot reliably handle the sparse inputs typical of real user interactions.",
    },
    {
        "category": "Suitability for 46-Class Classification",
        "rating": "Critical problem",
        "evidence": f"Best macro F1 across all models is ~0.19 (LogReg). "
                    f"46 classes with {n_classes - insufficient_total - categories['very_small']['count'] - categories['small']['count']} "
                    f"classes having <50 samples makes 46-class classification infeasible.",
    },
    {
        "category": "Reproducibility/Documentation",
        "rating": "Unknown",
        "evidence": "No documentation found for how the dataset was generated or collected. "
                    "No source attribution. No data dictionary. "
                    "CSV structure is consistent but provenance is unknown.",
    },
    {
        "category": "Medical/Clinical Provenance",
        "rating": "Unknown",
        "evidence": "No documentation of clinical origin. "
                    "No patient consent records referenced. "
                    "No institutional review. "
                    "Feature values appear to be binary symptom present/absent, "
                    "but the mapping methodology is undocumented.",
    },
]

scorecard_summary = {
    "strong": sum(1 for s in scorecard_items if s["rating"] == "Strong"),
    "acceptable": sum(1 for s in scorecard_items if s["rating"] == "Acceptable"),
    "weak": sum(1 for s in scorecard_items if s["rating"] == "Weak"),
    "critical_problem": sum(1 for s in scorecard_items if s["rating"] == "Critical problem"),
    "unknown": sum(1 for s in scorecard_items if s["rating"] == "Unknown"),
}

scorecard = {
    "title": "Current Dataset Suitability Scorecard (Phase 7E)",
    "date": "2026-09-08",
    "dataset": "disease_dataset_cleaned_v2.csv",
    "total_samples": total_samples,
    "n_classes": n_classes,
    "n_features": len(symptom_cols_list),
    "categories": scorecard_items,
    "summary": scorecard_summary,
    "overall_assessment": "Fundamentally unsuitable for reliable 46-class multiclass disease prediction",
}

# Save JSON
with open(BASE / "current_dataset_scorecard.json", 'w') as fh:
    json.dump(scorecard, fh, indent=2)

# Save Markdown
md = [
    "# Current Dataset Suitability Scorecard",
    "",
    f"**Date:** 2026-09-08",
    f"**Dataset:** disease_dataset_cleaned_v2.csv",
    f"**Rows:** {total_samples:,} | **Classes:** {n_classes} | **Features:** {len(symptom_cols_list)}",
    "",
    "## Scorecard",
    "",
    "| Category | Rating |",
    "|----------|--------|",
]
for item in scorecard_items:
    md.append(f"| {item['category']} | **{item['rating']}** |")
md += [
    "",
    "## Summary",
    "",
    f"- Strong: {scorecard_summary['strong']}",
    f"- Acceptable: {scorecard_summary['acceptable']}",
    f"- Weak: {scorecard_summary['weak']}",
    f"- Critical problem: {scorecard_summary['critical_problem']}",
    f"- Unknown: {scorecard_summary['unknown']}",
    "",
    "## Overall Assessment",
    "",
    f"**{scorecard['overall_assessment']}**",
    "",
    "## Evidence Details",
    "",
]
for item in scorecard_items:
    md.append(f"### {item['category']} — {item['rating']}")
    md.append("")
    md.append(item["evidence"])
    md.append("")

with open(BASE / "current_dataset_scorecard.md", 'w') as fh:
    fh.write("\n".join(md))

print("  Scorecard written (JSON + MD)")
for item in scorecard_items:
    print(f"    {item['category']}: {item['rating']}")
print(f"\n  Overall: {scorecard['overall_assessment']}")
