import 'package:healthcare_app/features/ai_assistant/services/ai_assistant_service.dart';
import 'package:healthcare_app/features/ai_assistant/services/assistant_request.dart';

/// An in-memory fake [AiAssistantService] for unit and widget tests that
/// avoids the Flask backend.
class FakeAiAssistantService implements AiAssistantService {
  FakeAiAssistantService({
    this.response = 'This is a fake assistant response.',
    this.shouldThrow = false,
    this.shouldBeNetworkError = false,
    this.failureMessage = 'Assistant request failed.',
  });

  /// The canned response returned when no error is configured.
  final String response;

  /// When true, [sendMessage] throws an [AssistantRequestException].
  /// Mutable so tests can simulate recovery.
  bool shouldThrow;
  bool shouldBeNetworkError;
  String failureMessage;

  /// Records the last received message and context for assertions.
  String? lastMessage;
  Map<String, dynamic>? lastContext;

  @override
  Future<AssistantResult> sendMessage({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    lastMessage = message;
    lastContext = context;
    if (shouldThrow) {
      throw AssistantRequestException(
        message: failureMessage,
        isNetwork: shouldBeNetworkError,
      );
    }
    return AssistantResult(response: response, disclaimer: 'Disclaimer');
  }
}