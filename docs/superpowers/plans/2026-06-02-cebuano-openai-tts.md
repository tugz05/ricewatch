# Cebuano OpenAI TTS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `flutter_tts` with OpenAI's `/v1/audio/speech` API (nova voice) so the AI Assistant reads Cebuano responses with a natural-sounding voice.

**Architecture:** `TextToSpeechService` becomes a `ChangeNotifier` singleton that calls the OpenAI TTS API, receives MP3 bytes, and plays them via `audioplayers`. Speaker buttons in both message bubble widgets use `ListenableBuilder` to show loading / stop / volume states reactively.

**Tech Stack:** Dart/Flutter, `audioplayers ^6.0.0`, `http` (already installed), OpenAI `/v1/audio/speech` API.

---

## File Map

| File | Change |
|---|---|
| `pubspec.yaml` | Remove `flutter_tts`, add `audioplayers ^6.0.0` |
| `lib/services/text_to_speech_service.dart` | Full rewrite |
| `lib/views/ai_assistant/ai_assistant_view.dart` | Add `messageKey` to `_MessageBubble`; wrap speaker buttons in `ListenableBuilder` |
| `test/services/text_to_speech_service_test.dart` | New — unit tests for `cleanForSpeech` |

---

## Task 1: Update pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Remove flutter_tts and add audioplayers**

Open `pubspec.yaml`. In the `dependencies:` block, remove the `flutter_tts` line and add `audioplayers`:

```yaml
# REMOVE this line:
  flutter_tts: ^4.2.5

# ADD this line in its place (keep alphabetical order near http):
  audioplayers: ^6.0.0
```

After the edit the relevant section of `pubspec.yaml` should look like:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  provider: ^6.1.5+1
  geolocator: ^14.0.2
  geocoding: ^4.0.0
  http: ^1.6.0
  audioplayers: ^6.0.0
  sqflite: ^2.4.2
  path_provider: ^2.1.5
  path: ^1.9.1
  flutter_markdown: ^0.7.7+1
  connectivity_plus: ^6.1.1
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  webview_flutter: ^4.13.1
  webview_flutter_web: ^0.2.3+4
  image_picker: ^1.1.2
  shared_preferences: ^2.5.4
```

- [ ] **Step 2: Fetch dependencies**

```bash
flutter pub get
```

Expected output ends with something like:
```
Resolving dependencies...
+ audioplayers 6.x.x
- flutter_tts 4.2.5
...
Changed N dependencies!
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: swap flutter_tts for audioplayers (OpenAI TTS prep)"
```

---

## Task 2: Write tests for TextToSpeechService

**Files:**
- Create: `test/services/text_to_speech_service_test.dart`

The `cleanForSpeech` static method (to be added in Task 3) is the only pure-logic unit in the service. Write these tests first so they fail, then the Task 3 implementation makes them pass.

- [ ] **Step 1: Create the test file**

Create `test/services/text_to_speech_service_test.dart` with this content:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ricewatch/services/text_to_speech_service.dart';

void main() {
  group('TextToSpeechService.cleanForSpeech', () {
    test('strips bold double-asterisk markers', () {
      expect(
        TextToSpeechService.cleanForSpeech('**humay**'),
        'humay',
      );
    });

    test('strips bold double-underscore markers', () {
      expect(
        TextToSpeechService.cleanForSpeech('__palay__'),
        'palay',
      );
    });

    test('strips italic single-asterisk markers', () {
      expect(
        TextToSpeechService.cleanForSpeech('*irigasyon*'),
        'irigasyon',
      );
    });

    test('strips ATX headers', () {
      expect(
        TextToSpeechService.cleanForSpeech('## Irigasyon'),
        'Irigasyon',
      );
    });

    test('strips deep headers', () {
      expect(
        TextToSpeechService.cleanForSpeech('### Pest Control'),
        'Pest Control',
      );
    });

    test('strips bullet list markers', () {
      expect(
        TextToSpeechService.cleanForSpeech('- Humay\n- Palay'),
        'Humay\nPalay',
      );
    });

    test('strips numbered list markers', () {
      expect(
        TextToSpeechService.cleanForSpeech('1. Una\n2. Duha'),
        'Una\nDuha',
      );
    });

    test('strips inline code backticks and keeps text', () {
      expect(
        TextToSpeechService.cleanForSpeech('`variety`'),
        'variety',
      );
    });

    test('strips link markup and keeps display text', () {
      expect(
        TextToSpeechService.cleanForSpeech('[DA website](https://da.gov.ph)'),
        'DA website',
      );
    });

    test('removes dollar signs', () {
      expect(
        TextToSpeechService.cleanForSpeech(r'$100 ang presyo'),
        '100 ang presyo',
      );
    });

    test('collapses multiple blank lines to one newline', () {
      expect(
        TextToSpeechService.cleanForSpeech('Una\n\n\nDuha'),
        'Una\nDuha',
      );
    });

    test('returns plain text unchanged', () {
      const plain = 'Pangutana bahin sa humay.';
      expect(TextToSpeechService.cleanForSpeech(plain), plain);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
flutter test test/services/text_to_speech_service_test.dart
```

