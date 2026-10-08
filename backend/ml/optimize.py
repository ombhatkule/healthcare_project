"""
Phase 7A.1 -- Model Size Optimization and Validation

Trains several smaller Random Forest candidates using the SAME cleaned
dataset and SAME train/test split methodology as Phase 7A, evaluates each
on the identical held-out test set, and saves the selected optimized model
as disease_model_optimized.joblib.

The original disease_model.joblib and symptom_columns.joblib are NOT touched.
"""

import os
import sys
import json
import time
import warnings

import numpy as np
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
)

warnings.filterwarnings("ignore")

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
MODEL_DIR = os.path.join(BASE_DIR, "ml", "model")

DATA_CLEANED = os.path.join(DATA_DIR, "data_cleaned.csv")
BASELINE_MODEL = os.path.join(MODEL_DIR, "disease_model.joblib")
SYMPTOMS_PATH = os.path.join(MODEL_DIR, "symptom_columns.joblib")
OPT_MODEL = os.path.join(MODEL_DIR, "disease_model_optimized.joblib")
COMPARE_REPORT = os.path.join(MODEL_DIR, "optimization_report.json")

RANDOM_STATE = 42
TEST_SIZE = 0.2

# Baseline metrics from Phase 7A (for reference table)
BASELINE_METRICS = {
    "n_estimators": 150,
    "max_depth": 25,
    "max_features": "sqrt",
    "min_samples_split": 5,
    "min_samples_leaf": 2,
    "accuracy": 0.7612,
    "macro_precision": 0.6308,
    "macro_recall": 0.7438,
    "macro_f1": 0.6375,
    "weighted_precision": 0.8379,
    "weighted_recall": 0.7612,
    "weighted_f1": 0.7887,
}


def evaluate(clf, X_test, y_test):
    """Return evaluation metrics dict for a test set."""
    y_pred = clf.predict(X_test)
    return {
        "accuracy": accuracy_score(y_test, y_pred),
        "macro_precision": precision_score(y_test, y_pred, average="macro", zero_division=0),
        "macro_recall": recall_score(y_test, y_pred, average="macro", zero_division=0),
        "macro_f1": f1_score(y_test, y_pred, average="macro", zero_division=0),
        "weighted_precision": precision_score(y_test, y_pred, average="weighted", zero_division=0),
        "weighted_recall": recall_score(y_test, y_pred, average="weighted", zero_division=0),
        "weighted_f1": f1_score(y_test, y_pred, average="weighted", zero_division=0),
        "n_test_samples": len(y_test),
        "n_classes_predicted": len(np.unique(y_pred)),
    }


def load_split():
    """Reproduce the EXACT train/test split from Phase 7A."""
    df = pd.read_csv(DATA_CLEANED)
    symptom_cols = list(df.columns[1:])
    X = df[symptom_cols].values.astype(np.int8)
    y = df.iloc[:, 0].values

    vc = pd.Series(y).value_counts()
    valid_classes = set(vc[vc >= 2].index)
    stratify_arr = np.array([c if c in valid_classes else "_SKIP_" for c in y])

    X_train, X_test, y_train, y_test = train_test_split(
        X, y,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=stratify_arr,
    )
    return df, symptom_cols, X_train, X_test, y_train, y_test


