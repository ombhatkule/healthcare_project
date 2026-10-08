import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:healthcare_app/features/ai_assistant/presentation/providers/ai_assistant_controller.dart';
import 'package:healthcare_app/features/ai_assistant/presentation/widgets/widgets.dart';
import 'package:healthcare_app/features/ai_assistant/services/ai_assistant_service.dart';
import 'package:healthcare_app/features/ai_assistant/services/flask_ai_assistant_service.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'fake_ai_assistant_service.dart';
import 'fake_appointment_service.dart';
import 'fake_auth_service.dart';
import 'fake_medical_record_service.dart';
import 'fake_prescription_service.dart';

Widget _wrap(FakeAiAssistantService fake) {
  return _wrapService(fake);
}

/// Wraps the screen with an arbitrary [AiAssistantService], so the production
/// [FlaskAiAssistantService] can be exercised against a stubbed HTTP layer.
Widget _wrapService(AiAssistantService assistantService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(FakeAuthService()),
      ),
      ChangeNotifierProvider<AiAssistantController>(
        create: (_) => AiAssistantController(
          assistantService,
          medicalRecordService: FakeMedicalRecordService(),
          prescriptionService: FakePrescriptionService(),
          appointmentService: FakeAppointmentService(),
        ),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: const AiAssistantScreen()),
  );
}

void main() {
  testWidgets('AI Assistant screen opens and shows the greeting',
      (tester) async {
    await tester.pumpWidget(_wrap(FakeAiAssistantService()));
    await tester.pumpAndSettle();

    expect(find.text('AI Healthcare Assistant'), findsOneWidget);
    expect(find.textContaining('Hello!'), findsOneWidget);
    expect(
      find.textContaining('AI-generated information.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sending a message shows user bubble and assistant reply',
      (tester) async {
    await tester.pumpWidget(_wrap(FakeAiAssistantService()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField), 'What is in my prescription?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('What is in my prescription?'), findsOneWidget);
    expect(
      find.text('This is a fake assistant response.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty message is not sent', (tester) async {
    final fake = FakeAiAssistantService();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    final sendButton =
        tester.widget<IconButton>(find.ancestor(
      of: find.byIcon(Icons.send),
      matching: find.byType(IconButton),
    ));
    // Send button is disabled when the input is empty.
    expect(sendButton.onPressed, isNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.send),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(fake.lastMessage, isNull);
    expect(find.textContaining('Hello!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quick prompt chip sends a real query', (tester) async {
    final fake = FakeAiAssistantService();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next appointment'));
    await tester.pumpAndSettle();

    expect(fake.lastMessage, 'When is my next appointment?');
    expect(find.text('When is my next appointment?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI Assistant screen has no overflow on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(FakeAiAssistantService()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('New Chat action clears the conversation after confirmation',
      (tester) async {
    await tester.pumpWidget(_wrap(FakeAiAssistantService()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('fake assistant'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();
    // Confirm the clear dialog.
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Chat with your AI assistant'),
      findsOneWidget,
    );
    expect(find.text('hello'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // ------------------------------------------------------------------
  // Regression coverage: a non-network backend failure (e.g. HTTP 503 from an
  // unconfigured AI provider) used to produce no visible output at all, so the
  // chat looked permanently stuck after the user bubble.
  // ------------------------------------------------------------------
  testWidgets('Backend rejection is shown to the user, not swallowed',
      (tester) async {
    final fake = FakeAiAssistantService(
      shouldThrow: true,
      shouldBeNetworkError: false,
      failureMessage: 'The AI Assistant is currently unavailable. Please '
          'check the AI service configuration and try again.',
    );
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Make a diet plan for me');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // The user's message is still shown...
    expect(find.text('Make a diet plan for me'), findsOneWidget);
    // ...and so is the reason the assistant could not reply.
    expect(find.textContaining('AI Assistant is currently unavailable'),
        findsOneWidget);
    // No assistant bubble was invented, and the input is usable again.
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry is offered for a backend rejection and recovers',
      (tester) async {
    final fake = FakeAiAssistantService(
      shouldThrow: true,
      failureMessage: 'Too many requests. Please wait a moment and try again.',
    );
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    // The backend recovers; retrying succeeds.
    fake.shouldThrow = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('This is a fake assistant response.'), findsOneWidget);
    // The failed message is replaced, not duplicated.
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Network failure still shows the retry bar',
      (tester) async {
    final fake = FakeAiAssistantService(
      shouldThrow: true,
      shouldBeNetworkError: true,
      failureMessage: 'Unable to connect to the assistant.',
    );
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.textContaining('Unable to connect to the assistant'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  // ------------------------------------------------------------------
  // End-to-end coverage of the real Phase 14 chain:
  //   send button -> controller -> FlaskAiAssistantService -> HTTP
  //   -> (Flask /api/assistant/chat JSON) -> parse -> chat state -> bubble
  //
  // Only the HTTP transport is stubbed, so the exact JSON contract the Flask
  // backend returns is exercised. The response bodies below are copies of the
  // real backend payloads, not invented replies.
  // ------------------------------------------------------------------
  group('end-to-end through the real Flask service', () {
    testWidgets('a real 200 assistant payload renders an assistant bubble',
        (tester) async {
      late http.Request captured;

      final client = MockClient((request) async {
        captured = request;
        // Exactly what routes/assistant_routes.py returns on success.
        return http.Response(
          json.encode({
            'status': 'success',
            'response':
                'A balanced diet plan usually includes plenty of vegetables, '
                    'whole grains and lean protein.',
            'disclaimer': 'AI-generated information. Not a replacement for '
                'professional medical advice.',
            'model': 'llama-3.3-70b-versatile',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        _wrapService(FlaskAiAssistantService(client: client)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Make a diet plan for me');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Request shape matches what FlaskAiAssistantService always sent.
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/assistant/chat');
      expect(json.decode(captured.body)['message'],
          'Make a diet plan for me');

      // The assistant reply reached the chat state and the UI.
      expect(
        find.textContaining('A balanced diet plan usually includes'),
        findsOneWidget,
      );
      expect(_loadingIndicatorCleared(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the real backend 503 payload is shown instead of silence',
        (tester) async {
      final client = MockClient((request) async {
        // Exactly what routes/assistant_routes.py returns when the AI provider
        // is not configured.
        return http.Response(
          json.encode({
            'status': 'error',
            'message': 'The AI Assistant is currently unavailable. Please '
                'check the AI service configuration and try again.',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        _wrapService(FlaskAiAssistantService(client: client)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Make a diet plan for me');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // The user bubble is kept and the reason is now visible.
      expect(find.text('Make a diet plan for me'), findsOneWidget);
      expect(
        find.textContaining('AI Assistant is currently unavailable'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      // The medical disclaimer banner is never removed.
      expect(find.textContaining('AI-generated information.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a socket failure surfaces a retryable network message',
        (tester) async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      await tester.pumpWidget(
        _wrapService(FlaskAiAssistantService(client: client)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to connect to the assistant'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // Loading must have stopped, so the input is usable again: the send
      // button re-enables as soon as there is text and no request in flight.
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      final sendButton = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.send), matching: find.byType(IconButton)),
      );
      expect(sendButton.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}

/// True when no typing indicator remains, i.e. the loading state was reset.
bool _loadingIndicatorCleared(WidgetTester tester) =>
    find.byType(TypingIndicator).evaluate().isEmpty;