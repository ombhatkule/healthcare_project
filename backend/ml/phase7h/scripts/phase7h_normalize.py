"""
Phase 7H Steps 7, 8, 10 — Column-name normalization, label normalization,
collision detection, and creation of cleaned candidate datasets.
Deterministic. Raw source never modified.
Outputs:
  analysis/column_normalization.json
  analysis/label_normalization.json
  cleaned/symbipredict_cleaned.csv          (full 4961 rows, normalized names)
  cleaned/symbipredict_deduplicated.csv     (unique vector+disease pairs, normalized names)
"""
import json
import re
from pathlib import Path

import pandas as pd

BASE = Path(__file__).resolve().parent.parent
SRC = BASE.parent / "phase7g" / "acquired" / "symbipredict_2022.csv"
OUT_COL = BASE / "analysis" / "column_normalization.json"
OUT_LAB = BASE / "analysis" / "label_normalization.json"
OUT_CLN = BASE / "cleaned" / "symbipredict_cleaned.csv"
OUT_DED = BASE / "cleaned" / "symbipredict_deduplicated.csv"

TARGET = "prognosis"


def normalize_name(s: str) -> str:
    v = str(s).strip().lower()
    v = re.sub(r"[^a-z0-9_]+", "_", v)
    v = re.sub(r"_+", "_", v).strip("_")
    return v


def main() -> None:
    df = pd.read_csv(SRC)
    feat_cols = [c for c in df.columns if c != TARGET]

    # ---- Step 7: column normalization + collision detection ----
    norm = {}
    for c in feat_cols:
        norm[str(c)] = normalize_name(c)

    from collections import defaultdict
    groups = defaultdict(list)
    for orig, n in norm.items():
        groups[n].append(orig)

    collisions = {n: origs for n, origs in groups.items() if len(origs) > 1}

    collision_investigation = {}
    for n, origs in collisions.items():
        cols = [c for c in feat_cols if str(c) in origs]
        if len(cols) < 2:
            continue
        a, b = cols[0], cols[1]
        identical = bool((df[a] == df[b]).all())
        collision_investigation[n] = {
            "original_columns": origs,
            "identical_data": identical,
            "same_semantic_meaning_evidence": identical,
            "decision": (
                "both retained with distinct normalized names (no silent merge);"
                + (" columns contain identical data - duplicate column names from source header"
                   if identical else " columns differ - genuine collision requiring manual review")
            ),
        }

    # Build final normalization: keep both colliding cols distinct with suffix.
    used = set()
    final_norm = {}
    for orig, n in norm.items():
        cnt = 0
        cand = n
        while cand in used:
            cnt += 1
            cand = f"{n}_dup{cnt}"
        used.add(cand)
        final_norm[str(orig)] = cand

    # ---- Step 8: label normalization + collision detection ----
    labels = sorted(df[TARGET].dropna().unique().tolist())
    label_norm = {}
    for lab in labels:
        nl = str(lab).strip()
        nl = re.sub(r"\s+", " ", nl)
        label_norm[str(lab)] = nl
    lg = defaultdict(list)
    for o, n in label_norm.items():
        lg[n].append(o)
    label_collisions = {n: o for n, o in lg.items() if len(o) > 1}
    label_ambiguous = []  # synonyms not verifiable from source docs -> manual review

    col_doc = {
        "target": TARGET,
        "normalization_rules": [
            "lowercase", "strip whitespace", "spaces->underscore",
            "hyphens->underscore", "remove non [a-z0-9_]", "collapse repeated underscores",
            "strip leading/trailing underscores", "no medical synonyms invented",
            "collision handling: investigation recorded; both columns retained with _dupN suffix",
        ],
        "mapping": final_norm,
        "collisions": collisions,
        "collision_investigation": collision_investigation,
        "duplicate_column_name_suffix_source": (
            "'fluid_overload.1' etc. are pandas '.N' suffixes appended when CSV header "
            "contains duplicate column names"
        ),
    }
    lab_doc = {
        "target": TARGET,
        "original_label_count": len(labels),
        "normalization_rules": ["strip", "collapse internal whitespace"],
        "mapping": label_norm,
        "collisions": label_collisions,
        "ambiguous_labels_for_manual_review": label_ambiguous,
    }

    with open(OUT_COL, "w", encoding="utf-8") as f:
        json.dump(col_doc, f, indent=2, default=str)
    with open(OUT_LAB, "w", encoding="utf-8") as f:
        json.dump(lab_doc, f, indent=2, default=str)

    # ---- Step 10: build cleaned datasets ----
    out = df.rename(columns={c: final_norm[str(c)] for c in feat_cols})
    out = out.copy()
    if TARGET in out.columns:
        out[TARGET] = out[TARGET].map(label_norm)

    vec_cols = [final_norm[str(c)] for c in feat_cols]
    ded = out.drop_duplicates(subset=vec_cols + [TARGET])

    out.to_csv(OUT_CLN, index=False)
    ded.to_csv(OUT_DED, index=False)

    print("=== NORMALIZATION ===")
    print(f"  feature columns normalized: {len(final_norm)}")
    print(f"  columns with normalized-collision: {len(collisions)}")
    for n, o in collisions.items():
        print(f"    '{n}' <- {o}  identical_data={collision_investigation[n]['identical_data']}")
    print(f"  labels normalized: {len(label_norm)} / colliding: {len(label_collisions)}")
    print(f"  cleaned rows (full)      : {len(out)} -> cleaned/symbipredict_cleaned.csv")
    print(f"  cleaned rows (deduped)   : {len(ded)} -> cleaned/symbipredict_deduplicated.csv")
    print("DONE -> analysis/column_normalization.json, analysis/label_normalization.json, cleaned/*.csv")


if __name__ == "__main__":
    main()