"""
Phase 7H Steps 11, 13, 14 — Duplicate-representation decision, feature quality
validation (132 symptoms), and class validation (41 diseases).
No training, no production writes. Deterministic. Outputs:
  validation/feature_analysis.json
  validation/class_validation.json
  analysis/representations.json
"""
import json
from collections import Counter
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.feature_selection import mutual_info_classif

BASE = Path(__file__).resolve().parent.parent
CLEANED = BASE / "cleaned" / "symbipredict_cleaned.csv"
DEDUP = BASE / "cleaned" / "symbipredict_deduplicated.csv"
OUT_FEAT = BASE / "validation" / "feature_analysis.json"
OUT_CLS = BASE / "validation" / "class_validation.json"
OUT_REP = BASE / "analysis" / "representations.json"

TARGET = "prognosis"


def describe(X, y, name, full_df):
    vc = y.value_counts()
    return {
        "name": name,
        "rows": int(len(full_df)),
        "unique_vectors": int(X.drop_duplicates().shape[0]),
        "classes": int(vc.size),
        "class_min": int(vc.min()),
        "class_max": int(vc.max()),
        "class_mean": round(float(vc.mean()), 2),
        "imbalance_ratio": round(float(vc.max() / vc.min()), 4),
    }


def main() -> None:
    raw = pd.read_csv(CLEANED)
    ded = pd.read_csv(DEDUP)
    feat_cols = [c for c in raw.columns if c != TARGET]

    # ---------- Step 11: representations ----------
    X_raw, y_raw = raw[feat_cols], raw[TARGET]
    X_ded, y_ded = ded[feat_cols], ded[TARGET]

    rep_raw = describe(X_raw, y_raw, "A_original_4961", raw)
    rep_b = describe(raw[feat_cols], raw[TARGET], "B_exact_duplicates_removed", raw.drop_duplicates())
    rep_c = describe(ded[feat_cols], ded[TARGET], "C_unique_vector_disease_associations", ded)
    rep_d = describe(raw[feat_cols], raw[TARGET], "D_unique_vectors_multilabel", raw.drop_duplicates(subset=feat_cols))

    representations = {
        "A_original_4961": {
            **rep_raw,
            "interpretation": "Association rows repeated to uniform 121/class; rows are NOT independent patient samples.",
            "leakage_risk": "HIGH if row-split naively: identical vectors span train/test.",
            "independent_samples_valid": False,
            "suitability_ml": "Acceptable source for class-conditional statistics but misleading as i.i.d. samples.",
        },
        "B_exact_duplicates_removed": {
            **rep_b,
            "interpretation": "Row-level dedup; here equals unique vector+label pairs (no contradictions).",
            "leakage_risk": "Low if used as association table; still group-split by vector for evaluation.",
            "independent_samples_valid": False,
            "suitability_ml": "Deduplicates repeated formatting; preferred base.",
        },
        "C_unique_vector_disease_associations": {
            **rep_c,
            "interpretation": "One row per unique disease->symptom association (304 rows). Honest information-bearing set.",
            "leakage_risk": "None from duplicates; split must be stratified/grouped by vector.",
            "independent_samples_valid": True,
            "suitability_ml": "Recommended for Phase 7I training/evaluation.",
        },
        "D_unique_vectors_multilabel": {
            **rep_d,
            "interpretation": "Only if contradictions existed; here 0 contradictions so D == B == C structurally.",
            "leakage_risk": "Not applicable (no multilabel vectors).",
            "independent_samples_valid": True,
            "suitability_ml": "Not needed; documented for completeness.",
        },
    }

    with open(OUT_REP, "w", encoding="utf-8") as f:
        json.dump(representations, f, indent=2, default=str)

    # ---------- Step 13: feature quality (computed on 4961 raw rows) ----------
    feat = {}
    pos_counts = {c: int((raw[c] == 1).sum()) for c in feat_cols}
    zerovar = {c: (pos_counts[c] == 0 or pos_counts[c] == len(raw)) for c in feat_cols}
    # near-zero variance: prevalence < 5% or > 95%
    nz = {c: (pos_counts[c] / len(raw) < 0.05 or pos_counts[c] / len(raw) > 0.95) for c in feat_cols}
    mi_full = mutual_info_classif(raw[feat_cols].astype(float), y_raw, random_state=0)
    # classes containing symptom (using unique association table)
    cls_has = {c: int(ded.loc[ded[c] == 1, TARGET].nunique()) for c in feat_cols}

    for i, c in enumerate(feat_cols):
        feat[c] = {
            "prevalence": round(float(pos_counts[c] / len(raw)), 4),
            "n_positive_rows": pos_counts[c],
            "pct_positive": round(float(pos_counts[c] / len(raw) * 100), 4),
            "zero_variance": bool(zerovar[c]),
            "near_zero_variance": bool(nz[c]),
            "mi_with_target": round(float(mi_full[i]), 6),
            "classes_containing_symptom": cls_has[c],
        }
    with open(OUT_FEAT, "w", encoding="utf-8") as f:
        json.dump(feat, f, indent=2, default=str)

    const = [c for c in feat_cols if feat[c]["zero_variance"]]
    quite_rare = [c for c in feat_cols if feat[c]["pct_positive"] < 5]
    quite_common = [c for c in feat_cols if feat[c]["pct_positive"] > 95]

    # ---------- Step 14: class validation ----------
    classes = {}
    for d in sorted(y_raw.unique()):
        sub = raw[y_raw == d]
        sub_ded = ded[y_ded == d]
        active = sub[feat_cols].sum(axis=1)
        classes[d] = {
            "class_name": d,
            "sample_count": int(len(sub)),
            "unique_symptom_vectors": int(sub_ded.shape[0]),
            "duplicate_rows": int(len(sub) - len(sub_ded)),
            "unique_symptom_associations": int(sub_ded.shape[0]),
            "min_active_symptoms": int(active.min()),
            "max_active_symptoms": int(active.max()),
            "mean_active_symptoms": round(float(active.mean()), 3),
        }
    with open(OUT_CLS, "w", encoding="utf-8") as f:
        json.dump(classes, f, indent=2, default=str)

    print("=== REPRESENTATIONS ===")
    for name, r in representations.items():
        print(f"  {name}: rows={r['rows']} uniq_vec={r['unique_vectors']} classes={r['classes']}")
    print(f"=== FEATURES ===")
    print(f"  constant(null/zerovar): {len(const)} -> {const if const else 'none'}")
    print(f"  near-zero (pct<5 or >95): {len(quite_rare+quite_common)} ({len(quite_rare)} rare, {len(quite_common)} common)")
    print(f"  mean MI (full rows): {np.mean(mi_full):.6f}   MI>0.01: {(mi_full>0.01).sum()}/{len(mi_full)}")
    print(f"=== CLASSES ===")
    uniq_span = [v["unique_symptom_vectors"] for v in classes.values()]
    print(f"  41 classes; unique vectors/disease min={min(uniq_span)} max={max(uniq_span)}")
    print("DONE -> feature_analysis.json, class_validation.json, representations.json")


if __name__ == "__main__":
    main()