Expected: compilation error — `cleanForSpeech` does not exist yet. This confirms the tests are wired to the right symbol.

---

## Task 3: Rewrite TextToSpeechService

**Files:**
- Modify: `lib/services/text_to_speech_service.dart`

- [ ] **Step 1: Replace the file with the new implementation**

Overwrite `lib/services/text_to_speech_service.dart` entirely:

```dart
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
    _state = TtsPlayState.loading;
    _currentKey = key;
    notifyListeners();

    await _player.stop();

    if (!hasOpenAiKey) {
      if (gen == _generation) _reset();
      return;
    }

    final plain = _stripMarkdown(text);
    if (plain.trim().isEmpty) {
      if (gen == _generation) _reset();
      return;
    }

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
              'input': plain,
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
    ++_generation;
    await _player.stop();
    _reset();
  }

  void _reset() {
    _state = TtsPlayState.idle;
    _currentKey = null;
    notifyListeners();
  }

  static String _stripMarkdown(String md) {
    return md
        // Fenced code blocks (must come before inline code)
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        // Inline code
        .replaceAll(RegExp(r'`([^`\n]+)`'), r'$1')
        // Bold **text** and __text__
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        // Italic *text* and _text_
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')
        // ATX headers (# through ######)
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        // Links [text](url) → text
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
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
```

- [ ] **Step 2: Run the tests — expect PASS**

```bash
flutter test test/services/text_to_speech_service_test.dart
```

Expected:
```
All tests passed!
```

If any test fails, fix `_stripMarkdown` before moving on. Do not proceed with a failing test.

- [ ] **Step 3: Verify no analysis errors in the service**

```bash
flutter analyze lib/services/text_to_speech_service.dart
```

Expected: `No issues found!` (or only infos, no warnings/errors).

- [ ] **Step 4: Commit**

```bash
git add lib/services/text_to_speech_service.dart test/services/text_to_speech_service_test.dart
git commit -m "feat: replace flutter_tts with OpenAI TTS service (nova voice)"
```

---

## Task 4: Update speaker buttons in ai_assistant_view.dart

**Files:**
- Modify: `lib/views/ai_assistant/ai_assistant_view.dart`

There are three changes in this file:
1. Add `messageKey` parameter to `_MessageBubble` and its three call sites in `_buildBody`.
2. Replace the static `IconButton` in `_MessageBubble` with a reactive `ListenableBuilder`.
3. Replace the static `IconButton` in `_TypewriterMessageBubble` with a reactive `ListenableBuilder`.

- [ ] **Step 1: Add messageKey to _MessageBubble constructor**

Find the `_MessageBubble` class definition (line ~417):

```dart
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.c});

  final ChatMessageModel message;
  final AppColorSet c;
```

Replace with:

```dart
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.c,
    required this.messageKey,
  });

  final ChatMessageModel message;
  final AppColorSet c;
  final String messageKey;
```

- [ ] **Step 2: Update the three _MessageBubble call sites in _buildBody**

In `_buildBody`, there are three lines that return `_MessageBubble(message: msg, c: c)`. Replace all three with the version that includes `messageKey`:

```dart
// First occurrence — DB-loaded last assistant message (not fresh):
return _MessageBubble(message: msg, c: c, messageKey: _messageTypewriterKey(msg));

// Second occurrence — typewriter already completed:
return _MessageBubble(message: msg, c: c, messageKey: _messageTypewriterKey(msg));

