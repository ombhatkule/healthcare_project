"""Google Gemini text generation for the AI Healthcare Assistant.

Uses the official Google Gen AI SDK (``google-genai``) and its standard
generation method, ``models.generate_content``:

    POST https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent

The SDK owns the HTTP transport, authentication and bounded retries, so this
module builds the request, enforces an overall time budget, and converts any
provider failure into a small set of safe, user-facing messages.

Medical privacy: neither the prompt, the generated answer, nor the API key is
ever logged or returned to the client. Only metadata (provider, model,
attempt count, HTTP status, error category) is written to the log.
"""

from __future__ import annotations

import logging

from config.config import get_config

logger = logging.getLogger(__name__)

# The SDK is imported defensively: a missing or broken install must surface
# as a clean HTTP 503 on /api/assistant/chat instead of crashing Flask at
# import time (the module is imported while the blueprint is registered).
try:  # pragma: no cover - the fallback branch runs only on a broken install
    from google import genai
    from google.genai import errors as genai_errors
    from google.genai import types as genai_types

    _GENAI_IMPORT_ERROR: Exception | None = None
except Exception as exc:  # noqa: BLE001 - never fail the whole backend
    genai = None
    genai_errors = None
    genai_types = None
    _GENAI_IMPORT_ERROR = exc

_config = get_config()

# Transient provider statuses that are worth one bounded retry. A 429 (quota)
# and a 4xx (bad request / bad key) are NOT retried: retrying them only makes
# the user wait longer for an answer that will not change.
RETRYABLE_STATUS_CODES = (500, 502, 503)

# Safe user-facing messages, one per failure category.
NOT_CONFIGURED_MESSAGE = (
    "The AI Assistant is currently unavailable. Please check the AI service "
    "configuration and try again."
)
MODEL_UNAVAILABLE_MESSAGE = (
    "The AI Assistant is temporarily unavailable. Please try again in a few "
    "minutes."
)
PROVIDER_BUSY_MESSAGE = (
    "The AI Assistant is busy right now. Please try again in a moment."
)
RATE_LIMIT_MESSAGE = (
    "Too many requests. Please wait a moment and try again."
)
GENERATION_FAILED_MESSAGE = (
    "Sorry, I couldn't generate a response right now. Please try again."
)
TIMEOUT_MESSAGE = (
    "The AI Assistant took too long to respond. Please try again."
)
CONNECTION_MESSAGE = (
    "Unable to connect to the assistant. Please check your internet "
    "connection and try again."
)

# One process-wide client, rebuilt only when the effective configuration
# changes (key, per-attempt timeout or retry budget).
_client = None
_client_cache_key: tuple[str, int, int] | None = None


class GeminiUnavailableError(Exception):
    """A provider failure carrying a safe user message and an HTTP status."""

    def __init__(self, user_message: str, status_code: int = 502):
        super().__init__(user_message)
        self.user_message = user_message
        self.status_code = status_code


def _reset_client_cache() -> None:
    """Drop the cached SDK client so configuration changes take effect."""
    global _client, _client_cache_key
    _client = None
    _client_cache_key = None


def _retry_budget() -> tuple[int, int]:
    """Return (per-attempt timeout seconds, attempts) for one Gemini call.

    ``GEMINI_TIMEOUT_SECONDS`` is the budget for the WHOLE call, retries
    included, so the Flutter client (45s request timeout) never outlives the
    backend. Two seconds are reserved per retry to absorb backoff.
    """
    try:
        attempts = int(_config.GEMINI_MAX_ATTEMPTS)
    except (TypeError, ValueError):
        attempts = 2
    attempts = min(max(attempts, 1), 4)

    try:
        overall = float(_config.GEMINI_TIMEOUT_SECONDS)
    except (TypeError, ValueError):
        overall = 30.0
    overall = max(overall, 1.0)

    reserve = 2.0 * (attempts - 1)
    per_attempt = max(1.0, (overall - reserve) / attempts)
    return int(round(per_attempt)), attempts


