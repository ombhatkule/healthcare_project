"""
Phase 7H Step 4 — Raw SymbiPredict inspection (READ-ONLY).
Determines shape, dtypes, binary-ness, missing/NaN/inf, duplicates, class counts,
active-symptom stats, invalid values. Never modifies the raw file.
Deterministic. Output: validation/raw_profile.json
"""
import json
import math
from pathlib import Path

import numpy as np
import pandas as pd

BASE = Path(__file__).resolve().parent.parent
RAW = BASE / "raw_reference" / "symbipredict_2022.csv"
OUT = BASE / "validation" / "raw_profile.json"

SRC = BASE.parent / "phase7g" / "acquired" / "symbipredict_2022.csv"


def main() -> None:
    df = pd.read_csv(SRC)
    assert len(df) == 4961 and df.shape[1] == 133, f"Unexpected shape {df.shape}"
    feat_cols = [c for c in df.columns if c != "prognosis"]
    X = df[feat_cols]
    y = df["prognosis"]

    # ---- feature uniqueness / binaryness ----
    nunique = X.nunique(dropna=True)
    value_sets = {c: sorted(v for v in X[c].dropna().unique().tolist()) for c in feat_cols}

    invalid_feature_values = {}
    for c in feat_cols:
        bad = [v for v in X[c].dropna().unique().tolist() if v not in (0, 1)]
        if bad:
            invalid_feature_values[c] = bad

    # ---- missing / inf ----
    nan_cells = int(df[feat_cols].isna().sum().sum())
    target_nan = int(y.isna().sum())
    inf_detect = df[feat_cols].isin([np.inf, -np.inf])
    inf_cells = int(inf_detect.sum().sum())

    # ---- duplicates ----
    full_dups = int(df.duplicated().sum())
    vec_dups = int(X.duplicated().sum())
    unique_vectors = int(X.drop_duplicates().shape[0])
    unique_vector_label = int(df.drop_duplicates().shape[0])

    # ---- active symptoms per row ----
    active = X.sum(axis=1)
    active_stats = {
        "min": int(active.min()),
        "max": int(active.max()),
        "mean": round(float(active.mean()), 4),
        "median": float(active.median()),
    }

    class_counts = {str(k): int(v) for k, v in y.value_counts().items()}

    profile = {
        "source": str(SRC),
        "source_sha256_expected": "9834c90dd48eb2fef1fa56282f8f016a6781b0e4ada878015dc34a81af8e9e1b",
        "rows": int(len(df)),
        "columns_total": int(df.shape[1]),
        "feature_columns": int(len(feat_cols)),
        "target_column": "prognosis",
        "target_dtype": str(y.dtype),
        "feature_dtype": str(X.dtypes.iloc[0]),
        "all_features_binary": len(invalid_feature_values) == 0,
        "missing_cells_features": nan_cells,
        "missing_cells_target": target_nan,
        "inf_cells": inf_cells,
        "rows_with_inf": int(inf_detect.any(axis=1).sum()),
        "duplicate_rows_exact": full_dups,
        "duplicate_vectors_when_ignoring_label": vec_dups,
        "unique_symptom_vectors": unique_vectors,
        "unique_vector_label_pairs": unique_vector_label,
        "unique_labels": int(y.nunique()),
        "class_counts": class_counts,
        "class_min": int(y.value_counts().min()),
        "class_max": int(y.value_counts().max()),
        "active_symptoms_per_row": active_stats,
        "all_zero_rows": int((X.sum(axis=1) == 0).sum()),
        "all_one_rows": int((X.sum(axis=1) == len(feat_cols)).sum()),
        "nunique_per_feature_min": int(nunique.min()),
        "nunique_per_feature_max": int(nunique.max()),
        "invalid_feature_values": invalid_feature_values,
        "column_names": list(df.columns),
    }

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(profile, f, indent=2, default=str)

    print("=== RAW SYMBIPREDICT PROFILE ===")
    for k in ["rows", "feature_columns", "unique_labels", "unique_symptom_vectors",
              "unique_vector_label_pairs", "duplicate_rows_exact", "class_min", "class_max",
              "missing_cells_features", "inf_cells", "all_features_binary", "all_zero_rows"]:
        print(f"  {k}: {profile.get(k)}")
    print(f"  active_symptoms_per_row: {active_stats}")
    print(f"  invalid_feature_values: {invalid_feature_values if invalid_feature_values else 'NONE'}")
    print("DONE -> validation/raw_profile.json")


if __name__ == "__main__":
    main()