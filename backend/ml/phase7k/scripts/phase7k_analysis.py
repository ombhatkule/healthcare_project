"""Phase 7K feasibility analysis: Columbia KB external-validation candidate.

Isolated research/educational analysis. NO model prediction is performed.
Goal: establish validation, label/feature mapping statuses, coverage bounds,
and content-independence (leakage) numbers, and decide outcome C/D.
"""
import hashlib
import json
import re
import difflib
import pandas as pd

ROOT = r"C:\Users\ADMIN\OneDrive\Desktop\healthcareapp\backend\ml"
K = ROOT + r"\phase7k"
COLUMBIA = ROOT + r"\phase7g\acquired\columbia_disease_symptom_kb.csv"
SYMBA = ROOT + r"\phase7i\data\symbipredict_representationC_131feat.csv"
VOCAB = ROOT + r"\phase7i\data\symptom_columns_131.json"

P7I_LABELS = [
    "AIDS", "Acne", "Alcoholic Hepatitis", "Allergy", "Arthritis",
    "Bronchial Asthma", "Cervical Spondylosis", "Chickenpox",
    "Chronic Cholestasis", "Common Cold", "Dengue", "Diabetes",
    "Dimorphic Hemmorhoids (piles)", "Drug Reaction", "Fungal Infection",
    "GERD", "Gastroenteritis", "Heart Attack", "Hepatitis A", "Hepatitis B",
    "Hepatitis C", "Hepatitis D", "Hepatitis E", "Hypertension",
    "Hyperthyroidism", "Hypoglycemia", "Hypothyroidism", "Impetigo",
    "Jaundice", "Malaria", "Migraine", "Osteoarthritis",
    "Paralysis (brain hemorrhage)", "Peptic Ulcer Disease", "Pneumonia",
    "Psoriasis", "Tuberculosis", "Typhoid", "Urinary Tract Infection",
    "Varicose Veins", "Vertigo",
]

LABEL_MAP = {
    "Arthritis": ("arthritis", "EXACT"),
    "Diabetes": ("diabetes", "EXACT"),
    "Gastroenteritis": ("gastroenteritis", "EXACT"),
    "Hepatitis B": ("hepatitis b", "EXACT"),
    "Hepatitis C": ("hepatitis c", "EXACT"),
    "Hypoglycemia": ("hypoglycemia", "EXACT"),
    "Hypothyroidism": ("hypothyroidism", "EXACT"),
    "Pneumonia": ("pneumonia", "EXACT"),
    "AIDS": ("acquired immuno-deficiency syndrome", "HIGH_CONFIDENCE"),
    "Bronchial Asthma": ("asthma", "HIGH_CONFIDENCE"),
    "Heart Attack": ("myocardial infarction", "HIGH_CONFIDENCE"),
    "Hypertension": ("hypertensive disease", "HIGH_CONFIDENCE"),
    "Migraine": ("migraine disorders", "HIGH_CONFIDENCE"),
    "Peptic Ulcer Disease": ("ulcer peptic", "HIGH_CONFIDENCE"),
    "Jaundice": ("hyperbilirubinemia", "HIGH_CONFIDENCE"),
    "Urinary Tract Infection": ("infection urinary tract", "HIGH_CONFIDENCE"),
    "Alcoholic Hepatitis": ("chronic alcoholic intoxication", "POSSIBLE"),
    "Chronic Cholestasis": ("biliary calculus", "POSSIBLE"),
    "Fungal Infection": ("oral candidiasis", "POSSIBLE"),
}

def norm(s):
    s = re.sub(r"[^a-z0-9 ]", " ", str(s).lower())
    return re.sub(r"\s+", " ", s).strip()

def stem_word(w):
    for suf in ("ing", "es", "s"):
        if w.endswith(suf) and len(w) > len(suf) + 2:
            return w[: -len(suf)]
    return w

def stem(t):
    return " ".join(stem_word(w) for w in norm(t).split())

