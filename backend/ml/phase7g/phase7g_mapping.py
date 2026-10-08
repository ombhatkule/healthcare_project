"""
Phase 7G Step 12 — Symptom feature mapping analysis (READ-ONLY).
Compares candidate symptom columns vs current 174-symptom vocabulary.
Categorizes: exact match / possible match (manual review) / no match / non-symptom.
NO modification of symptom_columns.joblib. NO forced mappings.
"""
import json
import joblib
import pandas as pd
from pathlib import Path

BASE = Path(__file__).parent
MODEL = BASE.parent / "model" / "symptom_columns.joblib"
ACQ = BASE / "acquired" / "symbipredict_2022.csv"

current_vocab = joblib.load(MODEL)  # list of 174 'symptom_*' / 'rare_symptom_*' names

# Normalize current vocab to bare symptom tokens
def bare(name):
    return name.replace("symptom_", "").replace("rare_symptom_", "").rstrip("_rare").strip()

current_bare = {bare(c): c for c in current_vocab}

df = pd.read_csv(ACQ)
target = "prognosis"
cand_cols = [c for c in df.columns if c != target]

# Normalize candidate column names (trim spaces, underscores)
def norm(c):
    return c.strip().replace(" ", "_").replace(" ", "").lower()

categories = {"exact_match": [], "possible_match_manual_review": [], "no_match": [], "non_symptom": []}

# Known possible synonyms (careful, conservative, flagged for manual review — NOT auto-merged)
# We only auto-classify EXACT matches; everything else is "no match" or flagged possible for review.
possible_syn = {
    "breathlessness": ["shortness_of_breath", "breathlessness", "dyspnea"],
    "cough": ["cough", "dry_cough", "productive_cough"],
    "fatigue": ["fatigue", "tiredness", "lethargy"],
    "chest_pain": ["chest_pain", "chest_tightness"],
    "headache": ["headache"],
    "nausea": ["nausea"],
    "vomiting": ["vomiting"],
    "pain_belly": ["abdominal_pain", "belly_pain", "stomach_pain"],
    "abdominal_pain": ["abdominal_pain", "belly_pain", "stomach_pain"],
    "muscle_pain": ["muscle_pain"],
}

# First pass: exact semantic match (normalized name present in current bare vocab)
matched = 0
for c in cand_cols:
    if c == target:
        continue
    cnorm = norm(c)
    exact = current_bare.get(cnorm)
    if exact is not None:
        categories["exact_match"].append({"candidate": c, "current": exact, "type": "exact"})
        matched += 1
    else:
        # check possible synonyms against current bare set
        found = False
        for cand_key, syns in possible_syn.items():
            if cnorm in syns or cnorm == cand_key:
                hits = [s for s in syns if s in current_bare]
                if hits:
                    categories["possible_match_manual_review"].append(
                        {"candidate": c, "possible_current": [current_bare[h] for h in hits], "type": "possible"})
                    found = True
                    break
        if not found:
            categories["no_match"].append({"candidate": c, "type": "no match"})

# Non-symptom features (identifiers, demographics) — none in this set besides target handled.

result = {
    "current_vocab_size": len(current_vocab),
    "candidate_symptom_columns": len(cand_cols),
    "summary": {
        "exact_match": len(categories["exact_match"]),
        "possible_match_manual_review": len(categories["possible_match_manual_review"]),
        "no_match": len(categories["no_match"]),
        "non_symptom": len(categories["non_symptom"]),
    },
    "categories": categories,
}
with open(BASE / "symptom_mapping_data.json", 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2)

print("current_vocab_size:", len(current_vocab))
print("candidate_symptom_columns:", len(cand_cols))
print("summary:", result["summary"])
print("\nEXACT MATCHES:")
for m in categories["exact_match"]:
    print(f"  {m['candidate']}  ->  {m['current']}")
print("\nPOSSIBLE (MANUAL REVIEW):")
for m in categories["possible_match_manual_review"]:
    print(f"  {m['candidate']}  ->  {m['possible_current']}")
print("\nDONE — symptom_mapping_data.json")
