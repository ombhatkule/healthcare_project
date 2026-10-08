"""
Phase 7C -- Disease Prediction ML Model Training (v2)

Loads backend/data/data.csv, cleans it, trains a Random Forest classifier,
evaluates it, and saves the model + metadata for Flask integration.

Outputs:
  backend/data/disease_dataset_cleaned_v2.csv   (cleaned dataset)
  backend/ml/model/disease_model.joblib          (active prediction model)
  backend/ml/model/symptom_columns.joblib        (training feature order)
  backend/ml/model/evaluation_report_v2.json     (metrics + confusion matrix)

The Random Forest `predict_proba` values are raw ensemble outputs (fraction of
trees voting for a class). They are NOT calibrated or medically validated
probabilities and must never be presented as a diagnosis or as diagnostic
confidence.
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
    classification_report,
    confusion_matrix,
)

warnings.filterwarnings("ignore")

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
DATA_RAW = os.path.join(DATA_DIR, "data.csv")
DATA_CLEANED = os.path.join(DATA_DIR, "disease_dataset_cleaned_v2.csv")
MODEL_DIR = os.path.join(BASE_DIR, "ml", "model")
os.makedirs(MODEL_DIR, exist_ok=True)

MODEL_PATH = os.path.join(MODEL_DIR, "disease_model.joblib")
SYMPTOMS_PATH = os.path.join(MODEL_DIR, "symptom_columns.joblib")
REPORT_PATH = os.path.join(MODEL_DIR, "evaluation_report_v2.json")

RANDOM_STATE = 42
TEST_SIZE = 0.2

# Resource-conscious Random Forest configuration. The prior Phase 7A model
# consumed ~750 MB-1.8 GB on disk. This configuration bounds tree size
# (max_depth=20) and ensemble size (n_estimators=100) to keep the saved model
# and its runtime memory footprint much smaller while the dataset (100K rows x
# 174 binary features) is still comfortably supported.
RF_PARAMS = {
    "n_estimators": 100,
    "max_depth": 20,
    "max_features": "sqrt",
    "min_samples_split": 5,
    "min_samples_leaf": 2,
    "class_weight": "balanced",
    "random_state": RANDOM_STATE,
    "n_jobs": -1,
    "oob_score": False,
}


def step3_clean(df):
    print("=" * 70)
    print("STEP 3 -- CLEAN DATASET")
    print("=" * 70)
    n_rows, n_cols = df.shape
    print(f"  Original rows:         {n_rows}")
    print(f"  Original columns:      {n_cols}")

    target_col = df.columns[0]
    symptom_cols = list(df.columns[1:])

    # --- Duplicate rows ---------------------------------------------------
    n_dups = int(df.duplicated().sum())
    df = df.drop_duplicates().reset_index(drop=True)
    print(f"  Duplicate rows:        {n_dups}")
    print(f"  Rows after dedup:       {len(df)}")

    # --- Validate binary values in symptom columns ------------------------
    # Fail clearly if any non-binary value is present (do not silently coerce).
    allowed = {0, 1, "0", "1"}
    bad = {}
    for c in symptom_cols:
        vals = set(df[c].unique())
        if not vals.issubset(allowed):
            bad[c] = sorted([str(v) for v in vals])
    if bad:
        bad_json = json.dumps(bad, indent=2)
        raise ValueError(
            "Unexpected non-binary symptom values detected in the dataset. "
            "Pipeline aborted rather than silently coercing values.\n" + bad_json
        )

    # --- Coerce symptom columns to int8 -----------------------------------
    df[symptom_cols] = df[symptom_cols].astype(np.int8)
    print(f"  Symptom values converted to int8: "
          f"{sorted(pd.unique(df[symptom_cols].values.ravel()).tolist())}")

    # --- Validate disease labels ------------------------------------------
    empties = int(df[target_col].astype(str).str.strip().eq("").sum())
    if empties > 0:
        raise ValueError(f"Found {empties} empty disease labels. Pipeline aborted.")
    n_classes = df[target_col].nunique()
    print(f"  Disease classes:       {n_classes} (all preserved)")

    df.to_csv(DATA_CLEANED, index=False)
    print(f"  Saved cleaned data -> {DATA_CLEANED}")
    print()
    return df


def step4_features(df):
    print("=" * 70)
    print("STEP 4 -- TRAINING FEATURES")
    print("=" * 70)
    target_col = df.columns[0]
    symptom_cols = list(df.columns[1:])

    X = df[symptom_cols].values.astype(np.int8)
    y = df[target_col].astype(str).values

    # Persist the exact feature ordering used at training time.
    joblib.dump(symptom_cols, SYMPTOMS_PATH)
    print(f"  Feature matrix shape:  {X.shape}")
    print(f"  Target vector shape:   {y.shape}")
    print(f"  Feature values:        {sorted(np.unique(X).tolist())}")
    print(f"  symptom_columns saved -> {SYMPTOMS_PATH}")
    print(f"  (exact training feature order persisted; "
          f"{len(symptom_cols)} features)")
    print()
    return X, y, symptom_cols


def step5_split(X, y):
    print("=" * 70)
    print("STEP 5 -- TRAIN/TEST SPLIT (80/20, stratified)")
    print("=" * 70)

    vc = pd.Series(y).value_counts()
    n_singletons = int((vc == 1).sum())
    print(f"  Classes total:                 {len(vc)}")
    print(f"  Classes with >=2 samples:      {int((vc >= 2).sum())}")
    print(f"  Singleton classes (<2):        {n_singletons}")
    for cls, cnt in vc.items():
        if cnt < 2:
            print(f"      - {cls}: {int(cnt)} sample(s) -- cannot be stratified")

    # Stratification requires >=2 samples per class. Singleton classes are
    # removed from the stratified split and safely appended to the TRAIN set
    # (NOT silently dropped). This guarantees every disease remains learnable.
    stratifiable = vc.index[vc >= 2]
    mask = np.array([c in stratifiable for c in y])
    X_str, y_str = X[mask], y[mask]
    X_single, y_single = X[~mask], y[~mask]
    print(f"  Stratifiable samples:          {len(X_str)}"
          f" ({len(X_str)/len(y)*100:.1f}%)")
    print(f"  Non-stratifiable (singletons): {len(X_single)}")

    if len(X_str) > 0:
        X_train, X_test, y_train, y_test = train_test_split(
            X_str, y_str,
            test_size=TEST_SIZE,
            random_state=RANDOM_STATE,
            stratify=y_str,
        )
    else:
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=TEST_SIZE, random_state=RANDOM_STATE,
        )

    if len(X_single) > 0:
        # SAFE HANDLING (documented): singleton disease rows cannot appear in
        # both train and test under stratification. They are added to TRAIN so
        # the model still learns them. The test set therefore contains only the
        # stratifiable classes. This does NOT delete any disease class.
        X_train = np.concatenate([X_train, X_single])
        y_train = np.concatenate([y_train, y_single])
        print("  NOTE: Singleton diseases were appended to the TRAIN set only.")
        print("        They are preserved, not removed.")

    print(f"  Training samples:  {len(X_train)}")
    print(f"  Testing samples:   {len(X_test)}")
    print(f"  Training classes:  {len(np.unique(y_train))}")
    print(f"  Testing classes:   {len(np.unique(y_test))}")
    print()
    return X_train, X_test, y_train, y_test


def step6_train(X_train, y_train):
    print("=" * 70)
    print("STEP 6 -- TRAIN RANDOM FOREST")
    print("=" * 70)
    print(f"  Parameters: {RF_PARAMS}")
    print("  Training in progress...")

    t0 = time.time()
    clf = RandomForestClassifier(**RF_PARAMS)
    clf.fit(X_train, y_train)
    elapsed = time.time() - t0

    print(f"  Training COMPLETE in {elapsed:.1f}s")
    print(f"  Model n_features_in_:  {clf.n_features_in_}")
    print(f"  Model n_classes:       {len(clf.classes_)}")
    print()
    return clf


def step7_evaluate(clf, X_test, y_test):
    print("=" * 70)
    print("STEP 7 -- EVALUATION (held-out test set)")
    print("=" * 70)

    y_pred = clf.predict(X_test)

    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average=None, zero_division=0)
    recall = recall_score(y_test, y_pred, average=None, zero_division=0)
    f1 = f1_score(y_test, y_pred, average=None, zero_division=0)

    metrics = {
        "accuracy": round(float(accuracy), 6),
        "precision": round(float(precision.mean()), 6),
        "recall": round(float(recall.mean()), 6),
        "f1": round(float(f1.mean()), 6),
        "macro_precision": round(
            float(precision_score(y_test, y_pred, average="macro", zero_division=0)), 6),
        "macro_recall": round(
            float(recall_score(y_test, y_pred, average="macro", zero_division=0)), 6),
        "macro_f1": round(
            float(f1_score(y_test, y_pred, average="macro", zero_division=0)), 6),
        "weighted_precision": round(
            float(precision_score(y_test, y_pred, average="weighted", zero_division=0)), 6),
        "weighted_recall": round(
            float(recall_score(y_test, y_pred, average="weighted", zero_division=0)), 6),
        "weighted_f1": round(
            float(f1_score(y_test, y_pred, average="weighted", zero_division=0)), 6),
    }

    print(f"  Test samples:             {len(y_test)}")
    print(f"  Classes in test:          {len(np.unique(y_test))}")
    print(f"  Accuracy:                 {metrics['accuracy']:.4f}")
    print(f"  Macro Precision:          {metrics['macro_precision']:.4f}")
    print(f"  Macro Recall:             {metrics['macro_recall']:.4f}")
    print(f"  Macro F1:                 {metrics['macro_f1']:.4f}")
    print(f"  Weighted Precision:       {metrics['weighted_precision']:.4f}")
    print(f"  Weighted Recall:          {metrics['weighted_recall']:.4f}")
    print(f"  Weighted F1:              {metrics['weighted_f1']:.4f}")
    print()

    # Per-class report
    report = classification_report(
        y_test, y_pred, zero_division=0, output_dict=True
    )
    class_metrics = {}
    for cls in sorted(set(y_test)):
        if cls in report:
            cm = report[cls]
            class_metrics[str(cls)] = {
                "precision": round(float(cm["precision"]), 6),
                "recall": round(float(cm["recall"]), 6),
                "f1": round(float(cm["f1-score"]), 6),
                "support": int(cm["support"]),
            }
    # Add test classes that were never predicted (still present? no, only in y_test)
    for cls in sorted(set(y_test)):
        class_metrics.setdefault(
            str(cls),
            {"precision": 0.0, "recall": 0.0, "f1": 0.0, "support": 0},
        )

    # Confusion matrix (46 classes is tractable as a JSON integer grid).
    # Provided for inspection; the primary interpretation is via per-class
    # precision/recall/F1 above.
    labels = sorted(set(y_test))
    cm = confusion_matrix(y_test, y_pred, labels=labels)

    report_json = {
        "metrics": metrics,
        "n_classes": int(len(clf.classes_)),
        "n_classes_in_test": int(len(np.unique(y_test))),
        "n_features": int(clf.n_features_in_),
        "train_samples": None,  # filled in main()
        "test_samples": int(len(y_test)),
        "model_parameters": RF_PARAMS,
        "per_class_metrics": class_metrics,
        "confusion_matrix": {
            "classes": [str(l) for l in labels],
            "matrix": cm.astype(int).tolist(),
            "note": (
                "Full 46x46 confusion matrix included for inspection. "
                "Per-class precision/recall/F1 above is the primary "
                "interpretation for this highly imbalanced dataset."
            ),
        },
    }
    return report_json


def step8_save(clf, report_json):
    print("=" * 70)
    print("STEP 8 -- SAVE MODEL")
    print("=" * 70)
    joblib.dump(clf, MODEL_PATH)
    size_mb = os.path.getsize(MODEL_PATH) / 1024 / 1024
    print(f"  Model saved  -> {MODEL_PATH}")
    print(f"  Model size:  {size_mb:.1f} MB")

    symptom_cols = joblib.load(SYMPTOMS_PATH)
    ok = getattr(clf, "n_features_in_", None) == len(symptom_cols)
    print(f"  Verify n_features_in_ == len(symptom_columns): "
          f"{getattr(clf, 'n_features_in_', None)} == {len(symptom_cols)} "
          f"-> {'OK' if ok else 'MISMATCH!'}")
    if not ok:
        raise RuntimeError("Feature count mismatch between model and metadata.")

    # Model load timing (fresh process simulation done in test_prediction.py)
    t0 = time.time()
    _ = joblib.load(MODEL_PATH)
    load_s = time.time() - t0
    report_json["model_size_mb"] = round(size_mb, 2)
    report_json["model_load_time_s"] = round(load_s, 4)

    with open(REPORT_PATH, "w") as f:
        json.dump(report_json, f, indent=2)
    print(f"  Report saved -> {REPORT_PATH}")
    print()


def main():
    print()
    print("#" * 70)
    print("#  PHASE 7C -- DISEASE PREDICTION MODEL (v2)")
    print("#" * 70)
    print()

    print(f"Loading dataset: {DATA_RAW}")
    df = pd.read_csv(DATA_RAW)
    if df.columns[0] != "disease":
        print("ERROR: Target column must be 'disease'.")
        sys.exit(1)
    print(f"  Loaded {df.shape[0]} rows x {df.shape[1]} columns")
    print()

    df_clean = step3_clean(df)
    X, y, symptom_cols = step4_features(df_clean)
    X_train, X_test, y_train, y_test = step5_split(X, y)
    clf = step6_train(X_train, y_train)
    report_json = step7_evaluate(clf, X_test, y_test)
    report_json["train_samples"] = int(len(X_train))
    report_json["n_features"] = int(clf.n_features_in_)
    report_json["n_classes"] = int(len(clf.classes_))
    step8_save(clf, report_json)

    print("=" * 70)
    print("PHASE 7C TRAINING COMPLETE.")
    print("=" * 70)
    print("  Active model    : disease_model.joblib")
    print("  Symptom metadata: symptom_columns.joblib (174 features)")
    print("  Evaluation      : evaluation_report_v2.json")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()