"""Phase 7J setup: backup production files, install experimental artifacts, verify, record hashes."""
import hashlib
import json
import os
import shutil
import time

import joblib

BACK = r"C:\Users\ADMIN\OneDrive\Desktop\healthcareapp\backend"
ML = BACK + r"\ml"
MODEL_DIR = ML + r"\model"
PHASE7I = ML + r"\phase7i"
K = ML + r"\phase7j"

PROD_FILES = [
    ("disease_model.joblib", MODEL_DIR + r"\disease_model.joblib"),
    ("symptom_columns.joblib", MODEL_DIR + r"\symptom_columns.joblib"),
    ("disease_dataset_cleaned_v2.csv", BACK + r"\data\disease_dataset_cleaned_v2.csv"),
]

SRC_MODEL = PHASE7I + r"\models\experimental_best_model.joblib"
SRC_VOCAB_JSON = PHASE7I + r"\data\symptom_columns_131.json"
DST_MODEL = MODEL_DIR + r"\experimental_disease_model.joblib"
DST_COLUMNS = MODEL_DIR + r"\experimental_symptom_columns.joblib"

def sha256(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()

# ---------- 1. backup production files ----------
backup_hashes = {}
for name, path in PROD_FILES:
    dst = os.path.join(BACK + r"\ml\phase7j\backup", name)
    if not os.path.exists(dst):
        shutil.copy2(path, dst)
    backup_hashes[name] = {"source": path, "sha256": sha256(path), "size": os.path.getsize(path)}

# ---------- 2. install experimental artifacts ----------
if not os.path.exists(DST_MODEL):
    shutil.copy2(SRC_MODEL, DST_MODEL)
if not os.path.exists(DST_COLUMNS):
    voc = json.load(open(SRC_VOCAB_JSON, encoding="utf-8"))["features"]
    joblib.dump(voc, DST_COLUMNS)

# ---------- 3. verify load + dimension checks ----------
t0 = time.time()
model = joblib.load(DST_MODEL)
columns = joblib.load(DST_COLUMNS)
load_time = time.time() - t0

nf = getattr(model, "n_features_in_", None)
nclass = len(getattr(model, "classes_", []))
model_type = type(model).__name__
fni = list(getattr(model, "feature_names_in_", [])) or None
vocab_order_ok = fni == columns if fni is not None else False

verification = {
    "model_type": model_type,
    "n_features_in_": nf,
    "n_classes": nclass,
    "n_columns": len(columns),
    "columns_match_feature_names_in": vocab_order_ok,
    "columns_are_strings": all(isinstance(c, str) for c in columns),
    "columns_unique": len(set(columns)) == len(columns),
    "load_time_s": round(load_time, 3),
    "has_predict_proba": hasattr(model, "predict_proba"),
}

# no fluid_overload, has fluid_overload_1
fluid_overload_present = "fluid_overload" in columns
fluid_overload_1_present = "fluid_overload_1" in columns

verification["fluid_overload_present"] = fluid_overload_present
verification["fluid_overload_1_present"] = fluid_overload_1_present

# ---------- 4. record hashes ----------
hashes_record = {
    "phase": "7J",
    "integration_timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
    "python_version": __import__("sys").version.split()[0],
    "scikit_learn_version": __import__("sklearn").__version__,
    "joblib_version": joblib.__version__,
    "production_originals": {
        name: {"sha256": v["sha256"], "size": v["size"]} for name, v in backup_hashes.items()
    },
    "experimental_artifacts": {
        "experimental_disease_model.joblib": {
            "source": SRC_MODEL,
            "sha256": sha256(SRC_MODEL),
            "installed_sha256": sha256(DST_MODEL),
        },
        "experimental_symptom_columns.joblib": {
            "source": SRC_VOCAB_JSON,
            "sha256_installed": sha256(DST_COLUMNS),
            "feature_count": len(columns),
        },
        "source_vocab_json_sha256": sha256(SRC_VOCAB_JSON),
    },
    "verification": verification,
}

json.dump(hashes_record, open(K + r"\evidence\model_verification.json", "w", encoding="utf-8"), indent=2)

# backup hashes text
lines = ["PHASE 7J PRODUCTION BACKUP HASHLISTS", ""]
for name, v in backup_hashes.items():
    lines += [f"{name}", f"  source: {v['source']}", f"  SHA256: {v['sha256']}", f"  Size: {v['size']}", ""]
open(K + r"\evidence\production_backup_hashes.txt", "w", encoding="utf-8").write("\n".join(lines))

print(json.dumps(hashes_record, indent=2))