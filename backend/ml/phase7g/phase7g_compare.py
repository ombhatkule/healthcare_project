"""
Phase 7G Step 11 — Quality screen: compare CURRENT dataset vs ACQUIRED candidate.
Computes structural/statistical characterization metrics for both.
NO model training. NO cleaning/transformation.
"""
import json
import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.feature_selection import mutual_info_classif

BASE = Path(__file__).parent
CURRENT = BASE.parent.parent / "data" / "disease_dataset_cleaned_v2.csv"
ACQ = BASE / "acquired" / "symbipredict_2022.csv"

result = {}

# ---------------- CURRENT DATASET ----------------
print("=== CURRENT DATASET ===")
cur = pd.read_csv(CURRENT)
# disease is FIRST column (verified in Phase 7F)
disease_col = cur.columns[0]
X_cur = cur.drop(columns=[disease_col])
y_cur = cur[disease_col]
vc = y_cur.value_counts()
cur_stats = {
    "rows": int(len(cur)),
    "columns": int(cur.shape[1]),
    "n_classes": int(vc.size),
    "min_class_size": int(vc.min()),
    "max_class_size": int(vc.max()),
    "imbalance_ratio": float(int(vc.max()) / int(vc.min())),
    "classes_below_10": int((vc < 10).sum()),
    "classes_below_20": int((vc < 20).sum()),
    "classes_below_50": int((vc < 50).sum()),
    "classes_below_100": int((vc < 100).sum()),
    "missing_value_percent": float(cur.isna().mean().mean() * 100),
    "duplicate_rows": int(cur.duplicated().sum()),
    "unique_rows_percent": float(len(cur.drop_duplicates()) / len(cur) * 100),
    "n_symptom_features": int(X_cur.shape[1]),
}
result["current"] = cur_stats
for k, v in cur_stats.items():
    print(f"  {k}: {v}")

# ---------------- ACQUIRED CANDIDATE ----------------
print("\n=== ACQUIRED CANDIDATE (SymbiPredict) ===")
df = pd.read_csv(ACQ)
target_col = "prognosis"
X = df.drop(columns=[target_col])
y = df[target_col]
vc2 = y.value_counts()
cand_stats = {
    "rows": int(len(df)),
    "columns": int(df.shape[1]),
    "n_classes": int(vc2.size),
    "min_class_size": int(vc2.min()),
    "max_class_size": int(vc2.max()),
    "imbalance_ratio": float(int(vc2.max()) / int(vc2.min())),
    "classes_below_10": int((vc2 < 10).sum()),
    "classes_below_20": int((vc2 < 20).sum()),
    "classes_below_50": int((vc2 < 50).sum()),
    "classes_below_100": int((vc2 < 100).sum()),
    "missing_value_percent": float(df.isna().mean().mean() * 100),
    "duplicate_rows": int(df.duplicated().sum()),
    "unique_rows_percent": float(len(df.drop_duplicates()) / len(df) * 100),
    "n_symptom_features": int(X.shape[1]),
}
result["candidate"] = cand_stats
for k, v in cand_stats.items():
    print(f"  {k}: {v}")

# ---------------- Separability (avg pairwise cosine similarity of class profiles) ----
print("\n=== Separability (avg pairwise cosine similarity of disease symptom profiles) ===")

def avg_class_similarity(X, y):
    classes = y.unique()
    profs = []
    for c in classes:
        profs.append(X[y == c].mean(axis=0).values.astype(float))
    profs = np.array(profs)
    norms = np.linalg.norm(profs, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    n = profs / norms
    sim = n @ n.T
    iu = np.triu_indices(len(classes), k=1)
    return float(sim[iu].mean()), int(len(classes))

# Current separability (from Phase 7E = 0.694). Recompute for consistency (quick).
# Use reduced numeric set for speed.
sim_cur, nc_cur = avg_class_similarity(X_cur.astype(float), y_cur)
sim_cand, nc_cand = avg_class_similarity(X.astype(float), y)
result["current_separability_avg_cosine"] = sim_cur
result["candidate_separability_avg_cosine"] = sim_cand
result["current_n_classes_sep"] = nc_cur
result["candidate_n_classes_sep"] = nc_cand
print(f"  CURRENT avg cosine (46-class): {sim_cur:.4f}")
print(f"  CANDIDATE avg cosine (41-class): {sim_cand:.4f}")

# ---------------- Feature discrimination (mean mutual information) ----
print("\n=== Feature discrimination (mean mutual information) ===")
# Sample for speed on current if large
mi_cur = mutual_info_classif(X_cur.astype(float).iloc[:20000], y_cur.iloc[:20000], random_state=0)
mi_cand = mutual_info_classif(X.astype(float), y, random_state=0)
result["current_mean_mi"] = float(mi_cur.mean())
result["candidate_mean_mi"] = float(mi_cand.mean())
result["current_mi_gt_0p01"] = int((mi_cur > 0.01).sum())
result["candidate_mi_gt_0p01"] = int((mi_cand > 0.01).sum())
print(f"  CURRENT mean MI: {mi_cur.mean():.4f}  (>0.01: {(mi_cur>0.01).sum()}/{len(mi_cur)})")
print(f"  CANDIDATE mean MI: {mi_cand.mean():.4f}  (>0.01: {(mi_cand>0.01).sum()}/{len(mi_cand)})")

with open(BASE / "current_vs_candidate_data.json", 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, default=str)
print("\nDONE — current_vs_candidate_data.json")
