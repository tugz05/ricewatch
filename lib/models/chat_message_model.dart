/// A single chat message (user or assistant).
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isFreshResponse = false,
  });

  final int? id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  /// True only when just received from API; false when loaded from DB.
  final bool isFreshResponse;

  bool get isUser => role == 'user';

  ChatMessageModel copyWith({
    int? id,
    String? role,
    String? content,
    DateTime? createdAt,
    bool? isFreshResponse,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isFreshResponse: isFreshResponse ?? this.isFreshResponse,
    );
  }
}
