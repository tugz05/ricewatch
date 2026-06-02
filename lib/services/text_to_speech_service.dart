import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';

enum TtsPlayState { idle, loading, playing }

class TextToSpeechService extends ChangeNotifier {
  static final TextToSpeechService _instance = TextToSpeechService._();
  factory TextToSpeechService() => _instance;

  TextToSpeechService._() {
    _player.onPlayerComplete.listen((_) => _reset());
  }

  final AudioPlayer _player = AudioPlayer();
  TtsPlayState _state = TtsPlayState.idle;
  String? _currentKey;
  int _generation = 0;

  TtsPlayState get state => _state;
  String? get currentKey => _currentKey;

  @visibleForTesting
  static String cleanForSpeech(String md) => _stripMarkdown(md);

  Future<void> speak(String text, {String? key}) async {
    final gen = ++_generation;

    await _player.stop();

    _state = TtsPlayState.loading;
    _currentKey = key;
    notifyListeners();

    if (!hasOpenAiKey) {
      if (gen == _generation) _reset();
      return;
    }

    final plain = _stripMarkdown(text);
    if (plain.trim().isEmpty) {
      if (gen == _generation) _reset();
      return;
    }

    final input = plain.length > 4096 ? plain.substring(0, 4096) : plain;

    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/audio/speech'),
            headers: {
              'Authorization': 'Bearer $openAiApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'tts-1',
              'voice': 'nova',
              'speed': 0.9,
              'input': input,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (gen != _generation) return;

      if (response.statusCode != 200) {
        debugPrint('[TTS] API error: ${response.statusCode} ${response.body}');
        if (gen == _generation) _reset();
        return;
      }

      _state = TtsPlayState.playing;
      notifyListeners();

      await _player.play(BytesSource(response.bodyBytes));
    } catch (e) {
      debugPrint('[TTS] error: $e');
      if (gen == _generation) _reset();
    }
  }

  Future<void> stop() async {
    if (_state == TtsPlayState.idle) return;
    ++_generation;
    await _player.stop();
    _reset();
  }

  void _reset() {
    _state = TtsPlayState.idle;
    _currentKey = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  static String _stripMarkdown(String md) {
    return md
        // Fenced code blocks (must come before inline code)
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        // Inline code
        .replaceAllMapped(RegExp(r'`([^`\n]+)`'), (m) => m[1] ?? '')
        // Bold **text** and __text__
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1] ?? '')
        .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m[1] ?? '')
        // Italic *text* and _text_
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1] ?? '')
        .replaceAllMapped(RegExp(r'(?<!\w)_(.+?)_(?!\w)'), (m) => m[1] ?? '')
        // ATX headers (# through ######)
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        // Links [text](url) → text
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '')
        // Bullet list markers (- and *)
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
        // Numbered list markers
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        // Horizontal rules
        .replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '')
        // Dollar signs (avoid TTS saying "dollar")
        .replaceAll(r'$', '')
        // HTML entities
        .replaceAll('&nbsp;', ' ')
        // Collapse excessive newlines / spaces
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }
}
