import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      if (!kIsWeb) {
        // Android: prefer Google TTS engine for best language coverage.
        try {
          final engines = await _tts.getEngines as List?;
          final google = (engines ?? [])
              .map((e) => e?.toString() ?? '')
              .firstWhere((s) => s.toLowerCase().contains('google'), orElse: () => '');
          if (google.isNotEmpty) await _tts.setEngine(google);
        } catch (_) {}

        // iOS: allow audio to mix with other sounds.
        try {
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        } catch (_) {}
      }

      // Pick the best available Filipino/Tagalog locale.
      // Probing first ensures we don't silently fall back to English when
      // a language pack is not installed on the device.
      const candidates = ['fil-PH', 'fil', 'tl-PH', 'tl', 'en-PH'];
      String chosen = 'fil-PH';
      for (final locale in candidates) {
        try {
          final ok = await _tts.isLanguageAvailable(locale);
          if (ok == true) { chosen = locale; break; }
        } catch (_) {}
      }
      await _tts.setLanguage(chosen);
      debugPrint('[TTS] using locale: $chosen');

      // Try to pick a specifically Filipino/Tagalog voice if the platform
      // exposes multiple voices for the chosen locale (e.g. male/female,
      // different engines). This helps avoid English-accented voices.
      try {
        final voices = await _tts.getVoices as List?;
        if (voices != null && voices.isNotEmpty) {
          Map<String, String>? best;
          for (final v in voices) {
            final map = (v as Map?)?.map((k, v) => MapEntry('$k', '${v ?? ''}'));
            if (map == null) continue;
            final lang = (map['locale'] ?? map['language'] ?? '').toLowerCase();
            final name = (map['name'] ?? '').toLowerCase();
            final isFilLocale = lang.startsWith('fil') || lang.startsWith('tl');
            final isPh = lang.contains('ph') || name.contains('philippines');
            if (!isFilLocale) continue;
            if (best == null || isPh) {
              best = map;
              if (isPh) break;
            }
          }
          if (best != null) {
            await _tts.setVoice({
              'name': best['name'] ?? '',
              'locale': best['locale'] ?? chosen,
            });
            debugPrint('[TTS] using voice: ${best['name']} (${best['locale']})');
          }
        }
      } catch (_) {}

      _tts.setErrorHandler((msg) => debugPrint('[TTS] $msg'));
    } catch (e) {
      debugPrint('[TTS] init error: $e');
    }
  }

  /// Speaks [text]. Strips Markdown symbols so the voice reads clean prose.
  Future<void> speak(String text) async {
    final plain = _stripMarkdown(text);
    if (plain.trim().isEmpty) return;
    try {
      await _init();
      await _tts.stop();
      final result = await _tts.speak(plain);
      if (result != 1) debugPrint('[TTS] speak returned $result');
    } catch (e) {
      debugPrint('[TTS] speak error: $e');
    }
  }

  /// Stops current speech.
  Future<void> stop() => _tts.stop();

  /// Keeps the original formatted text, only doing minimal cleanup so the
  /// TTS can read it without weird pauses. Markdown/formatting remains.
  static String _stripMarkdown(String md) {
    return md
        // Neutralise dollar signs so TTS does not say "dollar".
        .replaceAll(r'$', '')
        // Normalise HTML non-breaking spaces and excessive whitespace/newlines.
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }
}
