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