def build_http_options() -> object:
    """Build the SDK transport options: per-attempt timeout + bounded retry."""
    per_attempt, attempts = _retry_budget()
    return genai_types.HttpOptions(
        timeout=per_attempt * 1000,
        retry_options=genai_types.HttpRetryOptions(
            attempts=attempts,
            http_status_codes=list(RETRYABLE_STATUS_CODES),
        ),
    )


def _get_client(api_key: str):
    """Return the shared Gemini client, rebuilt when configuration changes."""
    global _client, _client_cache_key
    if genai is None:
        raise GeminiUnavailableError(NOT_CONFIGURED_MESSAGE, 503)
    per_attempt, attempts = _retry_budget()
    cache_key = (api_key, per_attempt, attempts)
    if _client is None or _client_cache_key != cache_key:
        _client = genai.Client(
            api_key=api_key,
            http_options=build_http_options(),
        )
        _client_cache_key = cache_key
    return _client


def generate_reply(system_instruction: str, user_input: str) -> str:
    """Ask Gemini for one assistant reply and return the stripped text.

    Sends a single-turn request through the standard Gemini generation API
    (``models.generate_content``): the healthcare safety rules travel in
    ``system_instruction`` and the user turn in ``contents``.

    Raises [GeminiUnavailableError] with a safe message and an HTTP status
    on any configuration, network or provider failure.
    """
    api_key = _config.GEMINI_API_KEY
    if not api_key:
        raise GeminiUnavailableError(NOT_CONFIGURED_MESSAGE, 503)

    if genai is None:
        logger.error(
            "Gemini SDK is not installed or failed to import (%s)",
            type(_GENAI_IMPORT_ERROR).__name__,
        )
        raise GeminiUnavailableError(NOT_CONFIGURED_MESSAGE, 503)

    client = _get_client(api_key)
    model = _config.GEMINI_MODEL
    per_attempt, attempts = _retry_budget()

    logger.info(
        "AI PROVIDER REQUEST STARTED: provider=gemini model=%s "
        "attempts=%d per-attempt-timeout=%ds",
        model,
        attempts,
        per_attempt,
    )

    try:
        response = client.models.generate_content(
            model=model,
            contents=user_input,
            config=genai_types.GenerateContentConfig(
                system_instruction=system_instruction,
                temperature=0.3,
                max_output_tokens=_config.GEMINI_MAX_OUTPUT_TOKENS,
                # No tools are supplied; AFC would only add hidden round trips.
                automatic_function_calling=genai_types
                .AutomaticFunctionCallingConfig(disable=True),
            ),
        )
    except Exception as exc:  # noqa: BLE001 - any SDK/transport failure
        raise _map_provider_error(exc, model) from exc

    text = getattr(response, "text", None)
    if not isinstance(text, str) or not text.strip():
        logger.warning(
            "AI PROVIDER RESPONSE EMPTY: provider=gemini model=%s finish=%s",
            model,
            _finish_reason(response),
        )
        raise GeminiUnavailableError(GENERATION_FAILED_MESSAGE, 502)

    logger.info(
        "AI PROVIDER RESPONSE RECEIVED: provider=gemini model=%s chars=%d",
        model,
        len(text.strip()),
    )
    return text.strip()


def _finish_reason(response: object) -> str:
    """Best-effort, non-sensitive reason a reply came back empty."""
    try:
        candidates = getattr(response, "candidates", None) or []
        if candidates:
            return str(getattr(candidates[0], "finish_reason", "unknown"))
        return "no-candidates"
    except Exception:  # noqa: BLE001 - diagnostics only
        return "unknown"


