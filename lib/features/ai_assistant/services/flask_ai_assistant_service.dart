import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors/exceptions.dart';
import '../../../shared/services/base_service.dart';
import 'ai_assistant_service.dart';
import 'assistant_request.dart';

/// Real implementation of [AiAssistantService] routed through the Flask
/// backend (`POST /api/assistant/chat`).
///
/// The Flask endpoint owns the Google Gemini API key, so no key ever appears
/// in the Flutter source code or is stored on the device. The Flutter app only
/// sends the user message plus a minimal, user-scoped context JSON blob and
/// receives back the assistant response and a safety disclaimer.
///
/// All provider/internal errors are converted to safe, user-friendly
/// messages. Raw response bodies and API keys are never shown to the user.
class FlaskAiAssistantService extends BaseService implements AiAssistantService {
  static const String _unreachableMessage =
      'Unable to connect to the assistant. Please check your internet '
      'connection and try again.';

  static const String _invalidResponseMessage =
      "Sorry, I couldn't generate a response right now. Please try again.";

  static const String _timeoutMessage =
      'The AI Assistant is taking too long to respond. Please try again.';

  /// Maximum allowed message length (in characters).
  static const int maxMessageLength = 2000;

  /// Request timeout for the AI request.
  ///
  /// Deliberately longer than the backend's own Gemini budget (30s) so a slow
  /// or failing provider produces the backend's specific error message instead
  /// of an opaque client-side timeout.
  static const Duration requestTimeout = Duration(seconds: 45);

  /// Whether to emit the temporary stage-by-stage trace of the request flow.
  ///
  /// Enabled with `--dart-define=AI_DEBUG=true`. Messages only ever contain the
  /// endpoint, the message length and the status code — never the message body,
  /// the user context or any credential.
  static const bool _debug = bool.fromEnvironment('AI_DEBUG');

  void _log(String stage, [String? detail]) {
    if (!_debug) return;
    debugPrint('DEBUG AI: $stage${detail == null ? '' : ' | $detail'}');
  }

  final http.Client _client;

  /// [client] is injectable so unit tests can run against a mocked HTTP layer
  /// without a running Flask server.
  FlaskAiAssistantService({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<AssistantResult> sendMessage({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final trimmed = message.trim();
    _log('sendMessage called', 'length=${trimmed.length}');

    if (trimmed.isEmpty) {
      throw const AssistantRequestException(message: 'Please enter a message.');
    }
    if (trimmed.length > maxMessageLength) {
      throw const AssistantRequestException(
        message: 'Your message is too long. Please shorten it and try again.',
      );
    }

    final uri = Uri.parse('$baseUrl/assistant/chat');
    final payload = AssistantRequestPayload(
      message: trimmed,
      context: context,
    );

    _log('AI REQUEST URL: $uri');
    _log('AI REQUEST SENT: YES '
        '(POST, message=${trimmed.length} chars, '
        'context=${context == null ? 'null' : 'present'})');

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload.toJson()),
          )
          .timeout(requestTimeout);

      _log('AI HTTP STATUS: ${response.statusCode}');

      return _handleResponse(response);
    } on TimeoutException {
      _log('AI HTTP STATUS: NONE (timeout after ${requestTimeout.inSeconds}s)');
      throw const AssistantRequestException(
        message: _timeoutMessage,
        isNetwork: true,
      );
    } on SocketException catch (e) {
      _log('AI HTTP STATUS: NONE (socket '
          'osErrorCode=${e.osError?.errorCode})');
      throw const AssistantRequestException(
        message: _unreachableMessage,
        isNetwork: true,
      );
    } on http.ClientException catch (e) {
      _log('AI HTTP STATUS: NONE (client error: ${e.message})');
      throw const AssistantRequestException(
        message: _unreachableMessage,
        isNetwork: true,
      );
    } on AssistantRequestException {
      rethrow;
    } on AppException catch (e) {
      throw AssistantRequestException(message: e.message);
    } on FormatException {
      _log('AI RESPONSE RECEIVED: NO (body was not valid JSON)');
      throw const AssistantRequestException(message: _invalidResponseMessage);
    } catch (e) {
      _log('Unexpected error', e.runtimeType.toString());
      throw const AssistantRequestException(message: _invalidResponseMessage);
    }
  }

  /// Interprets the Flask response into an [AssistantResult] or throws a
  /// user-friendly [AssistantRequestException].
  AssistantResult _handleResponse(http.Response response) {
    final body = _decodeMap(response.body);
    _log('AI RESPONSE RECEIVED: ${body != null ? 'YES' : 'NO'} '
        '(JSON object: ${body != null}, body bytes: ${response.body.length})');

    if (response.statusCode == 200 && body?['status'] == 'success') {
      final reply = (body!['response'] as String?)?.trim();
      final disclaimer = (body['disclaimer'] as String?)?.trim() ?? '';
      if (reply == null || reply.isEmpty) {
        _log('AI RESPONSE PARSED: NO (success status but empty "response")');
        throw const AssistantRequestException(
          message: _invalidResponseMessage,
        );
      }
      _log('AI RESPONSE PARSED: YES (chars=${reply.length}, '
          'disclaimer=${disclaimer.isEmpty ? 'none' : 'present'})');
      return AssistantResult(response: reply, disclaimer: disclaimer);
    }

    _log('AI RESPONSE PARSED: NO '
        '(status=${response.statusCode}, backend status field='
        '${body?['status'] ?? 'absent'})');
    throw AssistantRequestException(
      message: _errorMessage(body ?? const {}, response.statusCode),
    );
  }

  /// Decodes a JSON object body, or null when the body is not a JSON object.
  Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Non-JSON body (e.g. an HTML error page) — fall through to status-code
      // messaging in _handleResponse.
    }
    return null;
  }

  /// Builds a safe, user-facing message from a backend error response.
  ///
  /// A `message` supplied by the backend wins, because it is already safe and
  /// user-facing (see `routes/assistant_routes.py`); it never contains the
  /// provider key or raw provider output.
  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final message = body['message'] as String?;
    if (message != null && message.isNotEmpty) return message;

    switch (statusCode) {
      case 400:
        return 'Please enter a valid message.';
      case 401:
      case 403:
        return 'You are not authorized to use the AI Assistant. Please sign '
            'in again.';
      case 404:
        return 'The assistant service could not be found on the server. '
            'Please check the backend setup.';
      case 408:
        return _timeoutMessage;
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 503:
        return 'The AI Assistant is currently unavailable. Please check the '
            'AI service configuration and try again.';
      case 500:
      case 502:
        return _invalidResponseMessage;
      default:
        return _invalidResponseMessage;
    }
  }
}