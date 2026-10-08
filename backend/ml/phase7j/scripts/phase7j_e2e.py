"""Phase 7J end-to-end validation against a live Flask server.

Covers: health metadata, symptoms catalog contract, valid + invalid predict,
duplicates, determinism (5 identical runs), and latency measurement.
Uses only the standard library so it runs in any ambient Python.
"""

import json
import sys
import time
import urllib.error
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:5000"
results = []


def log(name, ok, detail=""):
    results.append((name, ok, detail))
    print(f"[{'PASS' if ok else 'FAIL'}] {name} {detail}")


def get(path):
    with urllib.request.urlopen(f"{BASE}{path}", timeout=60) as r:
        return r.status, json.load(r)


def post(path, payload):
    req = urllib.request.Request(
        f"{BASE}{path}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.status, json.load(r)


def expect_status(fn, want_status, name):
    try:
        code, _ = fn()
        log(name, code == want_status, f"(got HTTP {code}, want {want_status})")
    except urllib.error.HTTPError as e:
        log(name, e.code == want_status, f"(got HTTP {e.code}, want {want_status})")
    except Exception as e:  # noqa: BLE001
        log(name, False, f"raised {type(e).__name__}: {e}")


# ---------------- health ----------------
t0 = time.time()
code, health = get("/api/health")
elapsed = time.time() - t0
log("health endpoint", code == 200 and health.get("status") == "success")
log(
    "health exposes experimental model metadata",
    health.get("model", {}).get("mode") == "research_educational_experimental"
    and health.get("model", {}).get("type") == "LogisticRegression"
    and health.get("model", {}).get("feature_count") == 131
    and health.get("model", {}).get("class_count") == 41,
    f"model={health.get('model')}",
)
print(f"  health elapsed (incl. model load): {elapsed:.2f}s")

# ---------------- symptoms catalog ----------------
code, sym = get("/api/symptoms")
symptoms = sym.get("symptoms", [])
log(
    "GET /api/symptoms",
    code == 200 and sym.get("status") == "success" and sym.get("count") == len(symptoms),
    f"count={len(symptoms)}",
)
log(
    "symptom catalog is the exact 131 vocabulary",
    len(symptoms) == 131
    and "fluid_overload" not in symptoms
    and "fluid_overload_1" in symptoms
    and len(set(symptoms)) == 131,
    "no fluid_overload, has fluid_overload_1, unique",
)
log("symptom order is deterministic", symptoms == sym.get("symptoms"))

# ---------------- valid predict ----------------
code, resp = post("/api/predict", {"symptoms": ["high_fever", "cough", "headache", "fatigue"]})
log(
    "valid predict returns 200 + success",
    code == 200 and resp.get("status") == "success",
)
pred = resp.get("prediction", {})
log(
    "prediction payload shape",
    "disease" in pred and isinstance(pred.get("score"), (int, float)),
    f"disease={pred.get('disease')} score={pred.get('score')}",
)
log(
    "top_predictions shape",
    isinstance(resp.get("top_predictions"), list)
    and len(resp["top_predictions"]) <= 5
    and resp["top_predictions"][0]["disease"] == pred.get("disease"),
)
log(
    "response carries research disclaimer",
    "Research/Educational" in resp.get("disclaimer", "")
    and "not a medical diagnosis" in resp.get("disclaimer", ""),
)
log(
    "response carries usage note",
    "select multiple relevant symptoms" in resp.get("usage_note", "").lower(),
)
log(
    "response model metadata",
    resp.get("model", {}).get("feature_count") == 131
    and resp.get("model", {}).get("class_count") == 41,
)

# ---------------- determinism (5 runs) + latency ----------------
payload = {"symptoms": ["high_fever", "cough", "headache", "fatigue", "itching"]}
first_pred = None
lats = []
all_identical = True
for i in range(5):
    t0 = time.time()
    _, r = post("/api/predict", payload)
    lats.append((time.time() - t0) * 1000)
    if i == 0:
        first_pred = (r["prediction"], r["top_predictions"])
    elif first_pred != (r["prediction"], r["top_predictions"]):
        all_identical = False
log("5 repeated predictions are identical", all_identical)
print(f"  predict latencies (ms): {[round(x, 1) for x in lats]}")
print(f"  mean predict latency (ms): {round(sum(lats) / len(lats), 1)}")

# ---------------- invalid inputs ----------------
expect_status(
    lambda: post("/api/predict", {"symptoms": []}), 400, "empty list -> 400"
)
expect_status(
    lambda: post("/api/predict", {}), 400, "missing symptoms field -> 400"
)
expect_status(
    lambda: post("/api/predict", {"symptoms": "high_fever"}), 400,
    "non-list symptoms -> 400",
)
expect_status(
    lambda: post("/api/predict", {"symptoms": ["high_fever", 123]}), 400,
    "non-string symptom -> 400",
)
expect_status(
    lambda: post("/api/predict", {"symptoms": ["high_fever", "not_real"]}), 400,
    "unknown symptom -> 400",
)
expect_status(
    lambda: post("/api/predict", {"symptoms": [f"x{i}" for i in range(5000)]}), 400,
    "oversized list -> 400",
)

# dupes are accepted and deduplicated
code, r = post("/api/predict", {"symptoms": ["high_fever", "high_fever", "cough"]})
log("duplicate symptoms -> 200 (deduped)", code == 200)

print()
fails = [r for r in results if not r[1]]
print(f"RESULT: {len(results) - len(fails)}/{len(results)} checks passed")
if fails:
    for name, _, detail in fails:
        print(f"  FAILED: {name} {detail}")
    sys.exit(1)
print("ALL E2E CHECKS PASSED")