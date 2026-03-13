import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';

class RiceLeafAnalysisResult {
  const RiceLeafAnalysisResult({this.summary, this.error});
  final String? summary;
  final String? error;
  bool get isSuccess => summary != null && summary!.isNotEmpty;
}

/// Calls OpenAI to analyze a rice leaf photo.
///
/// Strategy:
///   1. Try Responses API (/v1/responses) with gpt-5.
///   2. If gpt-5 is unavailable or returns no content, fall back to
///      Chat Completions API (/v1/chat/completions) with gpt-4o.
class RiceLeafAnalyzerService {
  static const _responsesUrl = 'https://api.openai.com/v1/responses';
  static const _chatUrl = 'https://api.openai.com/v1/chat/completions';

  static const _primaryModel = 'gpt-5';
  static const _fallbackModel = 'gpt-4o'; // vision-guaranteed fallback

  static const _instructions = '''
Ikaw usa ka eksperto sa rice leaf diseases sa Pilipinas.

Ang imong task kay:
- Tan-awa ang litrato sa rice leaf (palay leaf) nga gi-upload.
- Ilista ang posible nga sakit (rice diseases) base sa itsura sa leaf: kolor, mga spots, lesions, yellowing, drying, blight, ug uban pa.
- I-explain sa **simple nga Cebuano/Bisaya**:
  - Unsa ang pinaka-posible nga sakit.
  - Unsa ang mga sintomas nga imong nakita sa larawan.
  - I-rank ang posible nga mga sakit base sa percentage chance.
  - Unsa ang basic nga rekomendasyon sa mag-uuma (unsay buhaton sunod, preventive ug immediate actions).

Kon dili klaro ang sakit sa hulagway, ayaw pag-ingon og 100% sure. Gamita ang pulong nga "posible" o "tingali".
Tubag gamit ang Markdown (bulleted list, **bold** para sa importanteng terms).
''';

  static Future<RiceLeafAnalysisResult> analyze(File file) async {
    if (!hasOpenAiKey) {
      return const RiceLeafAnalysisResult(
        error: 'Walay OpenAI API key. I-set ang OPENAI_API_KEY una.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);

      // ── Step 1: Responses API with gpt-5 ─────────────────────────────────
      debugPrint('[RiceLeaf] Trying Responses API with $_primaryModel...');
      final responsesBody = jsonEncode({
        'model': _primaryModel,
        'instructions': _instructions,
        'input': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text':
                    'Tan-awa kini nga litrato sa rice leaf ug himoa ang detalyadong analysis sa sakit (kung naa) ug rekomendasyon.',
              },
              {
                'type': 'input_image',
                'image_url': 'data:image/jpeg;base64,$b64',
              },
            ],
          },
        ],
        'max_output_tokens': 900,
      });

      final r1 = await http
          .post(
            Uri.parse(_responsesUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiApiKey',
            },
            body: responsesBody,
          )
          .timeout(const Duration(seconds: 90));

      debugPrint('[RiceLeaf] Responses API status: ${r1.statusCode}');
      debugPrint('[RiceLeaf] Responses API body: ${r1.body}');

      if (r1.statusCode == 200) {
        final text = _extractFromResponsesApi(r1.body);
        if (text != null) return RiceLeafAnalysisResult(summary: text);
      }

      // ── Step 2: Chat Completions fallback with gpt-4o ────────────────────
      debugPrint('[RiceLeaf] Falling back to Chat Completions with $_fallbackModel...');
      final chatBody = jsonEncode({
        'model': _fallbackModel,
        'messages': [
          {'role': 'system', 'content': _instructions},
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Tan-awa kini nga litrato sa rice leaf ug himoa ang detalyadong analysis sa sakit (kung naa) ug rekomendasyon.',
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$b64'},
              },
            ],
          },
        ],
        'max_tokens': 900,
      });

      final r2 = await http
          .post(
            Uri.parse(_chatUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiApiKey',
            },
            body: chatBody,
          )
          .timeout(const Duration(seconds: 90));

      debugPrint('[RiceLeaf] Chat Completions status: ${r2.statusCode}');
      debugPrint('[RiceLeaf] Chat Completions body: ${r2.body}');

      if (r2.statusCode == 200) {
        final text = _extractFromChatCompletions(r2.body);
        if (text != null) return RiceLeafAnalysisResult(summary: text);
      }

      // Both failed — surface the error from the last response.
      return RiceLeafAnalysisResult(
        error: _extractApiError(r2.body) ??
            'Dili ma-analyze ang litrato. Status: ${r2.statusCode}',
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[RiceLeaf] Exception: $msg');
      return RiceLeafAnalysisResult(error: 'Network / API error: $msg');
    } catch (e, st) {
      debugPrint('[RiceLeaf] Error: $e\n$st');
      return RiceLeafAnalysisResult(error: 'Error: $e');
    }
  }

  // ── Parsers ───────────────────────────────────────────────────────────────

  /// Extracts text from OpenAI Responses API response.
  /// Handles: output[].content[].text  and  output[].text
  static String? _extractFromResponsesApi(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>?;
      if (data == null) return null;
      final output = data['output'] as List<dynamic>?;
      if (output == null) return null;
      for (final item in output) {
        final m = item as Map<String, dynamic>?;
        if (m == null) continue;
        // output[].content[].text
        final contentList = m['content'] as List<dynamic>?;
        if (contentList != null) {
          for (final c in contentList) {
            final cm = c as Map<String, dynamic>?;
            final t = cm?['text'] as String?;
            if (t != null && t.trim().isNotEmpty) return t.trim();
          }
        }
        // output[].text (some response variants)
        final direct = m['text'] as String?;
        if (direct != null && direct.trim().isNotEmpty) return direct.trim();
      }
    } catch (e) {
      debugPrint('[RiceLeaf] Responses API parse error: $e');
    }
    return null;
  }

  /// Extracts text from Chat Completions response.
  /// Handles string content and list content.
  static String? _extractFromChatCompletions(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>?;
      if (data == null) return null;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;
      final first = choices.first as Map<String, dynamic>?;
      final message = first?['message'] as Map<String, dynamic>?;
      final content = message?['content'];
      if (content is String && content.trim().isNotEmpty) return content.trim();
      if (content is List) {
        for (final part in content) {
          final pm = part as Map<String, dynamic>?;
          final t = pm?['text'] as String?;
          if (t != null && t.trim().isNotEmpty) return t.trim();
        }
      }
    } catch (e) {
      debugPrint('[RiceLeaf] Chat Completions parse error: $e');
    }
    return null;
  }

  /// Extracts a human-readable error message from an OpenAI error response.
  static String? _extractApiError(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>?;
      final err = data?['error'] as Map<String, dynamic>?;
      return err?['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
