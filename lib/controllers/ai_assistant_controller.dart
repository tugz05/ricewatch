import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../services/chat_database_service.dart';
import '../services/openai_chat_service.dart';
import '../core/constants/api_config.dart';

/// Controller for AI Assistant: messages, loading, send, load from DB.
class AiAssistantController extends ChangeNotifier {
  List<ChatMessageModel> _messages = [];
  bool _loading = false;
  String? _error;
  /// Key of the last assistant message that already finished typewriter (so we don't re-animate on return).
  String? _typewriterCompletedKey;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasApiKey => hasOpenAiKey;
  String? get typewriterCompletedKey => _typewriterCompletedKey;

  void markTypewriterCompleted(String messageKey) {
    if (_typewriterCompletedKey == messageKey) return;
    _typewriterCompletedKey = messageKey;
    notifyListeners();
  }

  AiAssistantController() {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    _messages = await ChatDatabaseService.getAllMessages();
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!hasOpenAiKey) {
      _error = 'Walay OpenAI API key. I-set sa app config.';
      notifyListeners();
      return;
    }

    final userMsg = ChatMessageModel(
      id: null,
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    _loading = true;
    _error = null;
    notifyListeners(); // Show user message and loading immediately

    try {
      await ChatDatabaseService.insertMessage(userMsg);
      final result = await OpenAIChatService.sendMessage(_messages, trimmed);

      if (result.isSuccess && result.content != null) {
        final assistantMsg = ChatMessageModel(
          id: null,
          role: 'assistant',
          content: result.content!,
          createdAt: DateTime.now(),
          isFreshResponse: true, // New response → run typewriter
        );
        _messages.add(assistantMsg);
        _typewriterCompletedKey = null;
        await ChatDatabaseService.insertMessage(assistantMsg);
        _error = null;
      } else {
        _error = result.error ?? "Wala'y response. Susihi ang API key o koneksyon.";
      }
    } catch (e, stack) {
      _error = 'Error: ${e.toString()}';
      assert(() {
        // ignore: avoid_print
        print('AiAssistant sendMessage error: $e\n$stack');
        return true;
      }());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    await ChatDatabaseService.clearAll();
    _messages = [];
    _error = null;
    notifyListeners();
  }
}
