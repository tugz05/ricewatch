# Design: Cebuano OpenAI TTS with Nova Voice

**Date:** 2026-06-02  
**Status:** Approved  
**Scope:** Replace `flutter_tts` with OpenAI `/v1/audio/speech` (nova voice) in the AI Chat screen.

---

## Goal

Give the RiceWatch AI Assistant a fluent, natural-sounding Cebuano voice by using OpenAI's TTS API with the `nova` voice. The current `flutter_tts` setup has no Cebuano locale support — no mobile TTS engine does — so the on-device voice will always read Cebuano words with a Filipino/Tagalog accent at best. OpenAI TTS reads the text phonetically with a high-quality AI voice.

---

## Architecture & Data Flow

**Files changed:**
- `pubspec.yaml` — add `audioplayers ^6.x`, remove `flutter_tts`
- `lib/services/text_to_speech_service.dart` — full rewrite
- `lib/views/ai_assistant/ai_assistant_view.dart` — reactive speaker button

**Flow:**
1. User taps speaker icon on a message bubble.
2. `TextToSpeechService.speak(text, key: messageKey)` is called.
3. Service sets `state = loading`, calls `notifyListeners()`.
4. HTTP `POST https://api.openai.com/v1/audio/speech` with:
   - `model: "tts-1"`
   - `voice: "nova"`
   - `speed: 0.9`
   - `input`: markdown-stripped text
5. MP3 bytes received → played in memory via `audioplayers` `BytesSource`.
6. State transitions: `loading → playing → idle`.
7. Listeners (speaker buttons) rebuild to reflect state.

---

## Service Design

```dart
enum TtsPlayState { idle, loading, playing }

class TextToSpeechService extends ChangeNotifier {
  static final TextToSpeechService _instance = TextToSpeechService._();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._();

  TtsPlayState get state;   // current playback state
  String? get currentKey;   // key of the message being spoken

  Future<void> speak(String text, {String? key}) async;
  Future<void> stop() async;
}
```

**Generation counter for cancellation:** Each `speak()` call increments an internal `_generation` int. Before each async step (HTTP response, play call), the method checks if `_generation` still matches. If not (user tapped another message), it abandons silently.

---

## Speaker Button Behavior

Each assistant message bubble passes its `messageKey` to a `ListenableBuilder` wrapping `TextToSpeechService()`:

| Condition | Icon shown | Tap action |
|---|---|---|
| `currentKey != messageKey` | Volume icon | Start speaking this message |
| `currentKey == messageKey && state == loading` | `CircularProgressIndicator` (small) | — (no-op) |
| `currentKey == messageKey && state == playing` | Stop icon | `stop()` |

Tapping a new bubble while another is loading/playing: the generation counter mismatch cancels the previous request and starts the new one.

---

## Markdown Stripping

The existing minimal `_stripMarkdown` is replaced with a more thorough pass so the nova voice doesn't read formatting symbols aloud:

| Pattern | Replacement |
|---|---|
| `**text**` or `__text__` | `text` |
| `*text*` or `_text_` | `text` |
| `# Heading` (any level) | `Heading` |
| `` `code` `` or ` ```block``` ` | `code` / `block` |
| `- item` or `* item` (bullets) | `item` |
| `1. item` (numbered lists) | `item` |
| `[link](url)` | `link` |
| `$`, `&nbsp;`, excessive whitespace | cleaned |

---

## Error Handling

- **API error / timeout:** Service resets to `idle`, logs via `debugPrint`. No UI toast — user can retry by tapping the icon again.
- **Long messages:** OpenAI TTS supports up to 4,096 characters. AI responses in this app are well within that limit.
- **App navigation:** `dispose()` in the view calls `stop()`, same as current behavior.
- **No API key:** `speak()` returns immediately (same guard as the chat service).

---

## Dependencies

| Package | Change | Reason |
|---|---|---|
| `audioplayers ^6.x` | Add | Play MP3 bytes in memory |
| `flutter_tts ^4.2.5` | Remove | No longer needed |

---

## Out of Scope

- Auto-play on new messages (user chose manual trigger only).
- Audio caching / offline TTS.
- Voice selection UI in settings.
- ElevenLabs or other TTS providers.
