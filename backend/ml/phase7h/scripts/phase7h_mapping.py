"""
Phase 7H Step 9 — Symptom semantic mapping review.
The NEW SymbiPredict vocabulary is primary. The current production dataset vocabulary is
referenced ONLY to classify the candidate's 132 symptoms as
EXACT / HIGH_CONFIDENCE_SYNONYM / POSSIBLE_SYNONYM / AMBIGUOUS / NO_MATCH.
No synonyms are auto-applied; HIGH_CONFIDENCE_SYNONYM are flagged for the candidate
vocabulary. Deterministic. Outputs:
  analysis/symptom_mapping_review.json
  reports/symptom_mapping_review.md
"""
import json
import re
from pathlib import Path

import pandas as pd

BASE = Path(__file__).resolve().parent.parent
CLEANED = BASE / "cleaned" / "symbipredict_cleaned.csv"
CURRENT_SRC = BASE.parent.parent / "data" / "disease_dataset_cleaned_v2.csv"
OUT_JSON = BASE / "analysis" / "symptom_mapping_review.json"
OUT_MD = BASE / "reports" / "symptom_mapping_review.md"

TARGET = "prognosis"

# Curated HIGH_CONFIDENCE_SYNONYM (source: Phase 7G review; medically standard synonyms).
HIGH_CONF = {
    "stomach_pain": "abdominal_pain",
    "belly_pain": "abdominal_pain",
    "breathlessness": "shortness_of_breath",
}

# POSSIBLE_SYNONYM candidates carried from Phase 7G (require manual confirmation).
POSSIBLE_CONF = {
    "joint_pain": "joint_pain_symptom",
    "weight_gain": "weight_gain_symptom",
    "anxiety": "anxiety_symptom",
    "weight_loss": "unintentional_weight_loss",
    "high_fever": "fever",
    "back_pain": "low_back_pain",
    "mild_fever": "fever",
    "congestion": "nasal_congestion",
    "cramps": "muscle_cramps_symptom",
    "bruising": "easy_bruising",
    "drying_and_tingling_lips": "tingling",
}


def norm_current(name: str) -> str:
    v = str(name).lower()
    v = re.sub(r"^symptom_", "", v)
    v = re.sub(r"_symptom$", "", v)
    v = re.sub(r"[^a-z0-9_]+", "_", v).strip("_")
    return v


def norm_candidate(name: str) -> str:
    return re.sub(r"[^a-z0-9_]+", "_", str(name).lower()).strip("_")


def main() -> None:
    df = pd.read_csv(CLEANED)
    cand_names = [c for c in df.columns if c != TARGET]

    cur = pd.read_csv(CURRENT_SRC, nrows=1)
    cur_vocab = {norm_current(c) for c in cur.columns if c != "disease"}

    results = []
    for c in cand_names:
        cn = norm_candidate(c)
        if cn in cur_vocab:
            cls, note = "EXACT", {"current_term": cn}
        elif cn in HIGH_CONF:
            t = HIGH_CONF[cn]
            cls = "HIGH_CONFIDENCE_SYNONYM" if t in cur_vocab or len(norm_candidate(t)) > 0 else "HIGH_CONFIDENCE_SYNONYM"
            note = {"proposed_synonym": t, "in_current_vocab": t in cur_vocab}
        elif cn in POSSIBLE_CONF:
            t = POSSIBLE_CONF[cn]
            cls = "POSSIBLE_SYNONYM"
            note = {"candidate_synonym": t, "in_current_vocab": t in cur_vocab}
        else:
            cls, note = "NO_MATCH", {"in_current_vocab": False}
        results.append({"candidate_symptom": c, "normalized": cn, "classification": cls, **note})

    from collections import Counter
    summary = Counter(r["classification"] for r in results)

    out = {
        "method": (
            "candidate-centric: 132 candidate symptoms classified against current v2 vocab "
            "(normalized). Current vocab is NOT authoritative; used only for intersection analysis."
        ),
        "high_confidence_synonyms_considered_for_candidate_vocab": list(HIGH_CONF.keys()),
        "possible_synonyms_requiring_manual_confirmation": list(POSSIBLE_CONF.keys()),
        "summary": dict(summary),
        "items": results,
    }
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2, default=str)

    md = ["# Phase 7H — Symptom Semantic Mapping Review",
          "",
          "The **SymbiPredict vocabulary is primary**. The current production v2 vocabulary is referenced",
          "only to classify each candidate symptom. No synonym is auto-applied to the candidate dataset.",
          "",
          f"## Summary",
          "",
          "| Classification | Count |",
          "|---|---|",
          *[f"| {k} | {v} |" for k, v in sorted(summary.items(), key=lambda x: x[0])],
          "",
          "## HIGH_CONFIDENCE_SYNONYM (proposed additions to candidate vocabulary)",
          "",
          "| Candidate symptom | Proposed canonical term |",
          "|---|---|",
          *[f"| {c} | {HIGH_CONF[c]} |" for c in HIGH_CONF],
          "",
          "## POSSIBLE_SYNONYM (manual confirmation required)",
          "",
          "| Candidate symptom | Candidate synonym |",
          "|---|---|",
          *[f"| {c} | {POSSIBLE_CONF[c]} |" for c in POSSIBLE_CONF],
          "",
          "## NO_MATCH count", f"{summary.get('NO_MATCH',0)} candidate symptoms are new vocabulary.",
          "",
          "Machine data: `analysis/symptom_mapping_review.json`",
          ]
    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")

    print("=== SYMPTOM MAPPING REVIEW ===")
    for k, v in sorted(summary.items()):
        print(f"  {k}: {v}")
    print("DONE")


if __name__ == "__main__":
    main()