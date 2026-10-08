"""Application configuration loaded from environment variables.

Values come from the backend .env file (loaded by python-dotenv in app.py).
No secrets are hardcoded in source code.
"""

import os


class Config:
    """Base configuration for the Flask application."""

    # Environment name: development, production, etc.
    FLASK_ENV: str = os.getenv("FLASK_ENV", "development")

    # Host the Flask dev server binds to.
    # 0.0.0.0 makes the backend reachable from the Android emulator (via 10.0.2.2).
    HOST: str = os.getenv("FLASK_HOST", "0.0.0.0")

    # Port the Flask dev server listens on.
    PORT: int = int(os.getenv("FLASK_PORT", "5000"))

    # ENGINEERING threshold (NOT medically validated) used to flag a
    # prediction as "low confidence" when the top raw Logistic Regression model
    # score is below this value. It is configurable at deploy time but must
    # never be presented as a clinical reliability threshold.
    PREDICTION_LOW_CONFIDENCE_THRESHOLD: float = float(
        os.getenv("PREDICTION_LOW_CONFIDENCE_THRESHOLD", "0.5")
    )

    # Google Gemini API for the AI Healthcare Assistant. The key lives
    # server-side only and is never exposed to the Flutter app.
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    # gemini-3.6-flash is a stable, currently served, free-tier model that
    # answers reliably on this key. Overridable via GEMINI_MODEL without
    # touching this code.
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-3.6-flash")
    # Overall budget for ONE Gemini call, retries included, so the Flutter
    # client (45s request timeout) never outlives the backend.
    GEMINI_TIMEOUT_SECONDS: int = int(os.getenv("GEMINI_TIMEOUT_SECONDS", "30"))
    # Bounded retries for transient provider 5xx only (never 4xx / 429).
    GEMINI_MAX_ATTEMPTS: int = int(os.getenv("GEMINI_MAX_ATTEMPTS", "2"))
    # Upper bound for one reply. Gemini's thinking budget counts against it,
    # so this stays above the 500-token answer cap to avoid an empty reply.
    GEMINI_MAX_OUTPUT_TOKENS: int = int(
        os.getenv("GEMINI_MAX_OUTPUT_TOKENS", "2048")
    )

    # Maximum allowed assistant message length and simple per-IP rate limit.
    ASSISTANT_MAX_MESSAGE_LENGTH: int = int(
        os.getenv("ASSISTANT_MAX_MESSAGE_LENGTH", "2000")
    )
    ASSISTANT_RATE_LIMIT_PER_MINUTE: int = int(
        os.getenv("ASSISTANT_RATE_LIMIT_PER_MINUTE", "10")
    )


class DevelopmentConfig(Config):
    """Development-specific configuration.

    CORS is intentionally permissive for local development so the Flutter
    app (Android emulator / web) can reach the backend. Tighten this before
    any production deployment.
    """

    # Allowed origins for CORS during development. The Android emulator uses
    # http://10.0.2.2:5000, and the Flutter web app uses localhost.
    CORS_ORIGINS: list[str] = [
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://10.0.2.2:5000",
    ]

    DEBUG: bool = True


class ProductionConfig(Config):
    """Production configuration. Restrict CORS origins explicitly."""

    # Populate from real deployment values; never wildcard in production.
    CORS_ORIGINS: list[str] = []

    DEBUG: bool = False


def get_config() -> Config:
    """Return the active configuration based on the environment."""
    if Config.FLASK_ENV == "production":
        return ProductionConfig()
    return DevelopmentConfig()
