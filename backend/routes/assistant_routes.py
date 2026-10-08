"""AI Healthcare Assistant route (Phase 14).

Provides:
  POST /api/assistant/chat

The Flutter app sends the authenticated user's message plus a minimal,
user-scoped context JSON blob. This gateway owns the Gemini API key, so no key
ever leaves the backend. Responses are filtered for safety before returning.

Medical privacy: this module NEVER logs the context (medical data). Only the
message length / status is logged at info level.
"""

import json
import logging
import time
from collections import defaultdict

from flask import Blueprint, jsonify, request

from config.config import get_config
from services.assistant_prompt import ASSISTANT_SYSTEM_PROMPT
from services.gemini_service import (
    NOT_CONFIGURED_MESSAGE as _NOT_CONFIGURED_MESSAGE,
    GeminiUnavailableError,
    generate_reply,
)

logger = logging.getLogger(__name__)

assistant_bp = Blueprint("assistant", __name__)

_CONFIG = get_config()

# Simple in-memory per-IP rate limiter (best-effort, dev protection).
_rate_hits: dict[str, list[float]] = defaultdict(list)


def _is_rate_limited(client_ip: str) -> bool:
    """Return True when [client_ip] has exceeded the per-minute limit."""
    now = time.time()
    window = 60.0
    hits = _rate_hits[client_ip]
    hits[:] = [h for h in hits if now - h < window]
    if len(hits) >= _CONFIG.ASSISTANT_RATE_LIMIT_PER_MINUTE:
        return True
    hits.append(now)
    return False


@assistant_bp.route("/api/assistant/chat", methods=["POST"])
def assistant_chat():
    """Handle a chat request from the authenticated user.

    Request:
      {"message": "<text>", "context": {...}}   context is optional.

    Response:
      {"status": "success", "response": "<text>", "disclaimer": "<text>"}
    """
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
    except Exception:  # noqa: BLE001 - malformed JSON
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

    # --- Validate message ----------------------------------------------
    message = data.get("message")
    if not isinstance(message, str) or message.strip() == "":
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Message must not be empty",
                }
            ),
            400,
        )

    message = message.strip()
    if len(message) > _CONFIG.ASSISTANT_MAX_MESSAGE_LENGTH:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Message is too long. Please shorten it and "
                    "try again.",
                }
            ),
            400,
        )

    # --- Validate context ----------------------------------------------
    context = data.get("context")
    if context is not None and not isinstance(context, dict):
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "'context' must be a JSON object",
                }
            ),
            400,
        )

    # --- Rate limit ----------------------------------------------------
    client_ip = request.remote_addr or "unknown"
    if _is_rate_limited(client_ip):
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Too many requests. Please wait a moment and "
                    "try again.",
                }
            ),
            429,
        )

    # --- Verify Gemini key is configured --------------------------------
    if not _CONFIG.GEMINI_API_KEY:
        logger.warning(
            "Assistant request REJECTED before reaching the AI provider: "
            "GEMINI_API_KEY is missing or empty. Set it in backend/.env and "
            "restart Flask. (The key value is never logged.)"
        )
        return (
            jsonify(
                {
                    "status": "error",
                    "message": _NOT_CONFIGURED_MESSAGE,
                }
            ),
            503,
        )

    # Log only non-sensitive metadata, never the context payload.
    logger.info(
        "Assistant request: len=%d context=%s",
        len(message),
        "yes" if context else "no",
    )

    try:
        ai_response = generate_reply(
            ASSISTANT_SYSTEM_PROMPT, _build_user_message(message, context)
        )
    except GeminiUnavailableError as exc:
        logger.warning("Gemini call failed: %s", exc.user_message)
        return (
            jsonify(
                {
                    "status": "error",
                    "message": exc.user_message,
                }
            ),
            exc.status_code,
        )

    # --- Safety filter on the generated response -----------------------
    reply = ai_response
    if not reply or not reply.strip():
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Sorry, I couldn't generate a response right "
                    "now. Please try again.",
                }
            ),
            502,
        )

    if _contains_prohibited_claim(reply):
        logger.warning(
            "Assistant response replaced by the safety filter "
            "(prohibited claim detected)"
        )
        reply = (
            "I can only provide general, informational guidance and explain "
            "the information you have stored in this app. For a diagnosis or "
            "specific medical advice, please consult a qualified healthcare "
            "professional."
        )

    logger.info("FLASK RESPONSE SENT: status=200 chars=%d", len(reply))

    return (
        jsonify(
            {
                "status": "success",
                "response": reply,
                "disclaimer": (
                    "AI-generated information. Not a replacement for "
                    "professional medical advice."
                ),
                "model": _CONFIG.GEMINI_MODEL,
            }
        ),
        200,
    )


def _build_user_message(message: str, context: dict | None) -> str:
    """Compose the user turn: the question plus any supplied context."""
    if not context:
        return message
    # The context contains only the authenticated user's own data. It is
    # serialized into the prompt so the model can answer from stored records.
    try:
        context_text = json.dumps(context, ensure_ascii=False)
    except Exception:  # noqa: BLE001 - never crash on serialization
        return message
    return (
        "The following JSON is the authenticated user's own stored health "
        "context (records, prescriptions, appointments). Use it ONLY to "
        "answer questions about the user's own data. Do not mention data "
        "that is not present.\n\n"
        "USER CONTEXT:\n"
        f"{context_text}\n\n"
        f"QUESTION:\n{message}"
    )


def _contains_prohibited_claim(text: str) -> bool:
    """Defensive check: reject obvious unsafe claims in the AI response."""
    lower = text.lower()
    prohibited = [
        "confirmed diagnosis",
        "i am a doctor",
        "i'm a doctor",
        "i am your doctor",
    ]
    return any(p in lower for p in prohibited)