"""
Phase 7G Step 10/11 — Basic local inspection (READ-ONLY) of acquired SymbiPredict.
Determines rows, columns, target, class distribution, missing values, duplicates,
feature types, symptom columns. Compares against the CURRENT dataset structure.
NO model training, NO cleaning, NO transformation.
"""
import json, os
import pandas as pd
import numpy as np

BASE = Path = __import__('pathlib').Path(__file__).parent
ACQ = BASE / "acquired" / "symbipredict_2022.csv"
CURRENT = BASE.parent.parent / "data" / "disease_dataset_cleaned_v2.csv"

profile = {}

# ---- Acquired candidate ----
df = pd.read_csv(ACQ)
profile["filename"] = ACQ.name
profile["rows"] = int(len(df))
profile["columns"] = int(df.shape[1])
profile["column_names"] = [str(c) for c in df.columns]

# Target column is typically last (prognosis). Detect apparent target.
target_col = None
for c in df.columns:
    if str(c).lower() in ("prognosis", "disease", "label", "target", "class"):
        target_col = str(c)
profile["target_column"] = target_col

if target_col:
    vc = df[target_col].value_counts(dropna=False)
    profile["n_classes"] = int(vc.size)
    profile["class_counts"] = {str(k): int(v) for k, v in vc.items()}
    profile["min_class_size"] = int(vc.min())
    profile["max_class_size"] = int(vc.max())
    # imbalance ratio largest-to-smallest nonzero
    nz = vc[vc > 0]
    profile["imbalance_ratio"] = None if len(nz) < 2 else float(int(nz.max()) / int(nz.min()))
    profile["classes_below_10"] = int((vc < 10).sum())
    profile["classes_below_20"] = int((vc < 20).sum())
    profile["classes_below_50"] = int((vc < 50).sum())
    profile["classes_below_100"] = int((vc < 100).sum())

# Missing values
missing = df.isna().mean().mean() * 100
profile["missing_value_percent"] = float(missing)
profile["columns_with_any_missing"] = int((df.isna().any()).sum())

# Duplicates
profile["duplicate_rows"] = int(df.duplicated().sum())

# Feature types
dtypes = df.dtypes.astype(str).value_counts().to_dict()
profile["dtype_breakdown"] = {str(k): int(v) for k, v in dtypes.items()}

# Unique patterns (rows that are unique)
profile["unique_rows_percent"] = float(len(df.drop_duplicates()) / len(df) * 100) if len(df) else None

# Symptom-like columns count (non-target, non-identifier)
exclude = set()
if target_col:
    exclude.add(target_col)
for c in df.columns:
    if str(c).lower() in ("patientid", "patient_id", "id", "age", "gender", "sex"):
        exclude.add(str(c))
symptom_cols = [c for c in df.columns if c not in exclude]
profile["n_symptom_like_columns"] = len(symptom_cols)
profile["non_symptom_columns"] = [str(c) for c in df.columns if c in exclude]

# Value distribution of symptom columns (should be 0/1)
sub = df[symptom_cols]
vals = {str(k): int(v) for k, v in sub.stack().value_counts().to_dict().items()}
profile["symptom_value_distribution"] = vals

# min/max values per column
profile["min_value_all_cols"] = float(df[symptom_cols].min().min()) if len(symptom_cols) else None
profile["max_value_all_cols"] = float(df[symptom_cols].max().max()) if len(symptom_cols) else None

# ---- Current dataset (structure only, for comparison) ----
cur = pd.read_csv(CURRENT, nrows=5)
profile["current_dataset_columns"] = int(cur.shape[1])
cur_disease = pd.read_csv(CURRENT, usecols=lambda c: c == "disease") if "disease" in cur.columns else None
# read disease column counts quickly

# Save profile json
out_json = BASE / "acquired_dataset_profile.json"
with open(out_json, 'w', encoding='utf-8') as f:
    json.dump(profile, f, indent=2, default=str)

# Pretty console output
print("=" * 60)
print("ACQUIRED CANDIDATE PROFILE — SymbiPredict (SDPD)")
print("=" * 60)
for k in ["filename","rows","columns","target_column","n_classes","min_class_size",
          "max_class_size","imbalance_ratio","classes_below_10","classes_below_20",
          "classes_below_50","classes_below_100","missing_value_percent",
          "columns_with_any_missing","duplicate_rows","unique_rows_percent",
          "n_symptom_like_columns","min_value_all_cols","max_value_all_cols"]:
    print(f"  {k}: {profile.get(k)}")
print(f"  symptom_value_distribution: {profile.get('symptom_value_distribution')}")
print(f"  dtype_breakdown: {profile.get('dtype_breakdown')}")

print("\n  Top 10 class counts:")
for i, (k, v) in enumerate(list(profile.get("class_counts", {}).items())[:10]):
    print(f"    {k}: {v}")
print("=" * 60)
print("DONE — acquired_dataset_profile.json")