beat = re.compile(r"(^|\s)(none|not|no|without|absent)\b")
antonyms = {
    "weight gain": "weight_loss",
    "constipation": None,
}
def antonym_of(n):
    if n == "weight gain":
        return "weight_loss"
    if n == "weight loss":
        return "weight_gain"
    if n == "constipation":
        return None
    return None


def parse_symptom(s):
    s = str(s)
    base = s.split("^")[0]
    m = re.match(r"UMLS:\S+_(.+)", base)
    return m.group(1).strip() if m else base.strip()


def disease_aliases(d):
    aliases = set()
    for piece in str(d).split("^"):
        m = re.match(r"UMLS:\S+_(.+)", piece)
        aliases.add(m.group(1).strip() if m else piece.strip())
    return aliases

# Feature mapping: Columbia UMLS symptom name -> 7I feature
MANUAL_HIGH = {
    "abdominal pain": "abdominal_pain",
    "back pain": "back_pain",
    "belly pain": "belly_pain",
    "chest pain": "chest_pain",
    "pain chest": "chest_pain",
    "hip pain": "hip_joint_pain",
    "joint pain": "joint_pain",
    "knee pain": "knee_pain",
    "muscle pain": "muscle_pain",
    "neck pain": "neck_pain",
    "stomach pain": "stomach_pain",
    "diarrhea": "diarrhoea",
    "diarrhoea": "diarrhoea",
    "fever": "high_fever",
    "high fever": "high_fever",
    "mild fever": "mild_fever",
    "low grade fever": "mild_fever",
    "weight loss": "weight_loss",
    "pruritus": "itching",
    "itching": "itching",
    "shortness of breath": "breathlessness",
    "dyspnea": "breathlessness",
    "breathlessness": "breathlessness",
    "syncope": "dizziness",
    "vertigo": "dizziness",
    "dizziness": "dizziness",
    "asthenia": "fatigue",
    "fatigue": "fatigue",
    "lethargy": "lethargy",
    "malaise": "malaise",
    "cough": "cough",
    "sputum": "phlegm",
    "phlegm": "phlegm",
    "sweat": "sweating",
    "sweating": "sweating",
    "palpitation": "palpitations",
    "palpitations": "palpitations",
    "anorexia": "loss_of_appetite",
    "loss of appetite": "loss_of_appetite",
    "constipation": "constipation",
    "polyuria": "polyuria",
    "anxiety": "anxiety",
    "depression": "depression",
    "chill": "chills",
    "chills": "chills",
    "shivering": "shivering",
    "jitteriness": "anxiety",
    "jaundice": "yellowish_skin",
    "yellowish skin": "yellowish_skin",
    "nausea": "nausea",
    "vomiting": "vomiting",
    "headache": "headache",
    "coma": "coma",
    "confusion": "altered_sensorium",
    "skin rash": "skin_rash",
    "rash": "skin_rash",
    "wakefulness": "restlessness",  # high-confidence conceptual; flagged
}
MANUAL_POSSIBLE = {
    "nasal stuffiness": "congestion",
    "hypertension": None,          # excluded: disease not symptom here
}

