import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/ai_assistant/models/chat_message.dart';
import 'package:healthcare_app/features/ai_assistant/services/assistant_request.dart';
import 'package:healthcare_app/features/ai_assistant/services/flask_ai_assistant_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ChatMessage', () {
    test('marks roles correctly', () {
      final user = ChatMessage(
        id: '1',
        role: ChatMessageRole.user,
        content: 'hello',
        timestamp: DateTime(2025),
      );
      final assistant = ChatMessage(
        id: '2',
        role: ChatMessageRole.assistant,
        content: 'hi',
        timestamp: DateTime(2025),
      );
      expect(user.isUser, isTrue);
      expect(user.isAssistant, isFalse);
      expect(assistant.isAssistant, isTrue);
      expect(assistant.isUser, isFalse);
    });
  });

  group('AssistantRequestPayload', () {
    test('serializes message and context', () {
      const payload = AssistantRequestPayload(
        message: 'hello',
        context: {'user': {'id': 'u1'}},
      );
      final json = payload.toJson();
      expect(json['message'], 'hello');
      expect((json['context'] as Map)['user'], {'id': 'u1'});
    });
  });

  group('FlaskAiAssistantService', () {
    FlaskAiAssistantService build(http.Client client) =>
        FlaskAiAssistantService(client: client);

    MockClient successClient() {
      return MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/assistant/chat');
        return http.Response(
          json.encode({
            'status': 'success',
            'response': 'Your next appointment is with Dr. X.',
            'disclaimer': 'AI-generated information.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
    }

    test('parses a successful response', () async {
      final result =
          await build(successClient()).sendMessage(message: 'Next appointment?');
      expect(result.response, contains('Dr. X'));
      expect(result.disclaimer, contains('AI-generated'));
    });

    test('empty message is rejected before hitting the network', () async {
      await expectLater(
        build(successClient()).sendMessage(message: '   '),
        throwsA(isA<AssistantRequestException>()),
      );
    });

    test('overly long message is rejected', () async {
      await expectLater(
        build(successClient()).sendMessage(message: 'a' * 2001),
        throwsA(isA<AssistantRequestException>()),
      );
    });

    test('backend error response maps to a safe message', () async {
      final client = MockClient((request) async {
        return http.Response(
          json.encode({
            'status': 'error',
            'message': 'Message must not be empty',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      await expectLater(
        build(client).sendMessage(message: 'hello'),
        throwsA(predicate<AssistantRequestException>(
          (e) => e.message.contains('Message must not be empty'),
        )),
      );
    });

    test('invalid/empty AI response is surfaced as a friendly error',
        () async {
      final client = MockClient((request) async {
        return http.Response(
          json.encode({'status': 'success', 'response': ''}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      await expectLater(
        build(client).sendMessage(message: 'hi'),
        throwsA(predicate<AssistantRequestException>(
          (e) => e.message.contains("couldn't generate"),
        )),
      );
    });

    test('network errors become a friendly connection message', () async {
      final client = MockClient((request) async {
        throw http.ClientException('connection refused');
      });
      await expectLater(
        build(client).sendMessage(message: 'hi'),
        throwsA(predicate<AssistantRequestException>((e) => e.isNetwork)),
      );
    });

    test('non-JSON server body does not crash and produces a safe error',
        () async {
      final client = MockClient((request) async {
        return http.Response('<!DOCTYPE html>', 502);
      });
      await expectLater(
        build(client).sendMessage(message: 'hi'),
        throwsA(isA<AssistantRequestException>()),
      );
    });

    // ------------------------------------------------------------------
    // HTTP status coverage. Every non-200 must produce a distinct, actionable
    // message — none may be silently ignored or leave the chat waiting.
    //
    // The body deliberately omits "message" so the status-code mapping is the
    // code path under test. (A backend-supplied message taking precedence is
    // covered separately by 'backend error response maps to a safe message'.)
    // ------------------------------------------------------------------
    MockClient statusClient(int status, {String? body}) => MockClient(
          (request) async => http.Response(
            body ?? json.encode({'status': 'error'}),
            status,
            headers: {'content-type': 'application/json'},
          ),
        );

    test('503 unconfigured provider surfaces a clear message', () async {
      await expectLater(
        build(statusClient(503)).sendMessage(message: 'Hello'),
        throwsA(predicate<AssistantRequestException>((e) {
          expect(e.isNetwork, isFalse);
          expect(e.message, contains('AI Assistant is currently unavailable'));
          return true;
        })),
      );
    });

    test('429 rate limit surfaces a clear message', () async {
      await expectLater(
        build(statusClient(429)).sendMessage(message: 'Hello'),
        throwsA(predicate<AssistantRequestException>(
          (e) => e.message.contains('Too many requests'),
        )),
      );
    });

    test('404 endpoint misconfiguration surfaces a clear message', () async {
      await expectLater(
        build(statusClient(404, body: '<!DOCTYPE html>')).sendMessage(
              message: 'Hello',
            ),
        throwsA(predicate<AssistantRequestException>(
          (e) => e.message.contains('could not be found on the server'),
        )),
      );
    });

    test('401/403 surface an authorization message', () async {
      for (final status in [401, 403]) {
        await expectLater(
          build(statusClient(status, body: 'unauthorized')).sendMessage(
                message: 'Hello',
              ),
          throwsA(predicate<AssistantRequestException>(
            (e) => e.message.contains('not authorized'),
          )),
        );
      }
    });

    test('408 request timeout surfaces a clear message', () async {
      await expectLater(
        build(statusClient(408, body: 'timeout')).sendMessage(message: 'Hello'),
        throwsA(predicate<AssistantRequestException>(
          (e) => e.message.contains('taking too long'),
        )),
      );
    });

    test('400 bad request surfaces a clear message', () async {
      await expectLater(
        build(statusClient(400, body: 'bad')).sendMessage(message: 'Hello'),
        throwsA(predicate<AssistantRequestException>(
          (e) => e.message.contains('valid message'),
        )),
      );
    });

    test('the request timeout is bounded so the future cannot hang forever',
        () {
      // Guards the "never hang forever" requirement without a real socket.
      expect(
        FlaskAiAssistantService.requestTimeout,
        greaterThan(const Duration(seconds: 30)),
      );
      expect(
        FlaskAiAssistantService.requestTimeout,
        lessThan(const Duration(seconds: 60)),
      );
    });
  });
}