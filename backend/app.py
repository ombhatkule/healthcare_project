"""Flask backend application entry point.

Creates the Flask app, loads environment configuration, enables CORS for
development, registers API routes, and runs the dev server on a configurable
host and port.
"""

import logging
import os

from dotenv import load_dotenv
from flask import Flask, jsonify
from flask_cors import CORS

from config.config import get_config
from routes.health_routes import health_bp
from routes.prediction_routes import prediction_bp
from routes.assistant_routes import assistant_bp
from services.prediction_service import init_prediction_service

# Load environment variables from the backend .env file.
#
# The path is pinned to this file's own directory instead of relying on
# python-dotenv's CWD-based discovery. Launching Flask from the repository root
# (or any other directory) previously left `backend/.env` unread, which silently
# resolved GEMINI_API_KEY to an empty string and made /api/assistant/chat answer
# 503 "not configured" even though a key was present in the file.
_BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(_BACKEND_DIR, ".env"), override=False)

# Resolve the active configuration.
config = get_config()

app = Flask(__name__)
app.config.from_object(config)

# Enable CORS for the development origins listed in config/config.py.
# This is a DEVELOPMENT-only policy; tighten before production deployment.
CORS(
    app,
    resources={r"/api/*": {"origins": config.CORS_ORIGINS}},
    supports_credentials=False,
)


def register_routes(app: Flask) -> None:
    """Register all API blueprints on the app."""
    app.register_blueprint(health_bp)
    app.register_blueprint(prediction_bp)
    app.register_blueprint(assistant_bp)


@app.errorhandler(404)
def not_found(error):
    """Return JSON for 404 errors instead of the default HTML page."""
    return (
        jsonify(
            {
                "status": "error",
                "message": "Endpoint not found",
            }
        ),
        404,
    )


@app.errorhandler(405)
def method_not_allowed(error):
    """Return JSON for 405 errors instead of the default HTML page."""
    return (
        jsonify(
            {
                "status": "error",
                "message": "Method not allowed",
            }
        ),
        405,
    )


@app.errorhandler(500)
def internal_error(error):
    """Return a generic JSON error without leaking stack traces."""
    return (
        jsonify(
            {
                "status": "error",
                "message": "Internal server error",
            }
        ),
        500,
    )


register_routes(app)


def main() -> None:
    """Start the Flask development server."""
    logging.basicConfig(level=logging.INFO)
    _log_assistant_configuration()

    # Load the prediction model once at startup. The Phase 7J experimental
    # Logistic Regression artifact (131 features, 41 classes) takes several
    # seconds to load from disk; loading it per-request would be slow.
    logging.getLogger(__name__).info("Loading prediction model at startup...")
    service = init_prediction_service()
    logging.getLogger(__name__).info(
        "Prediction model loaded: %s, %d features, %d classes, load time %.2fs",
        service.model_type,
        service.feature_count,
        service.class_count,
        service.model_load_time_s or 0.0,
    )

    app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG)


def _log_assistant_configuration() -> None:
    """Log whether the AI assistant is usable — never the key itself.

    An absent GEMINI_API_KEY is the single most common reason
    POST /api/assistant/chat answers 503 with no visible symptom, so it is
    reported explicitly at startup. Only a boolean is printed.
    """
    log = logging.getLogger(__name__)
    if config.GEMINI_API_KEY:
        log.info(
            "AI assistant: configured (model=%s, timeout=%ss, attempts=%d)",
            config.GEMINI_MODEL,
            config.GEMINI_TIMEOUT_SECONDS,
            config.GEMINI_MAX_ATTEMPTS,
        )
    else:
        log.warning(
            "AI assistant: NOT configured - GEMINI_API_KEY is missing or "
            "empty. POST /api/assistant/chat will return HTTP 503 until a "
            "key is set in %s. Value is never logged.",
            os.path.join(_BACKEND_DIR, ".env"),
        )


if __name__ == "__main__":
    main()