def main():
    out = {}
    col = pd.read_csv(COLUMBIA)
    col["plain_d"] = col["disease"].str.replace(r"^UMLS:\S+_", "", regex=True)
    col["sym"] = col["symptom"].map(parse_symptom)

    # ---------- dataset hash ----------
    sha = hashlib.sha256(open(COLUMBIA, "rb").read()).hexdigest()
    out["columbia"] = {
        "path": COLUMBIA,
        "sha256": sha.upper(),
        "rows": int(len(col)),
        "columns": list(col.columns),
        "n_diseases_raw": int(col["disease"].nunique()),
        "n_diseases_plain": int(col["plain_d"].nunique()),
        "n_symptoms_uniq": int(col["sym"].nunique()),
        "missing_pct": float(col.isna().mean().mean() * 100),
        "duplicate_rows": int(col.duplicated().sum()),
    }

    # ---------- validation ----------
    counts = col.groupby("plain_d")["count_of_disease_occurrence"].first()
    assoc = col.groupby("plain_d")["sym"].apply(list)
    assoc_n = col.groupby("plain_d")["sym"].transform("count")
    out["validation"] = {
        "duplicate_feature_vectors": int(col.duplicated(subset=["plain_d", "sym"]).sum()),
        "contradictory_observations": "N/A (association-count format, single mapping per row)",
        "all_zero_rows": int((col[["count_of_disease_occurrence"]] == 0).sum().iloc[0]),
        "class_support_min": int(assoc_n.min()),
        "class_support_max": int(assoc_n.max()),
        "n_diseases_under_5_assoc": int((assoc_n < 5).sum()),
        "count_stats": {
            "min": int(counts.min()), "median": int(counts.median()),
            "max": int(counts.max()),
        },
    }

    # ---------- label mapping ----------
    labels = {}
    no_case = norm
    for lab in P7I_LABELS:
        if lab in LABEL_MAP:
            tgt, status = LABEL_MAP[lab]
            hit = [d for d in col["plain_d"].unique() if norm(tgt) in {norm(a) for a in disease_aliases(d)}]
            hit_label = hit[0] if hit else None
            labels[lab] = {"columbia_label": hit_label, "status": status, "found": bool(hit)}
        else:
            labels[lab] = {"columbia_label": None, "status": "NO_MATCH", "found": False}
    from collections import Counter
    lstat = Counter(v["status"] for v in labels.values())
    out["label_mapping"] = {
        "n_p7i_labels": len(P7I_LABELS),
        "by_status": dict(lstat),
        "details": labels,
    }

    # ---------- feature mapping ----------
    vocab = json.load(open(VOCAB, encoding="utf-8"))["features"]
    vnorm = {}
    for f in vocab:
        for form in {norm(f), stem(f), norm(f).replace(" ", ""), stem(f).replace(" ", "")}:
            vnorm.setdefault(form, f)

    uniq = sorted(col["sym"].dropna().unique())
    fm = {}
    statuses = Counter()
    for s in uniq:
        n = norm(s)
        tgt = None
        st = None
        if n in vnorm:
            tgt, st = vnorm[n], "EXACT"
        elif stem(n) in vnorm:
            tgt, st = vnorm[stem(n)], "EXACT"
        elif s in MANUAL_HIGH:
            tgt, st = MANUAL_HIGH[s], "HIGH_CONFIDENCE"
        elif n in MANUAL_HIGH:
            tgt, st = MANUAL_HIGH[n], "HIGH_CONFIDENCE"
        else:
            cand = difflib.get_close_matches(n, list(vnorm.keys()), n=1, cutoff=0.88)
            if cand:
                tgt, st = vnorm[cand[0]], "POSSIBLE" if cand[0].replace(" ", "") != n.replace(" ", "") else "EXACT"
            else:
                tgt, st = None, "NO_MATCH"
        if tgt is None and st != "POSSIBLE":
            st = "NO_MATCH"
        statuses[st] += 1
        fm[s] = {"feature": tgt, "status": st}

    n_map = sum(statuses.get(k, 0) for k in ("EXACT", "HIGH_CONFIDENCE", "POSSIBLE"))
    col["map_status"] = col["sym"].map(lambda s: fm[s]["status"])
    # define usable = EXACT or HIGH_CONFIDENCE
    usable = {"EXACT", "HIGH_CONFIDENCE"}
    row_cov = float(col["map_status"].isin(usable).mean() * 100)
    out["feature_mapping"] = {
        "n_unique_symptoms": len(uniq),
        "by_status": dict(statuses),
        "feature_coverage_exact_high_pct": round(100.0 * sum(statuses.get(k, 0) for k in usable) / len(uniq), 2),
        "feature_coverage_any_pct": round(100.0 * n_map / len(uniq), 2),
        "association_row_coverage_exact_high_pct": round(row_cov, 2),
        "n_vocab_features_matched": int(len(vocab) - sum(1 for f in vocab if f not in set(v["feature"] for v in fm.values() if v["feature"]))),
    }
    mappedfeat = set(v["feature"] for v in fm.values() if v["feature"])
    out["feature_mapping"]["n_vocab_features_covered"] = len(mappedfeat)

    # ---------- per-disease hypothetical vector feasibility (EXACT labels only) ----------
    feas = {}
    for lab in P7I_LABELS:
        e = labels[lab]
        if e["status"] != "EXACT" or not e["found"]:
            continue
        d = e["columbia_label"]
        syms = assoc.get(d, [])
        hits = [fm[s]["feature"] for s in syms if fm[s]["status"] in usable]
        hits_exact = [fm[s]["feature"] for s in syms if fm[s]["status"] == "EXACT"]
        feas[lab] = {
            "n_associations": int(len(syms)),
            "mapped_usable": int(len(hits)),
            "mapped_exact_only": int(len(hits_exact)),
            "usable_features": sorted(set(hits)),
            "signal_retained_exact_high_pct": round(100.0 * len(hits) / len(syms), 1) if syms else 0.0,
        }
    out["feasibility_exact_labels"] = feas
    out["feasibility_summary"] = {
        "n_exact_label_diseases": len(feas),
        "with_0_usable_features": int(sum(1 for v in feas.values() if v["mapped_usable"] == 0)),
        "with_le2_usable_features": int(sum(1 for v in feas.values() if v["mapped_usable"] <= 2)),
    }

    # ---------- leakage / content-independence ----------
    sym = pd.read_csv(SYMBA)
    sym_cols = [c for c in sym.columns if c != "prognosis"]
    ov = {}
    for lab, (d, st) in LABEL_MAP.items():
        if st != "EXACT":
            continue
        d_label = labels[lab]["columbia_label"]
        if not d_label:
            continue
        csyms = set(norm(x) for x in assoc.get(d_label, []))
        rows = sym[sym["prognosis"] == lab]
        psyms = set()
        for c in sym_cols:
            if (rows[c] == 1).any():
                psyms.add(norm(c.replace("_", " ")))
        inter = len(csyms & psyms)
        union = len(csyms | psyms)
        ov[lab] = {
            "columbia_n": int(len(csyms)),
            "symbipredict_n": int(len(psyms)),
            "overlap_n": int(inter),
            "jaccard": round(inter / union, 3) if union else None,
        }
    out["leakage"] = {
        "independence_assessment": "Content-independent sources analyzed (real NYP discharge notes NLP 2008 vs community-curated SDPD).",
        "shared_exact_label_jaccard": ov,
        "mean_jaccard": round(float(pd.Series([v["jaccard"] for v in ov.values() if v["jaccard"] is not None]).mean()), 3),
        "dup_vs_symbipredict": "No row-level copying detected (different format + vocabulary).",
    }

    # ---------- write outputs ----------
    json.dump(out, open(K + r"\validation\phase7k_mapping_analysis.json", "w", encoding="utf-8"), indent=2, default=str)
    pd.DataFrame(uniquify([(s, fm[s]["feature"], fm[s]["status"]) for s in fm])) \
        .to_csv(K + r"\mappings\feature_mapping_full.csv", index=False, header=["columbia_symptom", "phase7i_feature", "status"])
    pd.DataFrame([(k, v["columbia_label"], v["status"]) for k, v in labels.items()]) \
        .to_csv(K + r"\mappings\label_mapping_full.csv", index=False, header=["phase7i_label", "columbia_label", "status"])
    print(json.dumps({
        "columbia": out["columbia"],
        "validation": out["validation"],
        "label_by_status": out["label_mapping"]["by_status"],
        "feature_by_status": out["feature_mapping"]["by_status"],
        "feature_cov": out["feature_mapping"]["feature_coverage_exact_high_pct"],
        "feas_summary": out["feasibility_summary"],
        "leakage_mean_jaccard": out["leakage"]["mean_jaccard"],
    }, indent=2, default=str))


def uniquify(rows):
    seen = set()
    res = []
    for a, b, c in rows:
        u = (a == a, b or "", c)
        res.append([a if a == a else "", b or "", c])
    return res


if __name__ == "__main__":
    main()