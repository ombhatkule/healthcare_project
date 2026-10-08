/// A single chat message in the AI Healthcare Assistant conversation.
///
/// Messages are scoped to the current session and belong to the
/// authenticated user. They are never persisted globally across users.
enum ChatMessageRole { user, assistant }

class ChatMessage {
  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  bool get isUser => role == ChatMessageRole.user;
  bool get isAssistant => role == ChatMessageRole.assistant;
}