def _map_provider_error(exc: Exception, model: str) -> GeminiUnavailableError:
    """Translate a provider/transport exception into a safe user message.

    The SDK raises two error hierarchies (``google.genai.errors.APIError``
    with ``code``, and status-code classes with ``status_code``), so both are
    read. Only the class, HTTP status code and error status are used — never
    the raw payload, which could echo parts of the prompt or the key.
    """
    code = _error_code(exc)
    status = str(getattr(exc, "status", "") or "")
    name = type(exc).__name__
    logger.warning(
        "AI PROVIDER REQUEST FAILED: provider=gemini model=%s http=%s "
        "class=%s category=%s",
        model,
        code,
        name,
        _category(exc, code),
    )

    if _is_auth_failure(exc, code, status):
        return GeminiUnavailableError(NOT_CONFIGURED_MESSAGE, 503)
    if code == 404:
        return GeminiUnavailableError(MODEL_UNAVAILABLE_MESSAGE, 503)
    if code == 429:
        return GeminiUnavailableError(RATE_LIMIT_MESSAGE, 429)
    if code in (408, 504) or _is_timeout_failure(exc):
        return GeminiUnavailableError(TIMEOUT_MESSAGE, 504)
    if code is not None and code >= 500:
        return GeminiUnavailableError(PROVIDER_BUSY_MESSAGE, 503)
    if _is_connection_failure(exc):
        return GeminiUnavailableError(CONNECTION_MESSAGE, 503)
    return GeminiUnavailableError(GENERATION_FAILED_MESSAGE, 502)


def _category(exc: Exception, code: int | None) -> str:
    """Coarse, log-only label for a provider failure."""
    if _is_auth_failure(exc, code, str(getattr(exc, "status", "") or "")):
        return "auth"
    if code == 404:
        return "model-unavailable"
    if code == 429:
        return "rate-limit"
    if code in (408, 504) or _is_timeout_failure(exc):
        return "timeout"
    if code is not None and code >= 500:
        return "provider-server-error"
    if _is_connection_failure(exc):
        return "network"
    return "unknown"


def _error_code(exc: Exception) -> int | None:
    """Return the HTTP status code carried by either SDK error hierarchy."""
    for attribute in ("code", "status_code"):
        value = getattr(exc, attribute, None)
        if isinstance(value, int):
            return value
    return None


def _is_auth_failure(exc: Exception, code: int | None, status: str) -> bool:
    """True when the key is missing, invalid or lacks permission."""
    if code in (401, 403):
        return True
    name = type(exc).__name__
    if name in (
        "AuthenticationError",
        "PermissionDeniedError",
        "APIKeyInvalidError",
        "APIKeyNotFoundError",
    ):
        return True
    message = str(getattr(exc, "message", "") or "")
    haystack = f"{name} {status} {message}".lower()
    return any(
        marker in haystack
        for marker in ("api key", "api_key", "apikey", "unauthenticated",
                       "permission denied", "unauthorized")
    )


def _is_timeout_failure(exc: Exception) -> bool:
    """True for client-side deadline overruns (not server 5xx)."""
    if _error_code(exc) is not None:
        return False
    if genai_errors is not None and isinstance(
        exc, genai_errors.ServerError
    ):
        return False
    name = type(exc).__name__
    if name in (
        "APITimeoutError",
        "TimeoutException",
        "ReadTimeout",
        "ConnectTimeout",
        "WriteTimeout",
        "PoolTimeout",
    ):
        return True
    if name == "TimeoutError":
        return True
    module = type(exc).__module__ or ""
    return module.startswith(("httpx", "httpcore")) and isinstance(
        exc, TimeoutError
    )


def _is_connection_failure(exc: Exception) -> bool:
    """True when the request never reached the provider."""
    if _error_code(exc) is not None:
        return False
    if isinstance(exc, (TimeoutError, OSError)):
        return True
    if genai_errors is not None and isinstance(
        exc, genai_errors.ServerError
    ):
        return False
    module = type(exc).__module__ or ""
    name = type(exc).__name__
    if module.startswith(("httpx", "httpcore", "requests", "urllib3")):
        return True
    return name in (
        "ConnectError",
        "NetworkError",
        "RemoteProtocolError",
        "TransportError",
        "ConnectionError",
        "APIConnectionError",
        "NoResponseError",
    )
