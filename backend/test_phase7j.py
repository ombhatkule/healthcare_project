"""Phase 7J backend integration tests.

Tests the Flask prediction service singleton, the experimental model
loading, input validation, feature vector construction, and prediction
determinism.

IMPORTANT: These are non-clinical research/educational tests.
"""

import os
import sys
import numpy as np
import pandas as pd

# Ensure the backend package is importable.
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))

from services.prediction_service import PredictionService, PredictionServiceError

MODEL_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "ml", "model"
)


def _make_service():
    """Create a fresh PredictionService pointing at the experimental artifacts."""
    PredictionService.reset_instance()
    return PredictionService(
        model_path=os.path.join(MODEL_DIR, "experimental_disease_model.joblib"),
        symptoms_path=os.path.join(MODEL_DIR, "experimental_symptom_columns.joblib"),
        load_now=True,
    )


class TestModelLoading:
    def test_model_loads(self):
        svc = _make_service()
        assert svc.model is not None

    def test_131_features(self):
        svc = _make_service()
        assert svc.feature_count == 131

    def test_41_classes(self):
        svc = _make_service()
        assert svc.class_count == 41

    def test_model_type_logistic_regression(self):
        svc = _make_service()
        assert svc.model_type == "LogisticRegression"

    def test_has_predict_proba(self):
        svc = _make_service()
        assert hasattr(svc.model, "predict_proba")

    def test_symptom_columns_unique(self):
        svc = _make_service()
        assert len(svc.known_symptoms) == len(set(svc.known_symptoms))

    def test_no_fluid_overload(self):
        svc = _make_service()
        assert "fluid_overload" not in svc.known_symptoms

    def test_fluid_overload_1_present(self):
        svc = _make_service()
        assert "fluid_overload_1" in svc.known_symptoms


class TestSymptomValidation:
    def test_validate_known_symptom(self):
        svc = _make_service()
        unknown = svc.validate_symptoms(["high_fever", "headache"])
        assert unknown == []

    def test_validate_unknown_symptom(self):
        svc = _make_service()
        unknown = svc.validate_symptoms(["fake_symptom_xyz"])
        assert "fake_symptom_xyz" in unknown

    def test_validate_mixed(self):
        svc = _make_service()
        unknown = svc.validate_symptoms(["high_fever", "not_real_abc"])
        assert "not_real_abc" in unknown
        assert "high_fever" not in unknown


class TestFeatureVector:
    def test_131_dimensional_vector(self):
        svc = _make_service()
        n = len(svc.known_symptoms)
        assert n == 131
        vector = np.zeros(n, dtype=np.int8)
        for name in ["high_fever", "headache", "cough"]:
            idx = svc._index_map[name]
            vector[idx] = 1
        assert vector.sum() == 3
        assert len(vector) == 131

    def test_empty_vector_prediction(self):
        svc = _make_service()
        symptoms = []
        result = svc.predict(symptoms)
        assert "disease" in result
        assert "score" in result
        assert "top_predictions" in result
        assert len(result["top_predictions"]) == 5


class TestPrediction:
    def test_valid_prediction_structure(self):
        svc = _make_service()
        result = svc.predict(["high_fever", "headache", "fatigue"])
        assert isinstance(result["disease"], str)
        assert isinstance(result["score"], float)
        assert isinstance(result["confidence_status"], str)
        assert isinstance(result["top_predictions"], list)
        assert len(result["top_predictions"]) == 5
        for tp in result["top_predictions"]:
            assert "disease" in tp
            assert "score" in tp
            assert isinstance(tp["score"], float)

    def test_prediction_determinism(self):
        svc = _make_service()
        symptoms = ["high_fever", "cough", "fatigue", "nausea"]
        results = [svc.predict(symptoms) for _ in range(5)]
        for r in results[1:]:
            assert r["disease"] == results[0]["disease"]
            assert r["score"] == results[0]["score"]
            for a, b in zip(r["top_predictions"], results[0]["top_predictions"]):
                assert a["disease"] == b["disease"]
                assert a["score"] == b["score"]

    def test_multiple_symptoms(self):
        svc = _make_service()
        result = svc.predict([
            "high_fever", "headache", "fatigue", "nausea", "cough",
            "muscle_pain", "dizziness", "loss_of_appetite",
        ])
        assert result["disease"] != ""
        assert 0.0 <= result["score"] <= 1.0

    def test_duplicate_symptoms_handled(self):
        svc = _make_service()
        result = svc.predict(["high_fever", "high_fever", "headache", "headache"])
        assert result["disease"] != ""
        assert len(result["top_predictions"]) == 5

    def test_class_count_41(self):
        svc = _make_service()
        assert svc.class_count == 41
        assert len(svc.model.classes_) == 41

    def test_top_predictions_sorted_descending(self):
        svc = _make_service()
        result = svc.predict(["high_fever", "cough"])
        scores = [tp["score"] for tp in result["top_predictions"]]
        assert scores == sorted(scores, reverse=True)


class Test131FeatureVector:
    def test_all_features_settable(self):
        svc = _make_service()
        for i, name in enumerate(svc.known_symptoms):
            vector = np.zeros(131, dtype=np.int8)
            vector[i] = 1
            X = pd.DataFrame([vector], columns=svc.known_symptoms)
            proba = svc.model.predict_proba(X)[0]
            assert proba.shape == (41,), f"Feature {name} index {i} failed"

    def test_symptom_index_map_consistency(self):
        svc = _make_service()
        for i, name in enumerate(svc.known_symptoms):
            assert svc._index_map[name] == i
