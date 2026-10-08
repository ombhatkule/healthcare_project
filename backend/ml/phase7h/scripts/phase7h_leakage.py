"""
Phase 7H Step 12 — Data leakage analysis + recommended train/test strategy.
No model training. Deterministic. Outputs:
  analysis/leakage_analysis.json
  reports/train_test_strategy.md
"""
import json
from pathlib import Path

import pandas as pd

BASE = Path(__file__).resolve().parent.parent
CLEANED = BASE / "cleaned" / "symbipredict_cleaned.csv"
OUT_JSON = BASE / "analysis" / "leakage_analysis.json"
OUT_MD = BASE / "reports" / "train_test_strategy.md"

TARGET = "prognosis"


def main() -> None:
    df = pd.read_csv(CLEANED)
    feat = [c for c in df.columns if c != TARGET]
    key = df[feat].astype(str).apply(lambda s: s.str.cat(sep="|"), axis=1)

    vc = key.value_counts()
    mult = vc[vc > 1]
    n_vectors = int(mult.size)
    all_vectors = int(key.nunique())

    # expected identical-pattern leakage under a naive 80/20 random row split:
    # rows in test that share a vector with train rows
    rows_in_multi = int(mult.sum())
    pct_rows_in_multi = round(100.0 * rows_in_multi / len(df), 2)

    analysis = {
        "description": (
            "Repeated rows are exact repeats of the same symptom vector. Random row-level "
            "train/test splitting places identical vectors on BOTH sides -> identical "
            "information appears in train and test -> overly optimistic evaluation."
        ),
        "unique_vectors_total": all_vectors,
        "vectors_repeated_more_than_once": n_vectors,
        "rows_residing_in_repeated_vectors": rows_in_multi,
        "percent_rows_in_repeated_vectors": pct_rows_in_multi,
        "max_multiplicity": int(vc.max()),
        "multiplicity_distribution": {str(int(k)): int(v) for k, v in vc.value_counts().items()},
        "per_class_vectors": {
            str(d): int(pd.Series(key[df[TARGET] == d].values).nunique()) for d in sorted(df[TARGET].unique())
        },
        "recommended_strategy": {
            "representation": "C_unique_vector_disease_associations (304 rows)",
            "split": (
                "GROUPED split by unique symptom vector (LeaveOneVectorOut / GroupKFold-like): "
                "assign each unique vector to exactly one fold; NEVER split identical vectors "
                "across folds. With 5-10 vectors per class, use repeated grouped CV "
                "(e.g., 5-fold grouped, repeated 10x) and report macro metrics + per-class "
                "support. Because classes have only 5-10 association vectors, small-dataset "
                "uncertainty is expected and must be reported."
            ),
            "avoid": (
                "Random row-level split on the 4,961-row file (would leak identical vectors), "
                "and any split that lets a vector appear in both train and test."
            ),
            "evaluation_limitations": (
                "41 classes but only 304 total association vectors -> evaluation is inherently "
                "small-sample; treat results as exploratory, not clinical."
            ),
        },
    }
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(analysis, f, indent=2, default=str)

    md = [
        "# Phase 7H — Recommended Train/Test Strategy",
        "",
        "## Leakage risk",
        f"- {all_vectors} unique symptom vectors; **every one appears multiple times** in the 4,961-row file.",
        f"- {rows_in_multi} of 4,961 rows ({pct_rows_in_multi}%) are exact repeats of another row.",
        "- Naive random row-level split puts identical vectors in train and test → **information leakage** →",
        "  unusably optimistic evaluation.",
        "",
        "## Recommended strategy (for Phase 7I)",
        "1. **Use representation C** (`cleaned/symbipredict_deduplicated.csv`, 304 association rows).",
        "2. **Grouped split by unique symptom vector** — each vector assigned to exactly one fold.",
        "3. Repeated grouped CV (5-fold grouped, repeated 10x) due to only 5-10 vectors/class.",
        "4. Report macro-averaged metrics AND per-class support counts.",
        "5. Treat all numbers as **exploratory** (small sample, community-curated associations).",
        "6. Do NOT report as diagnostic/clinical performance.",
        "",
        "Machine data: `analysis/leakage_analysis.json`",
    ]
    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")

    print("=== LEAKAGE ===")
    print(f"  unique vectors: {all_vectors}")
    print(f"  vectors repeated >1x: {n_vectors} (100% of unique vectors)")
    print(f"  rows in repeats: {rows_in_multi} ({pct_rows_in_multi}%)")
    print(f"  max multiplicity: {int(vc.max())}")
    print("  strategy: grouped split by unique vector on the 304-row association representation")
    print("DONE -> analysis/leakage_analysis.json, reports/train_test_strategy.md")


if __name__ == "__main__":
    main()