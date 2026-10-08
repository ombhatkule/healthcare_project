import json
import sys
import time
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    confusion_matrix,
    precision_recall_fscore_support,
)
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.pipeline import Pipeline
from sklearn.feature_selection import SelectKBest, chi2
from sklearn.svm import LinearSVC

ROOT = Path(r"C:\Users\ADMIN\OneDrive\Desktop\healthcareapp\backend\ml\phase7i")
DATA = ROOT / "data" / "symbipredict_representationC_131feat.csv"
FEAT_JSON = ROOT / "data" / "symptom_columns_131.json"
TARGET = "prognosis"
RANDOM_STATE = 42
N_SPLITS = 5
N_REPEATS = 10
REPEAT_SEEDS = [RANDOM_STATE + i for i in range(N_REPEATS)]

DISCLAIMER = "Non-clinical research/educational evaluation; not clinically validated."
NOT_MEDICAL = "This model must not be used as a medical diagnosis system."

CLASSES = None


def build_models() -> dict:
    return {
        "LR_class_weight_None": LogisticRegression(
            max_iter=5000, solver="lbfgs", random_state=RANDOM_STATE, class_weight=None
        ),
        "LR_class_weight_balanced": LogisticRegression(
            max_iter=5000, solver="lbfgs", random_state=RANDOM_STATE, class_weight="balanced"
        ),
        "LinearSVC_class_weight_None": LinearSVC(
            max_iter=10000, random_state=RANDOM_STATE, class_weight=None
        ),
        "LinearSVC_class_weight_balanced": LinearSVC(
            max_iter=10000, random_state=RANDOM_STATE, class_weight="balanced"
        ),
        "RF_class_weight_None": RandomForestClassifier(
            n_estimators=200,
            max_features="sqrt",
            min_samples_split=2,
            min_samples_leaf=1,
            class_weight=None,
            random_state=RANDOM_STATE,
            n_jobs=-1,
        ),
        "RF_class_weight_balanced": RandomForestClassifier(
            n_estimators=200,
            max_features="sqrt",
            min_samples_split=2,
            min_samples_leaf=1,
            class_weight="balanced",
            random_state=RANDOM_STATE,
            n_jobs=-1,
        ),
    }


def majority_baseline(y_train, y_test):
    """Raw majority-class rule fit on training labels only."""
    from collections import Counter

    votes = Counter(y_train)
    pred = np.full(len(y_test), votes.most_common(1)[0][0])
    return pred


def grouped_folds(X, y, groups):
    for seed in REPEAT_SEEDS:
        sgkf = StratifiedGroupKFold(n_splits=N_SPLITS, shuffle=True, random_state=seed)
        yield from sgkf.split(X, y, groups=groups)


def summarize(metrics_array, classes_list):
    out = {}
    for m in classes_list:
        arr = np.asarray(metrics_array[m], dtype=float)
        out[m + "_mean"] = float(round(arr.mean(), 6))
        out[m + "_std"] = float(round(arr.std(), 6))
    return out


