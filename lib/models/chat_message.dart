import 'scripture.dart';

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<ScriptureQuote> scriptures;
  final bool isStreaming;
  final bool isVoice;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.scriptures = const [],
    this.isStreaming = false,
    this.isVoice = true,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  ChatMessage copyWith({
    String? content,
    List<ScriptureQuote>? scriptures,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      scriptures: scriptures ?? this.scriptures,
      isStreaming: isStreaming ?? this.isStreaming,
      isVoice: isVoice,
    );
  }
}
