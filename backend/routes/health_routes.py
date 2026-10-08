"""Health-check routes for the Flask backend.

Provides a simple endpoint the Flutter app uses to verify backend
connectivity during development.
"""

from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__)


@health_bp.route("/api/health", methods=["GET"])
def health_check():
    """Return a JSON payload confirming the API is running with model metadata.

    Exposes what the active experimental model actually is (type, version,
    feature/class counts) so consumers can verify which model is loaded.
    The model payload is informational; it does not report accuracy or any
    clinical-performance claim.
    """
    model_info = {
        "status": "not_loaded",
        "mode": "research_educational_experimental",
        "type": None,
        "version": None,
        "feature_count": None,
        "class_count": None,
    }
    try:
        from services.prediction_service import PredictionService

        service = PredictionService.get_instance()
        model_info = {
            "status": "loaded",
            "mode": "research_educational_experimental",
            "type": service.model_type,
            "version": service.model_version,
            "feature_count": service.feature_count,
            "class_count": service.class_count,
        }
    except Exception:  # noqa: BLE001 - do not leak internals in health probe
        pass

    return (
        jsonify(
            {
                "status": "success",
                "message": "Healthcare API is running",
                "service": "flask-backend",
                "model": model_info,
            }
        ),
        200,
    )