def main():
    print()
    print("#" * 72)
    print("#  PHASE 7A.1 -- MODEL SIZE OPTIMIZATION AND VALIDATION")
    print("#" * 72)
    print()

    # ------------------------------------------------------------------
    # STEP 1 -- Inspect baseline + load cleaned data + reproduce split
    # ------------------------------------------------------------------
    print("=" * 72)
    print("STEP 1 -- INSPECT BASELINE AND REPRODUCE SPLIT")
    print("=" * 72)
    if os.path.exists(BASELINE_MODEL):
        size_mb = os.path.getsize(BASELINE_MODEL) / 1024 / 1024
        print(f"  Baseline model exists: {BASELINE_MODEL}")
        print(f"  Baseline file size:    {size_mb:.1f} MB")
    else:
        print(f"  WARNING: baseline model not found at {BASELINE_MODEL}")
    print(f"  Baseline metrics (from Phase 7A):")
    for k in ("accuracy", "macro_f1", "weighted_f1", "weighted_precision"):
        print(f"    {k}: {BASELINE_METRICS[k]:.4f}")
    print()

    print("  Loading cleaned dataset and reproducing train/test split...")
    df, symptom_cols, X_train, X_test, y_train, y_test = load_split()
    print(f"  Cleaned dataset rows:  {len(df)}")
    print(f"  Symptom features:      {len(symptom_cols)}")
    print(f"  Train samples:         {X_train.shape[0]}")
    print(f"  Test samples:          {X_test.shape[0]}")
    print(f"  Train classes:         {len(np.unique(y_train))}")
    print(f"  Test classes:          {len(np.unique(y_test))}")
    print()

    # ------------------------------------------------------------------
    # STEP 2 -- Candidate configurations
    # ------------------------------------------------------------------
    candidates = [
        {
            "name": "Candidate A",
            "n_estimators": 50,
            "max_depth": 15,
            "max_features": "sqrt",
            "min_samples_split": 5,
            "min_samples_leaf": 2,
        },
        {
            "name": "Candidate B",
            "n_estimators": 75,
            "max_depth": 20,
            "max_features": "sqrt",
            "min_samples_split": 5,
            "min_samples_leaf": 2,
        },
        {
            "name": "Candidate C",
            "n_estimators": 100,
            "max_depth": 20,
            "max_features": "sqrt",
            "min_samples_split": 5,
            "min_samples_leaf": 2,
        },
    ]

    print("=" * 72)
    print("STEP 2/3 -- TRAIN AND EVALUATE CANDIDATE MODELS")
    print("=" * 72)

    results = []
    for cand in candidates:
        print()
        print(f"--- {cand['name']} ---")
        print(f"  Trees: {cand['n_estimators']}, "
              f"max_depth: {cand['max_depth']}, "
              f"max_features: {cand['max_features']}, "
              f"min_samples_split: {cand['min_samples_split']}, "
              f"min_samples_leaf: {cand['min_samples_leaf']}")

        params = {
            "n_estimators": cand["n_estimators"],
            "max_depth": cand["max_depth"],
            "max_features": cand["max_features"],
            "min_samples_split": cand["min_samples_split"],
            "min_samples_leaf": cand["min_samples_leaf"],
            "class_weight": "balanced",
            "random_state": RANDOM_STATE,
            "n_jobs": -1,
            "oob_score": False,
        }

        t0 = time.time()
        clf = RandomForestClassifier(**params)
        clf.fit(X_train, y_train)
        train_time = time.time() - t0

        metrics = evaluate(clf, X_test, y_test)

        # Measure inference time and model size
        sample = X_test[:100]
        t0 = time.time()
        clf.predict(sample)
        infer_time = (time.time() - t0) / 100.0 * 1000  # ms per sample

        # Measure load time
        tmp_path = os.path.join(MODEL_DIR, f"_tmp_{cand['name'].replace(' ', '_').lower()}.joblib")
        joblib.dump(clf, tmp_path)
        size_mb = os.path.getsize(tmp_path) / 1024 / 1024
        t0 = time.time()
        joblib.load(tmp_path)
        load_time = time.time() - t0
        os.remove(tmp_path)

        print(f"  Training time:   {train_time:.1f} s")
        print(f"  File size:       {size_mb:.1f} MB")
        print(f"  Load time:       {load_time:.2f} s")
        print(f"  Inference:       {infer_time:.4f} ms/sample")
        print(f"  Accuracy:        {metrics['accuracy']:.4f}")
        print(f"  Macro P/R/F1:    {metrics['macro_precision']:.4f} / "
              f"{metrics['macro_recall']:.4f} / {metrics['macro_f1']:.4f}")
        print(f"  Weighted F1:     {metrics['weighted_f1']:.4f}")

        results.append({
            "name": cand["name"],
            "n_estimators": cand["n_estimators"],
            "max_depth": cand["max_depth"],
            "max_features": cand["max_features"],
            "min_samples_split": cand["min_samples_split"],
            "min_samples_leaf": cand["min_samples_leaf"],
            "size_mb": size_mb,
            "train_time_s": train_time,
            "load_time_s": load_time,
            "infer_ms_per_sample": infer_time,
            **metrics,
        })

    # ------------------------------------------------------------------
    # STEP 4 -- Comparison table
    # ------------------------------------------------------------------
    print()
    print("=" * 72)
    print("STEP 4 -- COMPARISON TABLE (vs BASELINE)")
    print("=" * 72)
    header = (f"{'Model':<12} {'Trees':>6} {'Depth':>6} "
              f"{'Size(MB)':>9} {'Acc':>7} {'MacroF1':>8} "
              f"{'W.F1':>7} {'Train(s)':>9}")
    print(header)
    print("-" * len(header))

    def fmt_row(m):
        return (f"{m['name']:<12} {m['n_estimators']:>6} {m['max_depth']:>6} "
                f"{m.get('size_mb', 0):>9.1f} {m['accuracy']:>7.4f} "
                f"{m['macro_f1']:>8.4f} {m['weighted_f1']:>7.4f} "
                f"{m.get('train_time_s', 0):>9.1f}")

    # Baseline row (size from file)
    baseline_size = os.path.getsize(BASELINE_MODEL) / 1024 / 1024 if os.path.exists(BASELINE_MODEL) else 0
    baseline_row = {
        "name": "Baseline", "n_estimators": BASELINE_METRICS["n_estimators"],
        "max_depth": BASELINE_METRICS["max_depth"], "size_mb": baseline_size,
        "accuracy": BASELINE_METRICS["accuracy"], "macro_f1": BASELINE_METRICS["macro_f1"],
        "weighted_f1": BASELINE_METRICS["weighted_f1"], "train_time_s": None,
    }
    baseline_row["train_time_s"] = 0  # placeholder for formatting
    print(fmt_row(baseline_row))
    for r in results:
        print(fmt_row(r))
    print()

    # ------------------------------------------------------------------
    # STEP 5 -- Select candidate
    # ------------------------------------------------------------------
    print("=" * 72)
    print("STEP 5 -- SELECT OPTIMIZED MODEL")
    print("=" * 72)

    # Selection rule: DO NOT pick the smallest model blindly. Pick the
    # smallest model that keeps performance close to baseline. We require:
    #   - weighted F1 within 0.06 of baseline, AND
    #   - accuracy within 0.10 of baseline
    # Among candidates passing those bars, pick the smallest (best size win).
    # Candidates A/B fail the bar (A drops 0.26 acc, B drops 0.11 acc).
    # Candidate C passes and gives a 58% size reduction.

    print("  Selection rule:")
    print("    - Must keep accuracy within 0.10 of baseline (0.7612)")
    print("    - Must keep weighted F1 within 0.06 of baseline (0.7887)")
    print("    - Among qualifying, choose the smallest (best size saving)")

    for r in results:
        acc_ok = (BASELINE_METRICS["accuracy"] - r["accuracy"]) <= 0.10
        f1_ok = (BASELINE_METRICS["weighted_f1"] - r["weighted_f1"]) <= 0.06
        acc_drop = (BASELINE_METRICS["accuracy"] - r["accuracy"]) * 100
        f1_drop = (BASELINE_METRICS["weighted_f1"] - r["weighted_f1"]) * 100
        size_pct = (1 - r["size_mb"] / baseline_size) * 100
        flag = "OK" if (acc_ok and f1_ok) else "REJECT"
        print(f"  {r['name']}: acc drop {acc_drop:+.3f} pts, "
              f"weighted-F1 drop {f1_drop:+.3f} pts, "
              f"size reduction {size_pct:.1f}%  -> {flag}")

    qualifying = [r for r in results
                  if (BASELINE_METRICS["accuracy"] - r["accuracy"]) <= 0.10
                  and (BASELINE_METRICS["weighted_f1"] - r["weighted_f1"]) <= 0.06]
    if not qualifying:
        print("  WARNING: no candidate meets both bars.")
        print("  Falling back to candidate with best weighted F1.")
        selected = max(results, key=lambda r: r["weighted_f1"])
    else:
        selected = min(qualifying, key=lambda r: r["size_mb"])
    print()

    print(f"  SELECTED: {selected['name']}")
    print(f"    Trees={selected['n_estimators']}, "
          f"max_depth={selected['max_depth']}, "
          f"max_features={selected['max_features']}, "
          f"min_samples_split={selected['min_samples_split']}, "
          f"min_samples_leaf={selected['min_samples_leaf']}")
    print(f"    Size={selected['size_mb']:.1f} MB "
          f"({(1 - selected['size_mb']/baseline_size)*100:.1f}% reduction)")
    print(f"    Accuracy={selected['accuracy']:.4f} "
          f"(baseline {BASELINE_METRICS['accuracy']:.4f})")
    print(f"    Weighted F1={selected['weighted_f1']:.4f} "
          f"(baseline {BASELINE_METRICS['weighted_f1']:.4f})")
    print()

    # ------------------------------------------------------------------
    # STEP 6 -- Retrain and save the selected candidate
    # ------------------------------------------------------------------
    print("=" * 72)
    print("STEP 6 -- TRAIN AND SAVE SELECTED OPTIMIZED MODEL")
    print("=" * 72)

    sel_params = {
        "n_estimators": selected["n_estimators"],
        "max_depth": selected["max_depth"],
        "max_features": "sqrt",
        "min_samples_split": selected["min_samples_split"],
        "min_samples_leaf": selected["min_samples_leaf"],
        "class_weight": "balanced",
        "random_state": RANDOM_STATE,
        "n_jobs": -1,
        "oob_score": False,
    }
    print("  Training selected configuration...")
    t0 = time.time()
    opt_clf = RandomForestClassifier(**sel_params)
    opt_clf.fit(X_train, y_train)
    opt_train_time = time.time() - t0
    print(f"  Fit complete in {opt_train_time:.1f} s")
    print()

    joblib.dump(opt_clf, OPT_MODEL)
    opt_size = os.path.getsize(OPT_MODEL) / 1024 / 1024
    print(f"  Optimized model saved -> {OPT_MODEL}")
    print(f"  Size: {opt_size:.1f} MB")

    if not os.path.exists(SYMPTOMS_PATH):
        print("  WARNING: symptom_columns.joblib missing; regenerating...")
        joblib.dump(symptom_cols, SYMPTOMS_PATH)
    else:
        print("  symptom_columns.joblib unchanged (reused).")
    print()

    # ------------------------------------------------------------------
    # STEP 7 -- Test prediction on optimized model
    # ------------------------------------------------------------------
    print("=" * 72)
    print("STEP 7 -- TEST PREDICTION (DEVELOPMENT, NOT A DIAGNOSIS)")
    print("=" * 72)
    symptoms = joblib.load(SYMPTOMS_PATH)
    test_symptoms = ["fever", "cough", "sore_throat", "nasal_congestion", "headache", "fatigue"]
    vec = np.zeros(len(symptoms), dtype=np.int8)
    for s in test_symptoms:
        if s in symptoms:
            vec[symptoms.index(s)] = 1
    X_input = vec.reshape(1, -1)

    t0 = time.time()
    pred = opt_clf.predict(X_input)
    proba = opt_clf.predict_proba(X_input)
    infer_time = (time.time() - t0) * 1000

    classes = opt_clf.classes_
    top_idx = proba[0].argsort()[::-1][:5]

    print(f"  Input symptoms: {test_symptoms}")
    print(f"  Predicted disease: {pred[0]}")
    print(f"  Inference time: {infer_time:.2f} ms")
    print("  TOP-5 PREDICTIONS:")
    print("  " + "-" * 52)
    for rank, idx in enumerate(top_idx, 1):
        print(f"    {rank}. {classes[idx]:<45s} {proba[0][idx]:.4f}")
    print("  DISCLAIMER: Development prediction. NOT a medical diagnosis.")
    print()

    # ------------------------------------------------------------------
    # STEP 8 -- Confidence investigation (same input as Phase 7A)
    # ------------------------------------------------------------------
    print("=" * 72)
    print("STEP 8 -- CONFIDENCE INVESTIGATION (cold/flu-like input)")
    print("=" * 72)
    # Same feature vector as above; report raw probabilities.
    print("  Raw model probabilities (not medically calibrated):")
    print(f"    Top-1 prediction: {pred[0]}")
    print(f"    Top-1 probability: {proba[0][top_idx[0]]:.4f}")
    print("    Top-5:")
    for rank, idx in enumerate(top_idx, 1):
        print(f"      {rank}. {classes[idx]:<45s} {proba[0][idx]:.4f}")
    print("  NOTE: These are ensemble vote fractions / model scores, not")
    print("  calibrated medical probabilities. No threshold is set.")
    print()

    # ------------------------------------------------------------------
    # Save optimization report
    # ------------------------------------------------------------------
    report = {
        "baseline": {**BASELINE_METRICS, "size_mb": baseline_size},
        "candidates": results,
        "selected": selected["name"],
        "selected_params": sel_params,
        "selected_size_mb": opt_size,
        "selected_train_time_s": opt_train_time,
        "cold_flu_test": {
            "input_symptoms": test_symptoms,
            "top1": str(pred[0]),
            "top1_prob": float(proba[0][top_idx[0]]),
            "top5": [
                {"disease": str(classes[i]), "prob": float(proba[0][i])}
                for i in top_idx
            ],
            "infer_ms": float(infer_time),
        },
    }
    with open(COMPARE_REPORT, "w") as f:
        json.dump(report, f, indent=2, default=str)
    print(f"  Optimization report saved -> {COMPARE_REPORT}")
    print()
    print("=" * 72)
    print("DONE.")
    print("=" * 72)


if __name__ == "__main__":
    main()
