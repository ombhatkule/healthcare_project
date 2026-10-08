"""Disease prediction service (Phase 7J research/educational integration).

Loads the Phase 7I experimental Logistic Regression model
(experimental_disease_model.joblib) and its 131-feature symptom vocabulary
(experimental_symptom_columns.joblib) once at application startup and exposes
a method that converts a list of canonical symptom names into the model's
binary feature vector (exact training order) and returns predictions.

IMPORTANT (non-clinical, research/educational):
- This model is the Phase 7I experimental artifact (Logistic Regression,
  class_weight=None, 131 features, 41 classes). It was NOT clinically
  validated and NO independent external validation exists (Phase 7K concluded
  INSUFFICIENT_EXTERNAL_DATA). It must never be presented as a medical
  diagnostic system.
- The `score` values returned here are the raw, un-calibrated Logistic
  Regression class probability outputs. They are NOT validated medical
  probabilities, diagnostic confidence, or external-generalization evidence.
- The `confidence_status` flag is an ENGINEERING heuristic based on a
  configurable threshold. It is NOT a medically validated reliability measure.
"""

import os
import threading
import time

import numpy as np
import joblib
import pandas as pd

from config.config import get_config

# Paths relative to the backend package root.
# services/ -> backend root
_BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_MODEL_DIR = os.path.join(_BACKEND_DIR, "ml", "model")

# The application's disease prediction service now uses the Phase 7I
# experimental research/educational model. The original Phase 7C model
# (disease_model.joblib / symptom_columns.joblib) is preserved untouched
# under backend/ml/model as a rollback artifact and is not loaded here.
DEFAULT_MODEL_PATH = os.path.join(
    _MODEL_DIR,
    os.getenv("EXPERIMENTAL_MODEL_FILE", "experimental_disease_model.joblib"),
)
DEFAULT_SYMPTOMS_PATH = os.path.join(
    _MODEL_DIR,
    os.getenv(
        "EXPERIMENTAL_SYMPTOM_COLUMNS_FILE",
        "experimental_symptom_columns.joblib",
    ),
)

# Experimental model provenance, surfaced by /api/health and /api/predict.
MODEL_VERSION = "phase7i_experimental_lr_class_weight_none"
MODEL_SOURCE = "SymbiPredict Representation C (Phase 7I), grouped repeated CV"

# Maximum number of symptoms the prediction endpoint will accept. This is a
# robustness guard (there are exactly 131 features; more inputs than features
# is always redundant), not a clinical rule.
MAX_SYMPTOMS = 131

# Non-clinical disclaimer returned with every prediction.
RESEARCH_DISCLAIMER = (
    "Research/Educational Use Only. This experimental prediction is generated "
    "from a machine-learning research model. It is not a medical diagnosis and "
    "has not been validated for clinical use or independent patient-level "
    "generalization. Do not use this result to make healthcare decisions. "
    "Please consult a qualified healthcare professional for medical concerns."
)

# Number of top predictions to return.
TOP_N = 5

# Low-confidence statuses exposed by the API.
CONFIDENCE_STATUS_LOW = "low_confidence"
CONFIDENCE_STATUS_NORMAL = "normal"


class PredictionServiceError(Exception):
    """Raised when the model cannot be loaded or used."""


