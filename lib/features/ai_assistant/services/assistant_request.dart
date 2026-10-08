/// Represents an error raised while talking to the AI assistant backend.
///
/// Only ever carries a safe, user-friendly [message]. Provider/internal
/// error details and API keys are never propagated to the UI.
class AssistantRequestException implements Exception {
  final String message;
  final bool isNetwork;

  const AssistantRequestException({
    required this.message,
    this.isNetwork = false,
  });

  @override
  String toString() => 'AssistantRequestException: $message';
}

/// Unified request payload sent to the Flask AI gateway.
class AssistantRequestPayload {
  final String message;
  final Map<String, dynamic>? context;

  const AssistantRequestPayload({
    required this.message,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'context': context,
      };
}