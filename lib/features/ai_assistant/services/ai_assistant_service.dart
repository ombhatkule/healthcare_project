/// Response result from the AI assistant backend.
class AssistantResult {
  final String response;
  final String disclaimer;

  const AssistantResult({
    required this.response,
    required this.disclaimer,
  });
}

/// Abstract contract for the AI Healthcare Assistant service.
///
/// Implementations talk to an AI provider backend. The real implementation
/// routes requests through the Flask backend (`POST /api/assistant/chat`)
/// which owns the Google Gemini API key, keeping secrets out of the Flutter app.
abstract class AiAssistantService {
  /// Sends a chat [message] plus a structured [context] (EHR, prescriptions,
  /// appointments) to the AI provider and returns the assistant response.
  ///
  /// Throws an [AssistantRequestException] with a user-friendly message when
  /// the request cannot be completed.
  Future<AssistantResult> sendMessage({
    required String message,
    Map<String, dynamic>? context,
  });
}