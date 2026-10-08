"""Tests for the POST /api/assistant/chat endpoint.

These tests use Flask's test client. Because the Gemini API key is never
stored in the repository, the "configured path" (a real AI reply) cannot be
exercised here; instead the tests verify the request validation contract, the
safe not-configured response, and that the assistant blueprint is registered
without breaking the existing prediction endpoints.

The success path is covered with a stubbed SDK client (``_get_client`` is
replaced), which proves the outgoing request shape and the response contract
the Flutter client parses — without any network access and without a real
key. Mocks are used here only, never in production code.

To test against a real key locally, set GEMINI_API_KEY in backend/.env.
"""

import json
import os
import sys
import unittest
from unittest import mock

import httpx
from google.genai import errors as genai_errors
from google.genai._gaos.lib import compat_errors

_BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _BACKEND_DIR not in sys.path:
    sys.path.insert(0, _BACKEND_DIR)

from app import app  # noqa: E402
from config.config import Config  # noqa: E402
from routes import assistant_routes  # noqa: E402
from services import gemini_service  # noqa: E402


class AssistantApiTest(unittest.TestCase):
    # A placeholder credential stands in for the real key so no secret is
    # ever involved. Gemini keys are never printed or returned to the client.
    _PLACEHOLDER_KEY = "AIza_test_placeholder_key_not_a_real_secret"

    @classmethod
    def setUpClass(cls):
        cls.client = app.test_client()

    def setUp(self):
        # The per-IP rate limiter is module-level state; clear it so each test
        # starts clean instead of inheriting the previous test's budget.
        assistant_routes._rate_hits.clear()
        gemini_service._reset_client_cache()

    # ------------------------------------------------------------------
    # Request validation
    # ------------------------------------------------------------------
    def test_empty_message_rejected(self):
        resp = self.client.post(
            "/api/assistant/chat", json={"message": "   "}
        )
        self.assertEqual(resp.status_code, 400)
        data = resp.get_json()
        self.assertEqual(data["status"], "error")

    def test_missing_message_rejected(self):
        resp = self.client.post("/api/assistant/chat", json={})
        self.assertEqual(resp.status_code, 400)

    def test_non_json_body_rejected(self):
        resp = self.client.post(
            "/api/assistant/chat",
            data="not json",
            content_type="text/plain",
        )
        self.assertEqual(resp.status_code, 400)

    def test_long_message_rejected(self):
        long_message = "a" * 3000
        resp = self.client.post(
            "/api/assistant/chat", json={"message": long_message}
        )
        self.assertEqual(resp.status_code, 400)

    def test_invalid_context_rejected(self):
        resp = self.client.post(
            "/api/assistant/chat",
            json={"message": "hello", "context": "not-a-dict"},
        )
        self.assertEqual(resp.status_code, 400)

    # ------------------------------------------------------------------
    # Not-configured path (no GEMINI_API_KEY in CI)
    # ------------------------------------------------------------------
    def test_no_api_key_returns_safe_error(self):
        with mock.patch.object(Config, "GEMINI_API_KEY", ""):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "What is a headache?"}
            )

        self.assertEqual(resp.status_code, 503)
        data = resp.get_json()
        self.assertEqual(data["status"], "error")
        # The safe message must never leak the key or mention provider secrets.
        self.assertNotIn("GEMINI_API_KEY", data["message"])
        self.assertNotIn("api_key", data["message"].lower())
        self.assertNotIn("Bearer", data["message"])

    def test_missing_sdk_maps_to_safe_error(self):
        """A broken/absent install must answer 503, never crash Flask."""
        with mock.patch.object(Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY), \
                mock.patch.object(gemini_service, "genai", None):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 503)
        self.assertEqual(resp.get_json()["status"], "error")

    # ------------------------------------------------------------------
    # Existing endpoints must still work
    # ------------------------------------------------------------------
    def test_health_endpoint_still_works(self):
        resp = self.client.get("/api/health")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["status"], "success")

    def test_symptoms_endpoint_still_works(self):
        resp = self.client.get("/api/symptoms")
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["status"], "success")
        self.assertIn("symptoms", data)

    # ------------------------------------------------------------------
    # Success path with a stubbed AI provider.
    #
    # This is what verifies the contract the Flutter client depends on:
    #   request  -> {"message": ..., "context": {...}}
    #   response -> {"status": "success", "response": ..., "disclaimer": ...}
    # ------------------------------------------------------------------
    def _stub_provider(self, captured, content="Hello from the provider."):
        """Replace the Gemini client with a fake that records the request."""

        class _FakeResponse:
            text = content
            candidates = []

        class _FakeModels:
            def generate_content(self, **kwargs):
                captured.clear()
                captured.update(kwargs)
                return _FakeResponse()

        class _FakeClient:
            models = _FakeModels()

        return mock.patch.object(
            gemini_service, "_get_client", lambda api_key: _FakeClient()
        )

    def _stub_provider_error(self, exc):
        """Make the fake provider raise the given SDK exception."""

        class _FakeModels:
            def generate_content(self, **kwargs):
                raise exc

        class _FakeClient:
            models = _FakeModels()

        return mock.patch.object(
            gemini_service, "_get_client", lambda api_key: _FakeClient()
        )

    def _api_error(self, status_code, message="boom"):
        """Build the error class the SDK raises for generate_content calls."""
        request = httpx.Request(
            "POST",
            "https://generativelanguage.googleapis.com/v1beta/models/"
            "gemini-3.6-flash:generateContent",
        )
        body = {"error": {"code": status_code, "message": message,
                          "status": "PROBLEM"}}
        response = httpx.Response(status_code, request=request, json=body)
        return compat_errors.APIError.generate(status_code, body, None,
                                               response)

    def test_success_returns_response_and_disclaimer(self):
        captured = {}
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider(captured):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        # Exactly what FlaskAiAssistantService._handleResponse parses.
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["response"], "Hello from the provider.")
        self.assertIn("disclaimer", data)
        self.assertIn("Not a replacement for professional medical advice",
                      data["disclaimer"])

    def test_request_reaches_provider_with_expected_shape(self):
        captured = {}
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider(captured):
            resp = self.client.post(
                "/api/assistant/chat",
                json={"message": "What is asthma?", "context": {"age": 30}},
            )

        self.assertEqual(resp.status_code, 200)

        # The configured model is sent to the official Gemini SDK.
        self.assertEqual(
            captured["model"], assistant_routes._CONFIG.GEMINI_MODEL
        )

        # The provider credential travels as the SDK's api_key only.
        body = resp.get_json()
        serialized = json.dumps(body).lower()
        self.assertNotIn("authorization", serialized)
        self.assertNotIn(self._PLACEHOLDER_KEY.lower(), serialized)

        # System prompt carries the medical safety instructions.
        system_instruction = captured["config"].system_instruction
        self.assertIn("diagnos", system_instruction.lower())

        # The user turn carries the message and the supplied context.
        self.assertIn("What is asthma?", captured["contents"])

        # Output is bounded so a runaway generation cannot flood the client.
        self.assertGreater(captured["config"].max_output_tokens, 0)

    def test_calls_standard_generation_api_not_interactions(self):
        """The route must go through models.generate_content, nothing else."""

        class _OnlyModels:
            def generate_content(self, **kwargs):
                return type("_Resp", (), {"text": "ok", "candidates": []})()

        class _Client:
            models = _OnlyModels()

            def __getattr__(self, name):  # any other surface is a bug
                raise AssertionError(f"unexpected SDK surface: {name}")

        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), mock.patch.object(
            gemini_service, "_get_client", lambda api_key: _Client()
        ):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["response"], "ok")

    def test_transport_sets_timeout_and_bounded_retries(self):
        """The client must never hang, and retries must stay bounded."""
        http_options = gemini_service.build_http_options()

        # A per-attempt timeout is always set, so a request can never hang.
        self.assertIsNotNone(http_options.timeout)
        self.assertGreater(http_options.timeout, 0)

        retry = http_options.retry_options
        self.assertGreaterEqual(retry.attempts, 1)
        self.assertLessEqual(retry.attempts, 4)
        self.assertIn(503, retry.http_status_codes)
        # A 429 must not be retried: it would only make the user wait longer
        # for an answer that will not change.
        self.assertNotIn(429, retry.http_status_codes)

    def test_total_budget_stays_inside_the_flutter_timeout(self):
        """Retries must not outlive the Flutter client's 45s request timeout."""
        per_attempt_seconds, attempts = gemini_service._retry_budget()
        backoff_reserve = 2.0 * (attempts - 1)
        self.assertLessEqual(per_attempt_seconds * attempts + backoff_reserve, 45)

    def test_configured_model_is_a_supported_gemini_model(self):
        """Guard against retired or misspelled model identifiers."""
        model = assistant_routes._CONFIG.GEMINI_MODEL
        self.assertTrue(model.strip())
        self.assertTrue(
            model.startswith("gemini-"),
            f"GEMINI_MODEL must be a Gemini model id, got {model!r}",
        )
        # Preview/proxy ids that need a paid tier or were retired.
        for retired in ("gemini-1.0", "gemini-1.5", "text-bison", "ultra"):
            self.assertNotIn(retired, model)

    def test_outgoing_payload_uses_the_configured_model(self):
        captured = {}
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider(captured):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 200)
        self.assertEqual(
            captured["model"],
            assistant_routes._CONFIG.GEMINI_MODEL,
        )

    def test_provider_auth_failure_maps_to_503(self):
        exc = self._api_error(401, "API key not valid.")
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider_error(exc):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 503)
        data = resp.get_json()
        self.assertEqual(data["status"], "error")
        self.assertNotIn(self._PLACEHOLDER_KEY, json.dumps(data))

    def test_provider_rate_limit_maps_to_429(self):
        exc = self._api_error(429, "Quota exceeded.")
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider_error(exc):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 429)

    def test_second_error_hierarchy_is_also_mapped(self):
        """The SDK's other error classes (with `.code`) map the same way."""
        cases = [
            (genai_errors.ClientError(401, {"error": {"message": "no"}}), 503),
            (genai_errors.ClientError(404, {"error": {"message": "no"}}), 503),
            (genai_errors.ClientError(429, {"error": {"message": "no"}}), 429),
            (genai_errors.ServerError(500, {"error": {"message": "no"}}), 503),
            (genai_errors.ServerError(503, {"error": {"message": "no"}}), 503),
        ]
        for exc, expected in cases:
            with self.subTest(expected=expected):
                with mock.patch.object(
                    Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
                ), self._stub_provider_error(exc):
                    resp = self.client.post(
                        "/api/assistant/chat", json={"message": "Hello"}
                    )
                self.assertEqual(resp.status_code, expected)
                self.assertEqual(resp.get_json()["status"], "error")

    def test_provider_busy_503_is_distinct_from_auth_failure(self):
        """A provider outage and a bad key must not read the same to users."""
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider_error(
            genai_errors.ServerError(
                503,
                {"error": {"message": "This model is currently experiencing "
                           "high demand."}},
            )
        ):
            busy = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider_error(
            genai_errors.ClientError(
                401, {"error": {"message": "API key not valid."}}
            )
        ):
            auth = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(busy.status_code, 503)
        self.assertEqual(auth.status_code, 503)
        busy_message = busy.get_json()["message"].lower()
        auth_message = auth.get_json()["message"].lower()
        self.assertIn("busy", busy_message)
        self.assertNotIn("busy", auth_message)
        self.assertIn("configuration", auth_message)
        # Neither message may leak provider internals or the key.
        for payload in (busy.get_json(), auth.get_json()):
            serialized = json.dumps(payload).lower()
            self.assertNotIn(self._PLACEHOLDER_KEY.lower(), serialized)
            self.assertNotIn("high demand", serialized)
            self.assertNotIn("traceback", serialized)

    def test_unknown_model_maps_to_safe_503(self):
        """A retired/misspelled model id must answer 503, never a raw 404."""
        exc = self._api_error(404, "models/gemini-2.5-flash is no longer "
                                   "available to new users.")
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider_error(exc):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 503)
        self.assertEqual(resp.get_json()["status"], "error")
        self.assertNotIn("no longer available", resp.get_json()["message"])

    def test_provider_timeout_maps_to_safe_error(self):
        """A hung request surfaces as a friendly message, never a stack trace."""
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider_error(TimeoutError("timed out")):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 504)
        data = resp.get_json()
        self.assertEqual(data["status"], "error")
        self.assertIn("too long", data["message"].lower())
        self.assertNotIn("traceback", json.dumps(data).lower())

    def test_empty_provider_output_maps_to_502(self):
        captured = {}
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider(captured, content="   "):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "Hello"}
            )

        self.assertEqual(resp.status_code, 502)
        self.assertEqual(resp.get_json()["status"], "error")

    def test_unsafe_provider_output_is_replaced_by_safety_filter(self):
        captured = {}
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider(
            captured, content="Based on this, you have a confirmed diagnosis."
        ):
            resp = self.client.post(
                "/api/assistant/chat", json={"message": "What is it?"}
            )

        self.assertEqual(resp.status_code, 200)
        reply = resp.get_json()["response"].lower()
        self.assertNotIn("confirmed diagnosis", reply)
        self.assertIn("qualified healthcare professional", reply)

    def test_rate_limiter_rejects_bursts(self):
        captured = {}
        limit = assistant_routes._CONFIG.ASSISTANT_RATE_LIMIT_PER_MINUTE
        statuses = []
        with mock.patch.object(
            Config, "GEMINI_API_KEY", self._PLACEHOLDER_KEY
        ), self._stub_provider(captured):
            for _ in range(limit + 2):
                statuses.append(
                    self.client.post(
                        "/api/assistant/chat", json={"message": "Hello"}
                    ).status_code
                )

        self.assertIn(429, statuses)
        self.assertEqual(statuses[:limit], [200] * limit)


if __name__ == "__main__":
    unittest.main()
