"""Phase 7C -- STEP 2: Dataset Analysis (v2)

Analyzes backend/data/data.csv and writes a detailed report to
backend/ml/model/dataset_analysis_v2.json.

A normalization/standardization pass is NOT performed here: the analysis only
reports on the data as-is. Any cleaning happens in train.py (STEP 3).
"""

import json
import os
import sys

import numpy as np
import pandas as pd

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
DATA_RAW = os.path.join(DATA_DIR, "data.csv")
MODEL_DIR = os.path.join(BASE_DIR, "ml", "model")
REPORT_PATH = os.path.join(MODEL_DIR, "dataset_analysis_v2.json")


def main():
    os.makedirs(MODEL_DIR, exist_ok=True)

    if not os.path.exists(DATA_RAW):
        print(f"ERROR: New dataset not found at {DATA_RAW}")
        sys.exit(1)

    print(f"Loading dataset: {DATA_RAW}")
    df = pd.read_csv(DATA_RAW)
    print(f"  Loaded {df.shape[0]} rows x {df.shape[1]} columns\n")

    # ------------------------------------------------------------------
    # 1-2. Rows and columns
    # ------------------------------------------------------------------
    n_rows = int(df.shape[0])
    n_cols = int(df.shape[1])

    # ------------------------------------------------------------------
    # 3. Target column (assumed 'disease')
    # ------------------------------------------------------------------
    target_col = "disease"
    if target_col not in df.columns:
        print(f"ERROR: Expected target column '{target_col}' not found.")
        sys.exit(1)

    y = df[target_col]

    # ------------------------------------------------------------------
    # 4-5. Feature columns / unique diseases
    # ------------------------------------------------------------------
    feature_cols = [c for c in df.columns if c != target_col]
    n_features = len(feature_cols)
    diseases = y.dropna().unique()
    n_diseases = int(len(diseases))

    # ------------------------------------------------------------------
    # 6. Binary 0/1 check
    # ------------------------------------------------------------------
    valid_binary = {0, 1}
    feature_unique = {}
    for c in feature_cols:
        feature_unique[c] = sorted(df[c].dropna().unique().tolist())
    all_feature_vals = set()
    for vals in feature_unique.values():
        all_feature_vals.update(vals)
    is_binary = all_feature_vals.issubset(valid_binary)

    non_binary_cols = {}
    for c, vals in feature_unique.items():
        if not set(vals).issubset(valid_binary):
            non_binary_cols[c] = vals

    # ------------------------------------------------------------------
    # 7. Missing values (target + features)
    # ------------------------------------------------------------------
    total_missing = int(df.isnull().sum().sum())
    missing_by_col = {}
    for c in df.columns:
        m = int(df[c].isnull().sum())
        if m > 0:
            missing_by_col[c] = m
    target_missing = int(y.isnull().sum())

    # ------------------------------------------------------------------
    # 8. Duplicate rows
    # ------------------------------------------------------------------
    dup_rows = int(df.duplicated().sum())

    # ------------------------------------------------------------------
    # 9. Class distribution
    # ------------------------------------------------------------------
    vc = y.value_counts()
    class_distribution = {
        str(k): int(v) for k, v in vc.items()
    }

    # ------------------------------------------------------------------
    # 10-11. Rare diseases and min/max/median samples
    # ------------------------------------------------------------------
    sample_counts = vc.values
    rare_50 = {str(k): int(v) for k, v in vc.items() if v < 50}
    rare_10 = {str(k): int(v) for k, v in vc.items() if v < 10}
    singleton = {str(k): int(v) for k, v in vc.items() if v == 1}

    dist_stats = {
        "min_samples_per_disease": int(sample_counts.min()),
        "max_samples_per_disease": int(sample_counts.max()),
        "median_samples_per_disease": float(np.median(sample_counts)),
        "mean_samples_per_disease": float(sample_counts.mean()),
        "num_diseases_with_less_than_50": len(rare_50),
        "num_diseases_with_less_than_10": len(rare_10),
        "num_singleton_diseases": len(singleton),
    }

    # ------------------------------------------------------------------
    # 12. Unexpected symptom values (non-0/1)
    # ------------------------------------------------------------------
    # 13. Empty/null in disease names / symptom columns
    # ------------------------------------------------------------------
    empty_target = int((y.astype(str).str.strip() == "").sum())
    empty_feature = int(
        df[feature_cols]
        .astype(str)
        .apply(lambda col: col.str.strip() == "")
        .sum()
        .sum()
    )

    analysis = {
        "dataset_path": DATA_RAW.replace("\\", "/"),
        "source": os.path.basename(DATA_RAW),
        "rows": n_rows,
        "columns": n_cols,
        "target_column": target_col,
        "feature_columns_count": n_features,
        "feature_columns": feature_cols,
        "unique_diseases": n_diseases,
        "diseases": sorted([str(d) for d in diseases]),
        "symptom_values_binary_0_1": bool(is_binary),
        "unique_symptom_values": sorted(str(v) for v in all_feature_vals),
        "non_binary_columns": {k: v for k, v in non_binary_cols.items()},
        "missing_values": {
            "total": total_missing,
            "by_column": missing_by_col,
            "target_missing": target_missing,
        },
        "duplicate_rows": dup_rows,
        "class_distribution": class_distribution,
        "distribution_stats": dist_stats,
        "rare_diseases_lt_50": rare_50,
        "rare_diseases_lt_10": rare_10,
        "singleton_diseases": singleton,
        "empty_target_labels": int(empty_target),
        "empty_feature_values": int(empty_feature),
        "stratification_feasible":
            int((vc >= 2).sum()) == int(len(vc)),
        "classes_with_ge2_samples": int((vc >= 2).sum()),
    }

    with open(REPORT_PATH, "w") as f:
        json.dump(analysis, f, indent=2)

    # ------------------------------------------------------------------
    # Console summary
    # ------------------------------------------------------------------
    print("=" * 70)
    print("DATASET ANALYSIS (v2)")
    print("=" * 70)
    print(f"  Rows:                       {n_rows}")
    print(f"  Columns:                    {n_cols}")
    print(f"  Target column:              {target_col}")
    print(f"  Feature (symptom) columns:  {n_features}")
    print(f"  Unique diseases:            {n_diseases}")
    print(f"  Symptom values binary 0/1:  {is_binary}")
    print(f"  Missing values (total):     {total_missing}")
    print(f"  Duplicate rows:             {dup_rows}")
    print(f"  Min/median/max samples:     "
          f"{dist_stats['min_samples_per_disease']} / "
          f"{dist_stats['median_samples_per_disease']:.0f} / "
          f"{dist_stats['max_samples_per_disease']}")
    print(f"  Diseases < 50 samples:      {len(rare_50)}")
    print(f"  Diseases < 10 samples:      {len(rare_10)}")
    print(f"  Singleton diseases:         {len(singleton)}")
    print(f"  Classes with >=2 samples:   {analysis['classes_with_ge2_samples']}"
          f" / {n_diseases}")
    if empty_target:
        print("  NOTE: Empty disease label rows present.")
    if empty_feature:
        print("  NOTE: Empty symptom-cell rows present.")
    if not is_binary:
        print("  WARNING: Non-binary symptom values detected.")
    print()
    print(f"  Report saved -> {REPORT_PATH}")
    print()
    print("  NOTE: The model pipeline treats ALL non-target columns as binary")
    print("  symptom features. Values are int8-encoded for memory efficiency.")
    print()


if __name__ == "__main__":
    main()
