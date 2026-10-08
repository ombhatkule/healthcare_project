"""Prediction API routes (Phase 7J research/educational integration).

Provides:
  POST /api/predict   -> top-5 disease predictions for a list of symptoms
  GET  /api/symptoms  -> canonical symptom names supported by the active model

WARNING: the active model is the Phase 7I EXPERIMENTAL Logistic Regression
research artifact (131 features, 41 classes). It is NOT clinically validated
and has no independent external validation. The returned `score` is the raw,
un-calibrated Logistic Regression class probability; `confidence_status` is an
engineering heuristic (thresholds from config). These outputs must never be
presented as a medical diagnosis or diagnostic confidence.
"""

import logging

from flask import Blueprint, jsonify, request

from config.config import get_config
from services.prediction_service import (
    RESEARCH_DISCLAIMER,
    PredictionService,
    PredictionServiceError,
)

logger = logging.getLogger(__name__)

prediction_bp = Blueprint("prediction", __name__)

# Engineering threshold (configurable via env, NOT medically validated).
_LOW_CONFIDENCE_THRESHOLD = get_config().PREDICTION_LOW_CONFIDENCE_THRESHOLD


@prediction_bp.route("/api/symptoms", methods=["GET"])
def symptoms():
    """Return the canonical symptom names supported by the active model.

The order is the exact Phase 7I training-feature order (131 symptoms). It is
deterministic and must be used by consumers to build the feature vector.
"""
    try:
        service = PredictionService.get_instance()
    except PredictionServiceError as exc:
        logger.exception("Prediction model failed to load")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Prediction model is unavailable",
                }
            ),
            503,
        )

    return (
        jsonify(
            {
                "status": "success",
                "symptoms": service.known_symptoms,
                "count": service.feature_count,
                "mode": "research_educational_experimental",
            }
        ),
        200,
    )


@prediction_bp.route("/api/predict", methods=["POST"])
def predict():
    """Return top-5 disease predictions for a list of symptoms."""
    # --- Parse and validate JSON body ---------------------------------
    if not request.is_json:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Request body must be valid JSON",
                }
            ),
            400,
        )

    try:
        data = request.get_json()
    except Exception:
        # Malformed JSON
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Request body must be valid JSON",
                }
            ),
            400,
        )

    if not isinstance(data, dict):
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Request body must be a JSON object",
                }
            ),
            400,
        )

    # --- Validate symptoms field --------------------------------------
    symptoms = data.get("symptoms")
    if symptoms is None:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Missing required field: 'symptoms'",
                }
            ),
            400,
        )

    if not isinstance(symptoms, list):
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "'symptoms' must be a list",
                }
            ),
            400,
        )

    if len(symptoms) == 0:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "'symptoms' must not be empty",
                }
            ),
            400,
        )

    # Validate each symptom is a non-empty string.
    for s in symptoms:
        if not isinstance(s, str):
            return (
                jsonify(
                    {
                        "status": "error",
                        "message": "Each symptom must be a non-empty string",
                    }
                ),
                400,
            )
        if s.strip() == "":
            return (
                jsonify(
                    {
                        "status": "error",
                        "message": "Each symptom must be a non-empty string",
                    }
                ),
                400,
            )

    cleaned = [s.strip() for s in symptoms]

    # Deduplicate while preserving first-occurrence order. Duplicate symptom
    # entries are redundant for a binary feature vector and are rejected by
    # removing the duplicates safely rather than failing the request.
    cleaned = list(dict.fromkeys(cleaned))

    # --- Ensure the model is loaded -----------------------------------
    try:
        service = PredictionService.get_instance()
    except PredictionServiceError as exc:
        logger.exception("Prediction model failed to load")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Prediction model is unavailable",
                }
            ),
            503,
        )

    # --- Reject oversized symptom lists --------------------------------
    # Robustness guard: 131 features exist; more inputs can only be
    # duplicates after deduplication, so a list larger than the feature count
    # is invalid input.
    if len(cleaned) > service.max_symptoms:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": (
                        f"'symptoms' must not contain more than "
                        f"{service.max_symptoms} unique entries"
                    ),
                }
            ),
            400,
        )

    # --- Reject unknown symptoms --------------------------------------
    unknown = service.validate_symptoms(cleaned)
    if unknown:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "One or more symptoms are not recognized",
                    "unknown_symptoms": unknown,
                }
            ),
            400,
        )

    # --- Run prediction ------------------------------------------------
    try:
        result = service.predict(cleaned)
    except Exception as exc:  # noqa: BLE001 - do not leak internals
        logger.exception("Prediction failed")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Prediction failed. Please try again.",
                }
            ),
            500,
        )

    # Include disclaimer that scores are not calibrated and the model is
    # research/educational only. Never present results as a medical diagnosis.
    response = {
        "status": "success",
        "prediction": {
            "disease": result["disease"],
            "score": result["score"],
            # ENGINEERING flag, not a medical reliability measure.
            "confidence_status": result["confidence_status"],
        },
        "top_predictions": result["top_predictions"],
        "low_confidence_threshold": _LOW_CONFIDENCE_THRESHOLD,
        "model": {
            "mode": "research_educational_experimental",
            "type": service.model_type,
            "version": service.model_version,
            "feature_count": service.feature_count,
            "class_count": service.class_count,
        },
        "disclaimer": RESEARCH_DISCLAIMER,
        "usage_note": (
            "For a more informative experimental result, select multiple "
            "relevant symptoms."
        ),
    }
    return jsonify(response), 200