// Third occurrence — all non-last-assistant messages:
return _MessageBubble(message: msg, c: c, messageKey: _messageTypewriterKey(msg));
```

All three occurrences are inside the `itemBuilder` lambda. Search for `_MessageBubble(message: msg, c: c)` and add `messageKey: _messageTypewriterKey(msg)` to each.

- [ ] **Step 3: Replace the speaker IconButton in _MessageBubble**

Inside `_MessageBubble.build`, find the `IconButton` for the volume icon (inside the `Column` of the assistant bubble, at the `Align(alignment: Alignment.centerRight, ...)` block):

```dart
Align(
  alignment: Alignment.centerRight,
  child: IconButton(
    icon: Icon(
      AppIcons.volume,
      size: 20,
      color: c.accent.withValues(alpha: 0.9),
    ),
    onPressed: () => TextToSpeechService().speak(message.content),
    tooltip: 'Paminaw (Text to speech)',
    style: IconButton.styleFrom(
      padding: const EdgeInsets.all(4),
      minimumSize: const Size(32, 32),
    ),
  ),
),
```

Replace with:

```dart
Align(
  alignment: Alignment.centerRight,
  child: ListenableBuilder(
    listenable: TextToSpeechService(),
    builder: (context, _) {
      final svc = TextToSpeechService();
      final isThis = svc.currentKey == messageKey;
      if (isThis && svc.state == TtsPlayState.loading) {
        return const SizedBox(
          width: 32,
          height: 32,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      final isPlaying = isThis && svc.state == TtsPlayState.playing;
      return IconButton(
        icon: Icon(
          isPlaying ? Icons.stop_rounded : AppIcons.volume,
          size: 20,
          color: c.accent.withValues(alpha: 0.9),
        ),
        onPressed: isPlaying
            ? () => svc.stop()
            : () => svc.speak(message.content, key: messageKey),
        tooltip: isPlaying ? 'Ihunong' : 'Paminaw (Text to speech)',
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(4),
          minimumSize: const Size(32, 32),
        ),
      );
    },
  ),
),
```

- [ ] **Step 4: Replace the speaker IconButton in _TypewriterMessageBubble**

Inside `_TypewriterMessageBubble`, find the `IconButton` for the volume icon (inside the `if (widget.fullContent.isNotEmpty) ...[` block):

```dart
Align(
  alignment: Alignment.centerRight,
  child: IconButton(
    icon: Icon(
      AppIcons.volume,
      size: 20,
      color: c.accent.withValues(alpha: 0.9),
    ),
    onPressed: () => TextToSpeechService().speak(widget.fullContent),
    tooltip: 'Paminaw (Text to speech)',
    style: IconButton.styleFrom(
      padding: const EdgeInsets.all(4),
      minimumSize: const Size(32, 32),
    ),
  ),
),
```

Replace with:

```dart
Align(
  alignment: Alignment.centerRight,
  child: ListenableBuilder(
    listenable: TextToSpeechService(),
    builder: (context, _) {
      final svc = TextToSpeechService();
      final isThis = svc.currentKey == widget.messageKey;
      if (isThis && svc.state == TtsPlayState.loading) {
        return const SizedBox(
          width: 32,
          height: 32,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      final isPlaying = isThis && svc.state == TtsPlayState.playing;
      return IconButton(
        icon: Icon(
          isPlaying ? Icons.stop_rounded : AppIcons.volume,
          size: 20,
          color: c.accent.withValues(alpha: 0.9),
        ),
        onPressed: isPlaying
            ? () => svc.stop()
            : () => svc.speak(widget.fullContent, key: widget.messageKey),
        tooltip: isPlaying ? 'Ihunong' : 'Paminaw (Text to speech)',
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(4),
          minimumSize: const Size(32, 32),
        ),
      );
    },
  ),
),
```

- [ ] **Step 5: Add TtsPlayState import at the top of the view file**

The view already imports `text_to_speech_service.dart`. Make sure the import is present (it should already be there):

```dart
import '../../services/text_to_speech_service.dart';
```

No change needed — `TtsPlayState` is defined in the same file as `TextToSpeechService` and is exported with it.

- [ ] **Step 6: Verify no analysis errors in the view**

```bash
flutter analyze lib/views/ai_assistant/ai_assistant_view.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/views/ai_assistant/ai_assistant_view.dart
git commit -m "feat: reactive TTS speaker button (loading/playing/idle states)"
```

---

## Task 5: Smoke test

**Files:** none (manual verification)

- [ ] **Step 1: Run the app on a device or emulator**

```bash
flutter run
```

- [ ] **Step 2: Open AI Assistant and send a message**

Navigate to the AI Assistant tab, send any rice-farming question in Cebuano (e.g., `"Unsaon pagtanom og humay?"`). Wait for the response.

- [ ] **Step 3: Tap the speaker icon on the assistant response**

Expected sequence:
1. Speaker icon changes to a small `CircularProgressIndicator` (loading — fetching audio from OpenAI).
2. After 1-3 seconds, `CircularProgressIndicator` changes to a `stop_rounded` icon and audio plays in the nova voice.
3. When audio finishes naturally, icon returns to the volume speaker.

- [ ] **Step 4: Tap the stop icon mid-playback**

Expected: audio stops immediately, icon returns to speaker.

- [ ] **Step 5: Tap two different message bubbles in quick succession**

Expected: the first request is cancelled silently, the second one starts.

- [ ] **Step 6: Final commit if any tweaks were made**

```bash
git add -p
git commit -m "fix: TTS smoke test adjustments"
```

If no tweaks were needed, skip this step.
