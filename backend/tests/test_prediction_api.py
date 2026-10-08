"""Tests for the POST /api/predict, GET /api/symptoms and health endpoints.

These tests use Flask's test client and load the real Phase 7J experimental
model once via the PredictionService singleton. They verify API contract and
error handling. They do NOT assert that any specific disease is medically
correct, nor do they imply clinical validity: the active model is a
research/educational experimental artifact (Phase 7I: Logistic Regression,
131 features, 41 classes) with no external validation.
"""

import os
import sys
import unittest

# Ensure the backend package root is importable regardless of CWD.
_BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _BACKEND_DIR not in sys.path:
    sys.path.insert(0, _BACKEND_DIR)

from app import app  # noqa: E402
from services.prediction_service import PredictionService  # noqa: E402


# A set of valid, canonical symptom names that exist in the Phase 7I
# experimental vocabulary (experimental_symptom_columns.joblib, 131 features).
VALID_SYMPTOMS = [
    "high_fever",
    "cough",
    "headache",
    "fatigue",
    "itching",
    "skin_rash",
]


class PredictionApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Load the real model once.
        cls.service = PredictionService.get_instance()
        cls.client = app.test_client()

    # ------------------------------------------------------------------
    # Valid request
    # ------------------------------------------------------------------
    def test_valid_request(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": VALID_SYMPTOMS},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["status"], "success")
        self.assertIn("prediction", data)
        self.assertIn("disease", data["prediction"])
        self.assertIn("score", data["prediction"])
        self.assertIn("top_predictions", data)

        top = data["top_predictions"]
        self.assertIsInstance(top, list)
        self.assertLessEqual(len(top), 5)
        self.assertIsInstance(top[0]["disease"], str)
        self.assertIsInstance(top[0]["score"], (int, float))

        # Top prediction should match the top entry.
        self.assertEqual(data["prediction"]["disease"], top[0]["disease"])
        self.assertEqual(data["prediction"]["score"], top[0]["score"])

    def test_scores_are_numeric(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": ["high_fever", "cough"]},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        for item in data["top_predictions"]:
            self.assertIsInstance(item["score"], (int, float))

    def test_confidence_status_present(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": VALID_SYMPTOMS},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        status = data["prediction"]["confidence_status"]
        self.assertIn(status, ("low_confidence", "normal"))
        self.assertIn("low_confidence_threshold", data)
        self.assertIsInstance(data["low_confidence_threshold"], float)

    # ------------------------------------------------------------------
    # Empty symptoms
    # ------------------------------------------------------------------
    def test_empty_symptoms(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": []},
        )
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["status"], "error")

    # ------------------------------------------------------------------
    # Missing symptoms field
    # ------------------------------------------------------------------
    def test_missing_symptoms_field(self):
        resp = self.client.post("/api/predict", json={})
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["status"], "error")

    # ------------------------------------------------------------------
    # Invalid JSON / body
    # ------------------------------------------------------------------
    def test_invalid_json(self):
        resp = self.client.post(
            "/api/predict",
            data="{not valid json",
            content_type="application/json",
        )
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["status"], "error")

    def test_non_object_body(self):
        resp = self.client.post(
            "/api/predict",
            json=[1, 2, 3],
        )
        self.assertEqual(resp.status_code, 400)

    # ------------------------------------------------------------------
    # Unknown symptom
    # ------------------------------------------------------------------
    def test_unknown_symptom(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": ["high_fever", "not_a_real_symptom_xyz"]},
        )
        self.assertEqual(resp.status_code, 400)
        data = resp.get_json()
        self.assertEqual(data["status"], "error")
        self.assertIn("unknown_symptoms", data)
        self.assertIn("not_a_real_symptom_xyz", data["unknown_symptoms"])

    # ------------------------------------------------------------------
    # Non-list symptoms
    # ------------------------------------------------------------------
    def test_non_list_symptoms(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": "fever"},
        )
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["status"], "error")

    # ------------------------------------------------------------------
    # Non-string symptom
    # ------------------------------------------------------------------
    def test_non_string_symptom(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": ["fever", 123]},
        )
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["status"], "error")

    # ------------------------------------------------------------------
    # Health endpoint still works
    # ------------------------------------------------------------------
    def test_health_endpoint(self):
        resp = self.client.get("/api/health")
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["status"], "success")

    def test_health_exposes_model_metadata(self):
        resp = self.client.get("/api/health")
        self.assertEqual(resp.status_code, 200)
        model = resp.get_json()["model"]
        self.assertIn(model["status"], ("loaded", "not_loaded"))
        self.assertEqual(model["mode"], "research_educational_experimental")
        if model["status"] == "loaded":
            self.assertEqual(model["type"], "LogisticRegression")
            self.assertEqual(model["feature_count"], 131)
            self.assertEqual(model["class_count"], 41)

    # ------------------------------------------------------------------
    # Symptoms catalog endpoint
    # ------------------------------------------------------------------
    def test_symptoms_endpoint(self):
        resp = self.client.get("/api/symptoms")
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["status"], "success")
        self.assertIn("symptoms", data)
        self.assertIsInstance(data["symptoms"], list)
        self.assertEqual(data["count"], len(data["symptoms"]))
        self.assertGreater(len(data["symptoms"]), 0)
        # Symptom count must match the active model's feature count.
        service = PredictionService.get_instance()
        self.assertEqual(len(data["symptoms"]), service.feature_count)

    def test_symptoms_are_exact_experimental_vocabulary(self):
        resp = self.client.get("/api/symptoms")
        data = resp.get_json()
        symptoms = data["symptoms"]
        self.assertEqual(len(symptoms), 131)
        # r667: the removed phase-7I synonym must not be served; its keep
        # token fluid_overload_1 must be served.
        self.assertNotIn("fluid_overload", symptoms)
        self.assertIn("fluid_overload_1", symptoms)
        # The vocabulary must be deterministic across requests.
        resp2 = self.client.get("/api/symptoms")
        self.assertEqual(
            resp2.get_json()["symptoms"], symptoms
        )

    # ------------------------------------------------------------------
    # Duplicate symptoms are deduplicated (not an error)
    # ------------------------------------------------------------------
    def test_duplicate_symptoms_are_deduplicated(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": ["high_fever", "high_fever", "cough"]},
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["status"], "success")

        # Dedup must not change the result of the same unique set.
        uniq = self.client.post(
            "/api/predict",
            json={"symptoms": ["high_fever", "cough"]},
        )
        self.assertEqual(uniq.get_json()["prediction"], resp.get_json()["prediction"])

    # ------------------------------------------------------------------
    # Oversized symptom list is rejected (robustness guard)
    # ------------------------------------------------------------------
    def test_oversized_symptom_list(self):
        too_many = [f"v{s}" for s in range(5000)]
        resp = self.client.post("/api/predict", json={"symptoms": too_many})
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["status"], "error")

    # ------------------------------------------------------------------
    # Response includes the non-clinical disclaimer and model metadata
    # ------------------------------------------------------------------
    def test_response_includes_research_disclaimer(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": VALID_SYMPTOMS},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertIn("disclaimer", data)
        self.assertIn("Research/Educational", data["disclaimer"])
        self.assertIn("not a medical diagnosis", data["disclaimer"])
        self.assertEqual(data["model"]["mode"], "research_educational_experimental")
        self.assertEqual(data["model"]["type"], "LogisticRegression")
        self.assertEqual(data["model"]["feature_count"], 131)
        self.assertEqual(data["model"]["class_count"], 41)
        self.assertIn("usage_note", data)

    def test_usage_note_encourages_multiple_symptoms(self):
        resp = self.client.post(
            "/api/predict",
            json={"symptoms": VALID_SYMPTOMS},
        )
        data = resp.get_json()
        self.assertIn(
            "select multiple relevant symptoms", data["usage_note"].lower()
        )

    # ------------------------------------------------------------------
    # Determinism: identical input always yields identical output
    # ------------------------------------------------------------------
    def test_predictions_are_deterministic(self):
        body = {"symptoms": [VALID_SYMPTOMS[0], VALID_SYMPTOMS[1]]}
        first = self.client.post("/api/predict", json=body).get_json()
        second = self.client.post("/api/predict", json=body).get_json()
        self.assertEqual(first["prediction"], second["prediction"])
        self.assertEqual(first["top_predictions"], second["top_predictions"])


if __name__ == "__main__":
    unittest.main()