class PredictionService:
    """Singleton service that owns the loaded model and symptom column order."""

    _instance = None
    _lock = threading.Lock()

    def __init__(
        self,
        model_path: str = DEFAULT_MODEL_PATH,
        symptoms_path: str = DEFAULT_SYMPTOMS_PATH,
        low_confidence_threshold: float | None = None,
        load_now: bool = False,
    ):
        self.model_path = model_path
        self.symptoms_path = symptoms_path
        # Configurable engineering threshold. Defaults to the environment
        # config value; both are engineering policy, NOT medical thresholds.
        default_threshold = get_config().PREDICTION_LOW_CONFIDENCE_THRESHOLD
        self.low_confidence_threshold = (
            float(low_confidence_threshold)
            if low_confidence_threshold is not None
            else float(default_threshold)
        )
        self.model = None
        self.symptom_columns = None

        self._model_load_time_s = None

        if load_now:
            self.load()

    # ------------------------------------------------------------------
    # Singleton access
    # ------------------------------------------------------------------
    @classmethod
    def get_instance(cls):
        """Return the process-wide singleton, creating it if needed."""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = cls(load_now=True)
        return cls._instance

    @classmethod
    def reset_instance(cls):
        """Drop the cached instance (mainly for tests)."""
        with cls._lock:
            cls._instance = None

    # ------------------------------------------------------------------
    # Loading
    # ------------------------------------------------------------------
    def load(self) -> None:
        """Load the model and symptom columns. Idempotent."""
        if self.model is not None and self.symptom_columns is not None:
            return

        for path in (self.model_path, self.symptoms_path):
            if not os.path.exists(path):
                raise PredictionServiceError(
                    f"Required model file not found: {path}"
                )

        t0 = time.time()
        model = joblib.load(self.model_path)
        symptom_columns = joblib.load(self.symptoms_path)
        self._model_load_time_s = time.time() - t0

        # Validate dimensions against the model itself (no hard-coded count).
        if not isinstance(symptom_columns, (list, tuple)):
            raise PredictionServiceError(
                "symptom_columns.joblib did not contain a list of column names."
            )

        n_features = getattr(model, "n_features_in_", None)
        if n_features is None:
            raise PredictionServiceError(
                "Loaded model does not expose n_features_in_."
            )
        if n_features != len(symptom_columns):
            raise PredictionServiceError(
                f"Model expects {n_features} features, but symptom metadata "
                f"has {len(symptom_columns)}."
            )

        if not hasattr(model, "predict_proba"):
            raise PredictionServiceError(
                "Loaded model does not expose predict_proba()."
            )

        index_map = {name: i for i, name in enumerate(symptom_columns)}

        self.model = model
        self.symptom_columns = list(symptom_columns)
        self._index_map = index_map

    # ------------------------------------------------------------------
    # Properties (for reporting)
    # ------------------------------------------------------------------
    @property
    def model_load_time_s(self):
        return self._model_load_time_s

    @property
    def feature_count(self):
        return len(self.symptom_columns) if self.symptom_columns is not None else 0

    @property
    def class_count(self):
        return len(self.model.classes_) if self.model is not None else 0

    @property
    def known_symptoms(self):
        return list(self.symptom_columns) if self.symptom_columns is not None else []

    @property
    def model_type(self):
        return type(self.model).__name__ if self.model is not None else None

    @property
    def model_version(self):
        return MODEL_VERSION

    @property
    def model_source(self):
        return MODEL_SOURCE

    @property
    def max_symptoms(self):
        return MAX_SYMPTOMS

    # ------------------------------------------------------------------
    # Prediction
    # ------------------------------------------------------------------
    def validate_symptoms(self, symptoms: list) -> list:
        """Return the subset of symptom names unknown to the model."""
        self.ensure_loaded()
        return [s for s in symptoms if s not in self._index_map]

    def predict(self, symptoms: list) -> dict:
        """Run a prediction for a list of canonical symptom names.

        Args:
            symptoms: list of canonical symptom-name strings (already
                validated and ordered by the caller). Duplicates are removed
                safely here as well, independent of the caller.

        Returns:
            dict with keys:
                - disease: top predicted disease name
                - score: raw Logistic Regression model score for the top
                  prediction (un-calibrated; NOT a medical probability)
                - confidence_status: 'normal' or 'low_confidence' (engineering
                  heuristic only, NOT medically validated)
                - top_predictions: list of up to TOP_N dicts, each with
                  'disease' and 'score'.
        """
        self.ensure_loaded()

        n_features = len(self.symptom_columns)

        # Deduplicate symptom names while preserving first-occurrence order.
        unique_symptoms = list(dict.fromkeys(symptoms))

        # Build the binary feature vector preserving the exact training-time
        # column ordering stored in experimental_symptom_columns.joblib.
        vector = np.zeros(n_features, dtype=np.int8)
        for name in unique_symptoms:
            idx = self._index_map.get(name)
            if idx is not None:
                vector[idx] = 1

        X = pd.DataFrame([vector], columns=self.symptom_columns)

        # predict() for the single best class.
        predicted = self.model.predict(X)[0]

        # predict_proba() for the full distribution over all classes.
        proba = self.model.predict_proba(X)[0]
        classes = self.model.classes_

        # Sort descending by model score.
        order = np.argsort(proba)[::-1][:TOP_N]

        top = [
            {
                "disease": str(classes[i]),
                "score": round(float(proba[i]), 4),
            }
            for i in order
        ]

        top_score = top[0]["score"] if top else 0.0
        confidence_status = (
            CONFIDENCE_STATUS_LOW
            if top_score < self.low_confidence_threshold
            else CONFIDENCE_STATUS_NORMAL
        )

        return {
            "disease": str(predicted),
            "score": top_score,
            "confidence_status": confidence_status,
            "top_predictions": top,
        }

    def ensure_loaded(self) -> None:
        if self.model is None or self.symptom_columns is None:
            self.load()


def init_prediction_service(
    model_path: str = DEFAULT_MODEL_PATH,
    symptoms_path: str = DEFAULT_SYMPTOMS_PATH,
) -> PredictionService:
    """Force-load the singleton service at app startup."""
    service = PredictionService.get_instance()
    if service.model_path != model_path or service.symptoms_path != symptoms_path:
        PredictionService.reset_instance()
        service = PredictionService(
            model_path=model_path,
            symptoms_path=symptoms_path,
            load_now=True,
        )
        PredictionService._instance = service
    return service