def main() -> int:
    global CLASSES
    print("=" * 60)
    print("PHASE 7I STEP 2: GROUPED CROSS-VALIDATION BENCHMARK")
    print(DISCLAIMER)
    print("=" * 60)

    df = pd.read_csv(DATA, index_col=None)
    X = df.drop(columns=[TARGET])
    y = df[TARGET].astype(str)
    CLASSES = sorted(y.unique().tolist())
    class_index = {c: i for i, c in enumerate(CLASSES)}
    n = len(y)

    # groups: unique symptom vector identity
    group_key = X.astype(str).apply(lambda r: "|".join(r), axis=1)
    groups = pd.factorize(group_key)[0]
    group_label = pd.Series(groups).map(
        {i: k for i, k in enumerate(pd.factorize(group_key)[1])}
    )
    n_groups = len(np.unique(groups))

    models = build_models()
    results = {}
    aggregated = {}  # model -> aggregated confusion matrix
    all_predictions = {}  # for heldout collection (repeat 0)

    feasibility = {"n_splits": N_SPLITS, "n_repeats": N_REPEATS, "eliminated": True}

    for name, est in models.items():
        t0 = time.time()
        fold_metrics = {k: [] for k in
                        ["accuracy", "balanced_accuracy", "macro_precision", "macro_recall",
                         "macro_f1", "weighted_precision", "weighted_recall", "weighted_f1"]}
        agg_conf = np.zeros((len(CLASSES), len(CLASSES)), dtype=int)
        held = []
        for fold_idx, (train_i, test_i) in enumerate(grouped_folds(X, y, groups)):
            Xtr, Xte = X.iloc[train_i], X.iloc[test_i]
            ytr, yte = y.iloc[train_i], y.iloc[test_i]
            est.fit(Xtr, ytr)
            pred = est.predict(Xte)
            acc = accuracy_score(yte, pred)
            bacc = balanced_accuracy_score(yte, pred)
            P, R, F, _ = precision_recall_fscore_support(yte, pred, labels=CLASSES, average="macro", zero_division=0)
            wP, wR, wF, _ = precision_recall_fscore_support(yte, pred, labels=CLASSES, average="weighted", zero_division=0)
            fold_metrics["accuracy"].append(acc)
            fold_metrics["balanced_accuracy"].append(bacc)
            fold_metrics["macro_precision"].append(P)
            fold_metrics["macro_recall"].append(R)
            fold_metrics["macro_f1"].append(F)
            fold_metrics["weighted_precision"].append(wP)
            fold_metrics["weighted_recall"].append(wR)
            fold_metrics["weighted_f1"].append(wF)
            cmi = confusion_matrix(yte, pred, labels=CLASSES)
            agg_conf += cmi
            held.append({"fold": fold_idx, "train": train_i, "test": test_i, "pred": pred, "y": yte})
        results[name] = summarize(fold_metrics, list(fold_metrics.keys()))
        results[name]["n_folds"] = len(fold_metrics["accuracy"])
        aggregated[name] = agg_conf
        # heldout from first repeat seeds
        repeat0 = [h for h in held if h["fold"] < N_SPLITS]
        all_predictions[name] = repeat0
        dt = time.time() - t0
        print(f"{name:28s} n_folds={len(fold_metrics['accuracy'])} "
              f"acc={results[name]['accuracy_mean']:.4f}±{results[name]['accuracy_std']:.4f} "
              f"bacc={results[name]['balanced_accuracy_mean']:.4f} "
              f"mf1={results[name]['macro_f1_mean']:.4f} ({dt:.0f}s)")

    # ---------- MAJORITY BASELINE ----------
    bc = y.value_counts().to_dict()
    majority_class = max(bc, key=bc.get)
    majority_frac = bc[majority_class] / n
    baseline = {
        "n_folds": "none",
        "strategy": "constant majority-class prediction",
        "majority_class": majority_class,
        "majority_support": int(bc[majority_class]),
        "accuracy_mean": round(majority_frac, 6),
        "accuracy_std": 0.0,
        "balanced_accuracy_mean": round(1.0 / len(CLASSES), 6),
        "balanced_accuracy_std": 0.0,
        "macro_precision_mean": 0.0,
        "macro_recall_mean": 0.0,
        "macro_f1_mean": 0.0,
        "macro_f1_std": 0.0,
        "weighted_precision_mean": round(majority_frac, 6),
        "weighted_recall_mean": round(majority_frac, 6),
        "weighted_f1_mean": round(majority_frac, 6),
        "weighted_f1_std": 0.0,
    }
    results["MAJORITY_BASELINE"] = baseline

    # ---------- ABLATION: inside-fold feature selection ----------
    print("\nAblation: LR-balanced vs LR-balanced with fold-internal SelectKBest(chi2, k=70)...")
    ablation_folds = {k: [] for k in ["accuracy", "balanced_accuracy", "macro_precision", "macro_recall",
                                      "macro_f1", "weighted_precision", "weighted_recall", "weighted_f1"]}
    for seed in REPEAT_SEEDS:
        sgkf = StratifiedGroupKFold(n_splits=N_SPLITS, shuffle=True, random_state=seed)
        for train_i, test_i in sgkf.split(X, y, groups=groups):
            Xtr, Xte = X.iloc[train_i], X.iloc[test_i]
            ytr, yte = y.iloc[train_i], y.iloc[test_i]
            pipe = Pipeline([
                ("sel", SelectKBest(chi2, k=70)),
                ("clf", LogisticRegression(max_iter=5000, solver="lbfgs", random_state=RANDOM_STATE, class_weight="balanced")),
            ])
            pipe.fit(Xtr, ytr)
            pred = pipe.predict(Xte)
            ablation_folds["accuracy"].append(accuracy_score(yte, pred))
            ablation_folds["balanced_accuracy"].append(balanced_accuracy_score(yte, pred))
            P, R, F, _ = precision_recall_fscore_support(yte, pred, labels=CLASSES, average="macro", zero_division=0)
            wP, wR, wF, _ = precision_recall_fscore_support(yte, pred, labels=CLASSES, average="weighted", zero_division=0)
            ablation_folds["macro_precision"].append(P)
            ablation_folds["macro_recall"].append(R)
            ablation_folds["macro_f1"].append(F)
            ablation_folds["weighted_precision"].append(wP)
            ablation_folds["weighted_recall"].append(wR)
            ablation_folds["weighted_f1"].append(wF)
    ablation = summarize(ablation_folds, list(ablation_folds.keys()))
    ablation["n_folds"] = len(ablation_folds["accuracy"])
    results["ABLATION_LR_balanced_SelectKBest70"] = ablation
    print(f"Ablation: acc={ablation['accuracy_mean']:.4f} bacc={ablation['balanced_accuracy_mean']:.4f} "
          f"mf1={ablation['macro_f1_mean']:.4f}")

    # ---------- RANKING (macro F1 > balanced acc > macro recall) ----------
    cands = [k for k in results if k != "MAJORITY_BASELINE"]
    cands.sort(key=lambda k: (results[k]["macro_f1_mean"], results[k]["balanced_accuracy_mean"],
                              results[k]["macro_recall_mean"]), reverse=True)
    ranked = []
    for i, k in enumerate(cands):
        ranked.append({"rank": i + 1, "model": k, **results[k]})
    comparator = ranked[0]
    runner_up = ranked[1]
    delta = comparator["macro_f1_mean"] - runner_up["macro_f1_mean"]
    both_std = max(comparator["macro_f1_std"], runner_up["macro_f1_std"])
    if delta <= both_std * 0.5:
        winner_status = "NO_CLEAR_WINNER"
    else:
        winner_status = f"WINNER: {comparator['model']}"
    best_name = comparator["model"]

    # ---------- PER-CLASS + ERROR ANALYSIS (best model) ----------
    agg_conf = aggregated[best_name]
    cm = agg_conf
    total_support = cm.sum(axis=1)
    assert total_support.sum() == n * N_REPEATS
    per_class = []
    for i, c in enumerate(CLASSES):
        tp = cm[i, i]
        fp = cm[:, i].sum() - tp
        fn = cm[i, :].sum() - tp
        pr = tp / (tp + fp) if (tp + fp) else 0.0
        re = tp / (tp + fn) if (tp + fn) else 0.0
        f1 = 2 * pr * re / (pr + re) if (pr + re) else 0.0
        per_class.append({"disease": c, "support": int(total_support[i]),
                          "precision": round(pr, 6), "recall": round(re, 6), "f1": round(f1, 6),
                          "tp": int(tp)})
    per_class_df = pd.DataFrame(per_class).sort_values("support", ascending=True)
    per_class_df.to_csv(ROOT / "reports" / "per_class_metrics.csv", index=False)

    zero_recall = per_class_df[per_class_df["recall"] == 0]["disease"].tolist()
    low_support = per_class_df[per_class_df["support"] <= 50].sort_values("support").to_dict("records")

    # confusion pairs for error analysis (best model): predicted != true, count > 0
    pairs = []
    for i, c in enumerate(CLASSES):
        for j, d in enumerate(CLASSES):
            if i != j and cm[i, j] > 0:
                pairs.append({"true": c, "predicted": d, "count": int(cm[i, j]),
                              "true_support": int(total_support[i]), "recall_of_true": round(cm[i, i] / total_support[i], 4) if total_support[i] else 0})
    pairs.sort(key=lambda r: r["count"], reverse=True)
    pairs_df = pd.DataFrame(pairs)
    pairs_df.to_csv(ROOT / "reports" / "confusion_pairs.csv", index=False)
    top_pairs = pairs_df.head(20).to_dict("records") if len(pairs_df) else []

    # ---------- FEATURE IMPORTANCE (best model) ----------
    feat_imp = None
    best_est = models[best_name]
    if hasattr(best_est, "feature_importances_"):
        est_final = best_est
        est_final.fit(X, y)
        imp = pd.DataFrame({"feature": X.columns, "importance": est_final.feature_importances_})
        imp = imp.sort_values("importance", ascending=False)
        imp.to_csv(ROOT / "reports" / "feature_importance.csv", index=False)
        feat_imp = imp.head(20).to_dict("records")
    elif hasattr(best_est, "coef_"):
        est_final = best_est
        est_final.fit(X, y)
        coefs = np.abs(np.atleast_2d(est_final.coef_)).mean(axis=0)
        imp = pd.DataFrame({"feature": X.columns, "abs_mean_coef": coefs})
        imp = imp.sort_values("abs_mean_coef", ascending=False)
        imp.to_csv(ROOT / "reports" / "feature_importance.csv", index=False)
        feat_imp = imp.head(20).to_dict("records")

    # ---------- SAVE BEST MODEL (references only) ----------
    final_model = models[best_name]
    final_model.fit(X, y)
    model_path = ROOT / "models" / "experimental_best_model.joblib"
    joblib.dump(final_model, model_path)
    vocab_hash = json.loads((ROOT / "data" / "symptom_columns_131.json").read_text(encoding="utf-8"))
    prep_report = json.loads((ROOT / "validation" / "phase7i_preprocessing.json").read_text(encoding="utf-8"))
    dataset_sha = prep_report["processed_dataset_sha256"]
    metadata = {
        "model_type": type(final_model).__name__,
        "parameters": final_model.get_params(deep=True),
        "best_config_key": best_name,
        "feature_count": int(X.shape[1]),
        "feature_vocabulary_file": str(FEAT_JSON),
        "feature_vocabulary_sha256": prep_report["vocabulary_sha256"],
        "dataset_path": str(DATA),
        "dataset_sha256": dataset_sha,
        "random_seed": RANDOM_STATE,
        "evaluation_strategy": "Repeated Stratified Group K-Fold (5 folds x 10 repeats) grouped by unique symptom vector",
        "cv_configuration": {"n_splits": N_SPLITS, "n_repeats": N_REPEATS, "repeat_seeds": REPEAT_SEEDS},
        "metrics": comparator,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "status": "NOT PRODUCTION",
        "medical_disclaimer": NOT_MEDICAL,
        "disclaimer": DISCLAIMER,
    }
    (ROOT / "models" / "experimental_model_metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8")

    # ---------- CONFUSION MATRICES (all models) ----------
    for name, cmt in aggregated.items():
        cdf = pd.DataFrame(cmt, index=CLASSES, columns=CLASSES)
        cdf.index.name = "true\\pred"
        cdf.to_csv(ROOT / "benchmarks" / f"confusion_matrix_{name}.csv")

    # ---------- MODEL COMPARISON TABLE ----------
    comp_rows = []
    for r in ranked:
        comp_rows.append({
            "model": r["model"], "rank": r["rank"],
            "folds": N_SPLITS, "repeats": N_REPEATS,
            "accuracy_mean": r["accuracy_mean"], "accuracy_std": r["accuracy_std"],
            "balanced_accuracy_mean": r["balanced_accuracy_mean"], "balanced_accuracy_std": r["balanced_accuracy_std"],
            "macro_precision_mean": r["macro_precision_mean"], "macro_recall_mean": r["macro_recall_mean"],
            "macro_f1_mean": r["macro_f1_mean"], "macro_f1_std": r["macro_f1_std"],
            "weighted_f1_mean": r["weighted_f1_mean"], "weighted_f1_std": r["weighted_f1_std"],
        })
    # include baseline row + ablation
    comp_rows.append({
        "model": "MAJORITY_BASELINE", "rank": "", "folds": "none", "repeats": "none",
        "accuracy_mean": baseline["accuracy_mean"], "accuracy_std": 0.0,
        "balanced_accuracy_mean": baseline["balanced_accuracy_mean"], "balanced_accuracy_std": 0.0,
        "macro_precision_mean": 0.0, "macro_recall_mean": 0.0,
        "macro_f1_mean": 0.0, "macro_f1_std": 0.0,
        "weighted_f1_mean": baseline["weighted_f1_mean"], "weighted_f1_std": 0.0,
    })
    comp_df = pd.DataFrame(comp_rows)
    comp_df.to_csv(ROOT / "benchmarks" / "model_comparison.csv", index=False)

    cv_json = {
        "disclaimer": DISCLAIMER,
        "grouped": True,
        "grouping_unit": "unique symptom vector",
        "n_groups": int(n_groups),
        "n_splits": N_SPLITS,
        "n_repeats": N_REPEATS,
        "repeat_seeds": REPEAT_SEEDS,
        "stratified_group_kfold_feasibility": "each class has >= 5 groups; 5 folds keep every class in every fold",
        "results": results,
    }
    (ROOT / "outputs" / "cross_validation_results.json").write_text(json.dumps(cv_json, indent=2), encoding="utf-8")

    comp_json = {"disclaimer": DISCLAIMER, "comparison": comp_rows}
    (ROOT / "outputs" / "model_comparison.json").write_text(json.dumps(comp_json, indent=2), encoding="utf-8")

    # ---------- HELDOUT PREDICTIONS (repeat 0 / seeds 42..46, each row once) ----------
    held_rows = []
    best_held = all_predictions[best_name]
    for h in best_held:
        for p, ti in zip(h["pred"], h["test"]):
            y_true = y.iloc[ti]
            held_rows.append({"vector_id": group_label.iloc[ti], "true": y_true, "predicted": p,
                              "fold": h["fold"]})
    held_df = pd.DataFrame(held_rows)
    conf_probs = None
    try:
        if hasattr(best_est, "predict_proba"):
            conf_matrix = best_est.predict_proba(X)
            conf = conf_matrix.max(axis=1)
            conf_probs = pd.Series(conf)
    except Exception:
        pass
    if conf_probs is not None:
        held_df["confidence"] = conf_probs.reindex(held_df.index).values
    held_df.to_csv(ROOT / "predictions" / "heldout_predictions.csv", index=False)

    # ---------- SANITY: dataset quality vs Phase 7H ----------
    print("\nDecision inputs (vs majority baseline):")
    print(f" best={comparator['model']} mf1={comparator['macro_f1_mean']:.4f} bacc={comparator['balanced_accuracy_mean']:.4f} acc={comparator['accuracy_mean']:.4f}")
    print(f" baseline acc={majority_frac:.4f} bacc={1/len(CLASSES):.4f} mf1=0")
    print(f" zero-recall classes (best): {len(zero_recall)} {zero_recall[:5]}")
    print(f" winner_status: {winner_status}")
    print(f" saved model: {model_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())