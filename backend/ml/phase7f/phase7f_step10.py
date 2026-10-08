"""
Phase 7F — Step 10: Experimental Model Design Comparison
Trains a consistent RandomForest (in-memory only) on full vs reduced-class problems.
Also Steps 4 & 6 (reduced-class viability + hierarchical feasibility).
"""
import json, os, time, warnings, gc
import numpy as np
import pandas as pd
from pathlib import Path
from collections import Counter
warnings.filterwarnings('ignore')

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import (accuracy_score, precision_recall_fscore_support,
                             balanced_accuracy_score)

BASE = Path(__file__).parent
DATA_DIR = BASE.parent.parent / "data"

print("=" * 60)
print("STEP 10 — Experimental Model Design Comparison")
print("=" * 60)

df = pd.read_csv(DATA_DIR / "disease_dataset_cleaned_v2.csv")
disease_col = 'disease' if 'disease' in df.columns else df.columns[0]
symptom_cols = [c for c in df.columns if c != disease_col]
y_all = df[disease_col].values
X_all = df[symptom_cols].values
counts = Counter(y_all)

# Fixed split (random_state=42). Full 46-class problem cannot stratify because
# some classes have < 2 samples, so use a plain random split (no stratify) for
# the full problem; reduced problems filter train/test consistently by class.
X_train_full, X_test_full, y_train_full, y_test_full = train_test_split(
    X_all, y_all, test_size=0.2, random_state=42
)
print(f"  Full split (non-stratified): train {len(X_train_full)}, test {len(X_test_full)}")

# Define problem formulations
thresholds = [None, 10, 20, 50, 100, 500]

results = []

def eval_problem(label, Xtr, ytr, Xte, yte):
    """Train a consistent RF and return metrics. In-memory only."""
    classes = sorted(set(ytr))
    n_classes = len(classes)
    if n_classes < 2:
        return None
    t0 = time.time()
    rf = RandomForestClassifier(
        n_estimators=100, max_depth=20, max_features='sqrt',
        min_samples_split=5, min_samples_leaf=2,
        class_weight='balanced', random_state=42, n_jobs=-1
    )
    rf.fit(Xtr, ytr)
    train_t = time.time() - t0
    y_pred = rf.predict(Xte)
    y_true = yte

    # Filter to classes present in test
    acc = accuracy_score(y_true, y_pred)
    ba = balanced_accuracy_score(y_true, y_pred)
    p, r, f, _ = precision_recall_fscore_support(y_true, y_pred, average=None,
                                                 labels=sorted(set(y_true)),
                                                 zero_division=0)
    macro_p = np.nanmean(p)
    macro_r = np.nanmean(r)
    macro_f = np.nanmean(f)
    # Weighted
    pw, rw, fw, s = precision_recall_fscore_support(y_true, y_pred,
                                                    average='weighted', zero_division=0)
    del rf
    gc.collect()
    return {
        "n_classes": n_classes,
        "rows_retained_train": int(len(Xtr)),
        "rows_retained_test": int(len(Xte)),
        "accuracy": round(float(acc), 4),
        "balanced_accuracy": round(float(ba), 4),
        "macro_precision": round(float(macro_p), 4),
        "macro_recall": round(float(macro_r), 4),
        "macro_f1": round(float(macro_f), 4),
        "weighted_precision": round(float(pw), 4),
        "weighted_recall": round(float(rw), 4),
        "weighted_f1": round(float(fw), 4),
        "train_time_s": round(train_t, 1),
    }

# Full 46-class
print("\n  [A] Full 46-class...")
full_res = eval_problem("full", X_train_full, y_train_full, X_test_full, y_test_full)
full_res["label"] = "A_Full_46_class"
full_res["formulation"] = "Full 46-class"
results.append(full_res)
print(f"      Macro F1={full_res['macro_f1']}, BA={full_res['balanced_accuracy']}")

# Filtered problems
for thr in [10, 20, 50, 100, 500]:
    keep = set(d for d, c in counts.items() if c >= thr)
    if len(keep) < 2:
        continue
    # Filter train & test consistently
    idx_tr = np.isin(y_train_full, list(keep))
    idx_te = np.isin(y_test_full, list(keep))
    Xtr, ytr = X_train_full[idx_tr], y_train_full[idx_tr]
    Xte, yte = X_test_full[idx_te], y_test_full[idx_te]
    print(f"  [{'BCDEF'[thresholds.index(thr)-1]}] >= {thr} samples ({len(keep)} classes)...")
    res = eval_problem(f"thr{thr}", Xtr, ytr, Xte, yte)
    if res is None:
        print(f"      Skipped (too few classes)")
        continue
    res["label"] = f"{'BCDEF'[thresholds.index(thr)-1]}_ge{thr}"
    res["formulation"] = f"remove < {thr} samples"
    res["threshold"] = thr
    results.append(res)
    print(f"      Macro F1={res['macro_f1']}, BA={res['balanced_accuracy']}")

# Save
with open(BASE / "step10_model_comparison.json", 'w') as f:
    json.dump({"experiments": results}, f, indent=2)
print("\n  DONE — step10_model_comparison.json")

# ============================================================
# STEP 4 — Reduced-class viability statement (metrics-driven)
# ============================================================
print("\n" + "=" * 60)
print("STEP 4 — Reduced-Class Viability")
print("=" * 60)
# Combine separability (from step5) + these metrics to assess viability
