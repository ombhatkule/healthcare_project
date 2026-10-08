"""Phase 7K evidence generation: registry, hashes, counts, evaluation record."""
import hashlib
import json
import os

ROOT = r"C:\Users\ADMIN\OneDrive\Desktop\healthcareapp\backend\ml"
K = ROOT + r"\phase7k"
G = ROOT + r"\phase7g\acquired"

def sha256(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest().upper()

# ---------- candidate registry (investigated, incl. web-search findings) ----------
registry = {
    "phase": "7K",
    "note": "Candidate datasets investigated for independent external validation of the Phase 7I experimental model. "
            "Downloads were NOT performed in 7K; the three locally-held files below were already acquired (Phase 7G) and are re-analyzed. "
            "Web-search candidates are documented with their recorded limitations.",
    "investigated": 9,
    "candidates": [
        {
            "id": "COL-001", "name": "Columbia University Disease-Symptom Knowledge Database",
            "source": "Columbia DBMI; extracted from 25,074 NYP 2004 discharge summaries via MedLEE NLP; UMLS-coded (AMIA 2008, PMC2656103)",
            "license": "UNKNOWN - no explicit license statement; manual review required (contact friedman@dbmi.columbia.edu)",
            "observations": "1,858 disease->symptom associations (count-weighted), 134 diseases, 397 symptoms",
            "observation_type": "aggregated clinical associations (real discharge-note origin), NOT case/patient-level rows",
            "label_overlap_41": "8 EXACT / 8 HIGH_CONFIDENCE / 3 POSSIBLE / 22 NO_MATCH",
            "feature_coverage": "14/397 EXACT (3.53%), 24/397 with HIGH_CONFIDENCE (6.05%) vs 131-vocab",
            "status": "ANALYZED ONLY - CONDITIONAL CANDIDATE (license pending; insufficient feature/label coverage)",
        },
        {
            "id": "KAU-001", "name": "Kaushil268 - Disease Prediction using Machine Learning (Kaggle)",
            "source": "Kaggle dataset kaushil268; fetched Phase 7G via public GitHub raw mirror; Apache-2.0",
            "license": "Apache-2.0",
            "observations": "4,920 rows / 41 diseases / 17 symptom columns (Symptom_1..17)",
            "observation_type": "canonical symptom->disease KB rows (same family as SymbiPredict; 304 unique signatures)",
            "label_overlap_41": "essentially all 41 (mirror disease family)",
            "feature_coverage": "full (same vocabulary)",
            "status": "REJECTED for 7K - SAME canonical family as SymbiPredict -> NOT independent (mirror/leakage risk). Approved only in Phase 7G as a cross-check mirror.",
        },
        {
            "id": "SYM-001", "name": "SymbiPredict / SDPD (Mendeley)",
            "source": "Mendeley Data DOI 10.17632/dv5z3v2xyd.1; CC-BY-4.0",
            "license": "CC BY 4.0",
            "observations": "4,961 rows (41 classes x 121) -> 304 unique signatures used in Phase 7I",
            "observation_type": "canonical community-curated associations, NOT patient records",
            "status": "REJECTED for 7K - THIS IS THE TRAINING SOURCE (Phase 7I); cannot be used as external validation (in-sample).",
        },
        {
            "id": "KAG-800", "name": "Disease and Symptoms dataset (~800 diseases, 600 symptoms; Kaggle choongqianzheng + variants)",
            "source": "Kaggle; Disease Prediction Using Machine Learning family",
            "license": "Other (specified in description) / unspecified authorship",
            "observations": "~5,000 rows, 800+ diseases, 18 cols",
            "observation_type": "canonical symptom->disease associations, NOT patient-level",
            "status": "REJECTED for 7K - SAME canonical disease-symptom KB family as SymbiPredict -> not independent; undocumented provenance.",
        },
        {
            "id": "KAG-773", "name": "Disease-Symptom Dataset (773 diseases / 377 symptoms; Kaggle dhivyeshrk) + Mendeley 'Disease and symptoms dataset 2023' (246k rows)",
            "source": "Kaggle dhivyeshrk; Mendeley DOI 10.17632/2cxccsxydc.1 (Lombardo 2025)",
            "license": "CC BY 4.0 (Mendeley)",
            "observations": "~246,000 rows; 773 diseases; 377 symptoms",
            "observation_type": "ARTIFICIALLY GENERATED symptom->disease rows (self-described), preserving 'Symptom Severity and Disease Occurrence Possibility'",
            "status": "REJECTED for 7K - synthetic/generated rows describing canonical KB associations; not independent real observations; speculative coverage.",
        },
        {
            "id": "DDX-001", "name": "DDXPlus (1.3M synthetic patients, 49 pathologies, 110 symptoms)",
            "source": "Tchango et al., NeurIPS 2022 / figshare 20043374; synthea+proprietary KB",
            "license": "figshare terms; research use documented in paper",
            "observations": "~1,300,000 synthetic patients; 49 pathologies; 110 binary/categorical symptoms + antecedents",
            "observation_type": "SYNTHETIC patients generated from a medical KB (Synthea); not real clinical observations",
            "label_overlap_41": "~5 (subset of symptom-based diseases)",
            "feature_coverage": "limited/requires mapping; categorical+multi-choice (not binary 0/1)",
            "status": "REJECTED for 7K - synthetic cohort, not independent real observations; feature representation (categorical, negative framing) incompatible with lean binary prerequisite; large acquisition not justified.",
        },
        {
            "id": "BR-DENGUE", "name": "Brazil SINAN dengue/chikungunya/SARI notifications (PMC12819417, 2025)",
            "source": "Brazilian epidemiological surveillance (SINAN); Scientific Data description",
            "license": "CC BY (dataset via article/content)",
            "observations": "case-level records (dengue, chikungunya) with binary symptom columns (fever, headache, rash, nausea, vomiting, arthralgia, myalgia, retro-orbital pain...)",
            "observation_type": "REAL case-level clinical notifications",
            "label_overlap_41": "1 disease (Dengue) out of 41",
            "feature_coverage": "~8-12 features overlap 131-vocab",
            "status": "REJECTED for 7K - real but single-disease; class coverage ~2.4% is too small to support a 41-class generalization claim.",
        },
        {
            "id": "HCMC-DENGUE", "name": "OUCRU Ho Chi Minh City dengue cohort (12,000+ patients, 1999-2021)",
            "source": "Oxford Univ Clinical Research Unit; PMC9992802",
            "license": "data access requires application/permission",
            "observations": ">12,000 real patients, single disease (Dengue), WHO warning-sign categories",
            "observation_type": "REAL patient cohort (hospitalized children)",
            "label_overlap_41": "1 disease",
            "status": "REJECTED for 7K - single-disease; access-restricted; class coverage too small.",
        },
        {
            "id": "MIMIC-III", "name": "MIMIC-III clinical database",
            "source": "MIT Lab / PhysioNet; credentialed access",
            "license": "PhysioNet DUA required",
            "observations": "~40k ICU admissions; structured EHR",
            "observation_type": "REAL patients",
            "label_overlap_41": "labels not aligned to symptom-based 41 classes",
            "feature_coverage": "lacks a ready symptom-presence matrix (per DDXPlus paper: 'often lack symptom-related data')",
            "status": "REJECTED for 7K - no symptom presence matrix; credentialed access; not usable as-is.",
        },
        {
            "id": "S2D-001", "name": "symptoms2Disease (Kaggle niyarrbarman, 24 diseases / 1200 natural-language descriptions)",
            "source": "Kaggle; GitHub bimarshak7 mirror",
            "license": "Kaggle terms (unspecified)",
            "observations": "1,200 rows; 24 diseases; free-text symptom sentences (same disease family)",
            "observation_type": "paraphrased natural-language symptom descriptions; derived from the same known disease-symptom KB family",
            "status": "REJECTED for 7K - paraphrases/derivatives of same canonical family -> not independent; free-text tokens require unsupervised alignment -> mapping inadequate.",
        },
    ],
    "conclusion": "No independently-sourced, patient/case-level, adequately-covered dataset is obtainable. "
                  "Best genuine independent candidate (Columbia KB, real clinical origin) fails license clarity and feature/label coverage; "
                  "all other real datasets are single-disease or unaligned; the large Kaggle/Mendeley sets are the same canonical family or synthetic. "
                  "No external evaluation was performed.",
}

json.dump(registry, open(K + r"\evidence\candidate_registry_7k.json", "w", encoding="utf-8"), indent=2)

# ---------- dataset hashes ----------
dh = {
    "phase7k_analysis_inputs": [
        {"file": "columbia_disease_symptom_kb.csv", "path": G + r"\columbia_disease_symptom_kb.csv", "sha256": sha256(G + r"\columbia_disease_symptom_kb.csv")},
        {"file": "symbipredict_2022.csv (Phase 7I training source - NOT used)", "path": G + r"\symbipredict_2022.csv", "sha256": sha256(G + r"\symbipredict_2022.csv")},
        {"file": "kaushil268_disease_prediction.csv (mirror, NOT used)", "path": G + r"\kaushil268_disease_prediction.csv", "sha256": sha256(G + r"\kaushil268_disease_prediction.csv")},
        {"file": "symbipredict_representationC_131feat.csv (Phase 7I experimental data - reference only)", "path": ROOT + r"\phase7i\data\symbipredict_representationC_131feat.csv", "sha256": sha256(ROOT + r"\phase7i\data\symbipredict_representationC_131feat.csv")},
    ]
}
json.dump(dh, open(K + r"\evidence\dataset_hashes.json", "w", encoding="utf-8"), indent=2)

# ---------- counts ----------
a = json.load(open(K + r"\validation\phase7k_mapping_analysis.json", encoding="utf-8"))
json.dump(a["columbia"], open(K + r"\evidence\dataset_validation.json", "w", encoding="utf-8"), indent=2)
json.dump(a["validation"], open(K + r"\evidence\validation_counts.json", "w", encoding="utf-8"), indent=2)
json.dump(a["label_mapping"], open(K + r"\evidence\mapping_counts_label.json", "w", encoding="utf-8"), indent=2)
json.dump(a["feature_mapping"], open(K + r"\evidence\mapping_counts_feature.json", "w", encoding="utf-8"), indent=2)
json.dump(a["feasibility_exact_labels"], open(K + r"\evidence\coverage_feasibility_per_disease.json", "w", encoding="utf-8"), indent=2)
json.dump(a["feasibility_summary"], open(K + r"\evidence\coverage_summary.json", "w", encoding="utf-8"), indent=2)
json.dump(a["leakage"], open(K + r"\evidence\leakage_check.json", "w", encoding="utf-8"), indent=2)

eval_rec = {
    "phase": "7K",
    "external_evaluation_performed": False,
    "reason": "No valid external evaluation is possible: (1) the only independent clinically-sourced candidate "
              "(Columbia KB) is license-pending, association-count format, with 22/41 Phase 7I labels NO_MATCH, "
              "only 8 EXACT label matches, and feature coverage of 14/397 (3.53%) EXACT / 24/397 (6.05%) exact+high-confidence "
              "against the 131-feature vocabulary. Even for the 8 EXACT-label diseases the retained Columbia symptom signal "
              "would be 0-57% (1 of 8 diseases keeps 0% of its symptoms; 4 of 8 keep <=30%), so any predicted vector would "
              "represent <60% of the external evidence and results would be an artifact of mapping loss, not generalization. "
              "(2) All other documented candidates are either the same canonical KB family (mirror/leakage), synthetic "
              "(DDXPlus / generated rows), single-disease real cohorts (Dengue), or repositories without a symptom-presence "
              "matrix (MIMIC-III). Per Phase 7K rules (only EXACT mappings are automatic; HIGH_CONFIDENCE/POSSIBLE require "
              "clinician review, unavailable) and the 'do not manufacture evidence' rule, no external metrics were computed.",
    "metrics": None,
    "metrics_computed_for_classes": 0,
    "predictions_made": 0,
    "clinician_review_of_mappings": False,
    "note": "Reporting an external accuracy/F1 here would be a mapping-coverage artifact, not external generalization evidence.",
}
json.dump(eval_rec, open(K + r"\evidence\evaluation_metrics.json", "w", encoding="utf-8"), indent=2)

rep = {
    "phase": "7K",
    "analysis_script": "backend/ml/phase7k/scripts/phase7k_analysis.py",
    "python": "venv Python (3.11.9)",
    "env": "pandas 3.0.5, numpy 2.4.6, scikit-learn 1.8.0 (analysis only: no model fitted)",
    "non_deterministic_steps": "difflib.get_close_matches cutoff=0.88 produces identical output on fixed input (no RNG used)",
    "outputs": ["validation/phase7k_mapping_analysis.json", "evidence/*.json",
                "mappings/label_mapping_full.csv", "mappings/feature_mapping_full.csv"],
    "model_used": "Phase 7I experimental model NOT invoked (no valid evaluation set).",
}
json.dump(rep, open(K + r"\evidence\reproducibility_info.json", "w", encoding="utf-8"), indent=2)

print("evidence written OK")
print(json.dumps(dh, indent=2))