import json
import hashlib
import sys
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(r"C:\Users\ADMIN\OneDrive\Desktop\healthcareapp\backend\ml\phase7i")
SRC = Path(r"C:\Users\ADMIN\OneDrive\Desktop\healthcareapp\backend\ml\phase7h\cleaned\symbipredict_deduplicated.csv")

TARGET = "prognosis"
REMOVED = ["fluid_overload"]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    print("=" * 60)
    print("PHASE 7I STEP 1: PREPROCESSING")
    print("=" * 60)

    df = pd.read_csv(SRC)
    print(f"Loaded: {SRC.name} shape={df.shape}")

    report = {
        "source_dataset": str(SRC),
        "source_dataset_sha256": sha256_file(SRC),
        "rows_input": int(df.shape[0]),
        "columns_input": int(df.shape[1]),
        "target_column": TARGET,
        "features_input": int(df.shape[1]) - 1,
        "classes_input": int(df[TARGET].nunique()),
        "removed_features": REMOVED,
    }

    symptom_cols = [c for c in df.columns if c != TARGET]
    flu_hits = [c for c in REMOVED if c in symptom_cols]
    assert set(flu_hits) == set(REMOVED), f"expected to find {REMOVED} got {flu_hits}"

    X = df[symptom_cols].astype(np.float64)
    y = df[TARGET].astype(str)

    # binary / missing checks
    valid_binary = set([0.0, 1.0])
    binary_ok = all(set(X[c].unique()).issubset(valid_binary) for c in X.columns)
    missing = int(X.isna().sum().sum() + y.isna().sum())
    inf_count = int(np.isinf(X.to_numpy()).sum())
    nan_count = int(np.isnan(X.to_numpy()).sum())

    # duplicates in raw rows
    dup_rows = int(df.duplicated().sum())
    dup_vectors = int(X.duplicated().sum())

    # contingency contradictions: same vector -> >1 disease
    vector_key = X.astype(str).apply(lambda r: "|".join(r), axis=1)
    contradictions = 0
    g = pd.DataFrame({"key": vector_key, "y": y})
    vcount = g.groupby("key")["y"].nunique()
    contradictions = int((vcount > 1).sum())

    report.update(
        {
            "all_features_binary": bool(binary_ok),
            "missing_values": missing,
            "nan_values": nan_count,
            "inf_values": inf_count,
            "duplicate_rows": dup_rows,
            "duplicate_feature_vectors": dup_vectors,
            "contradictory_vectors": contradictions,
            "unique_feature_vectors": int(X.shape[0]) - int(X.duplicated().sum()),
        }
    )

    # constant features BEFORE removal (all percentage 0 or 1)
    const_info = {}
    for c in X.columns:
        if X[c].nunique() == 1:
            const_info[c] = {"unique_value": int(X[c].iloc[0]), "n_ones": int(X[c].sum())}
    report["constant_features_before_removal"] = const_info

    # remove approved feature
    Xr = X.drop(columns=REMOVED)
    report["features_after_removal"] = int(Xr.shape[1])
    report["rows_out"] = int(Xr.shape[0])
    report["fluid_overload_removed"] = True

    # constant features AFTER removal
    const_after = {}
    for c in Xr.columns:
        if Xr[c].nunique() == 1:
            const_after[c] = {"unique_value": int(Xr[c].iloc[0]), "n_ones": int(Xr[c].sum())}
    report["constant_features_after_removal"] = const_after

    # per-class support
    yc = y.value_counts().sort_index()
    report["classes_final"] = int(yc.shape[0])
    report["samples_per_class"] = {str(k): int(v) for k, v in yc.items()}
    report["min_support"] = int(yc.min())
    report["max_support"] = int(yc.max())

    # active symptoms per vector
    active = Xr.sum(axis=1)
    report["active_symptoms_per_vector"] = {
        "min": int(active.min()),
        "max": int(active.max()),
        "mean": float(round(active.mean(), 4)),
        "median": float(round(active.median(), 4)),
    }

    # class imbalance
    report["imbalance_ratio_max_over_min"] = round(float(yc.max()) / float(yc.min()), 4)

    # deterministic feature vocabulary
    features = Xr.columns.tolist()
    vocab = {
        "feature_count": len(features),
        "removed_features": REMOVED,
        "synonym_mappings_applied": False,
        "source_dataset": str(SRC),
        "source_dataset_sha256": report["source_dataset_sha256"],
        "vocabulary_note": "Exact column order from Representation C cleaned dataset after fluid_overload removal.",
        "features": features,
    }
    (ROOT / "data" / "symptom_columns_131.json").write_text(
        json.dumps(vocab, indent=2), encoding="utf-8"
    )
    vocab_hash = sha256_file(ROOT / "data" / "symptom_columns_131.json")
    report["vocabulary_file"] = str(ROOT / "data" / "symptom_columns_131.json")
    report["vocabulary_sha256"] = vocab_hash
    report["feature_order_deterministic"] = True

    # save preprocessed dataset
    out_df = pd.concat([Xr, y.to_frame(TARGET)], axis=1)
    out_path = ROOT / "data" / "symbipredict_representationC_131feat.csv"
    out_df.to_csv(out_path, index=False)
    report["processed_dataset_file"] = str(out_path)
    report["processed_dataset_sha256"] = sha256_file(out_path)

    val_path = ROOT / "validation" / "phase7i_preprocessing.json"
    val_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print(f"\nSaved: symptom_columns_131.json, symbipredict_representationC_131feat.csv, phase7i_preprocessing.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())